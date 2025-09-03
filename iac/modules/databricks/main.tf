terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm    = { source = "hashicorp/azurerm", version = "~> 4.0" }
    databricks = { source = "databricks/databricks", version = "~> 1.54" }
  }
}

# provider "azurerm" {
#   features {}
# }

# ---------------------------------------------------------------------------------------
# Data lookups for existing VNet and (at least) the existing PRIVATE subnet
# ---------------------------------------------------------------------------------------
data "azurerm_resource_group" "vnet_rg" {
  name = var.vnet_resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.vnet_rg.name
}

# 
# Im using new private subnet
# 
# Existing subnet you already have – we’ll treat this as the PRIVATE subnet
# data "azurerm_subnet" "existing_private" {
#   name                 = var.existing_private_subnet_name
#   virtual_network_name = data.azurerm_virtual_network.vnet.name
#   resource_group_name  = data.azurerm_resource_group.vnet_rg.name
# }

# Optional creation of the second (PUBLIC) subnet if you only have one today
resource "azurerm_subnet" "public" {
  count                = var.create_public_subnet ? 1 : 0
  name                 = var.public_subnet_name
  resource_group_name  = data.azurerm_resource_group.vnet_rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.public_subnet_cidr]

  delegation {
    name = "databricks-delegation-public"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

# Ensure the existing private subnet is delegated to Databricks as well
# (Make this managed by TF only if you’re OK with TF owning subnet delegation on that subnet)

# Update: for now im using new private subnet
resource "azurerm_subnet" "private_delegate" {
  # create a managed mirror of the existing subnet to add delegation (safe if you want TF to manage it)
  name                 = "dbx-private-delegate"
  resource_group_name  = data.azurerm_resource_group.vnet_rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.3.0/24"]


  delegation {
    name = "databricks-delegation-private"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }

  lifecycle {
    # If you cannot let TF manage this subnet (eg already managed elsewhere),
    # then comment this whole resource out and ensure delegation exists manually.
    ignore_changes = [service_endpoints] # common drift
  }
}

# Optional route table associations (only if you use UDRs/NAT)
resource "azurerm_subnet_route_table_association" "rt_public" {
  count          = var.public_subnet_route_table_id != "" && var.create_public_subnet ? 1 : 0
  subnet_id      = azurerm_subnet.public[0].id
  route_table_id = var.public_subnet_route_table_id
}

resource "azurerm_subnet_route_table_association" "rt_private" {
  count          = var.private_subnet_route_table_id != "" ? 1 : 0
  subnet_id      = azurerm_subnet.private_delegate.id
  route_table_id = var.private_subnet_route_table_id
}

# ---------------------------------------------------------------------------------------
# Workspace RG
# ---------------------------------------------------------------------------------------
resource "azurerm_resource_group" "ws" {
  name     = var.workspace_rg_name
  location = var.location
  tags     = var.tags
}

# ---------------------------------------------------------------------------------------
# Databricks Workspace (VNet-injected)
# ---------------------------------------------------------------------------------------
resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  location                    = var.location
  resource_group_name         = azurerm_resource_group.ws.name
  sku                         = var.workspace_sku
  managed_resource_group_name = var.workspace_managed_rg_name

  public_network_access_enabled     = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = data.azurerm_virtual_network.vnet.id
    public_subnet_name  = var.create_public_subnet ? azurerm_subnet.public[0].name : var.public_subnet_name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.public[0].id
    private_subnet_name = azurerm_subnet.private_delegate.name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }

  tags = var.tags
}

data "azurerm_databricks_workspace" "current" {
  name                = azurerm_databricks_workspace.this.name
  resource_group_name = azurerm_resource_group.ws.name
}
data "azurerm_private_dns_zone" "dbx_zone" {
  name = "privatelink.azuredatabricks.net"
  resource_group_name = "rg-sandbox-hub"
}
# Public NSG
resource "azurerm_network_security_group" "dbx_public" {
  name                = "${var.workspace_name}-nsg-public"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name
  tags                = var.tags
}

# Private NSG
resource "azurerm_network_security_group" "dbx_private" {
  name                = "${var.workspace_name}-nsg-private"
  location            = var.location
  resource_group_name = var.vnet_resource_group_name
  tags                = var.tags
}
# Associate NSGs to subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = var.create_public_subnet ? 1 : 0
  subnet_id                 = azurerm_subnet.public[0].id
  network_security_group_id = azurerm_network_security_group.dbx_public.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private_delegate.id
  network_security_group_id = azurerm_network_security_group.dbx_private.id
}
# ---------------------------------------------------------------------------------------
# Private Link (optional): create PEs in a PE subnet (often a dedicated subnet in hub/spoke)
# If you want PEs inside the same VNet, point privatelink_subnet_id to a subnet there.
# ---------------------------------------------------------------------------------------
# resource "azurerm_private_dns_zone" "dbx" {
#   count               = var.enable_private_link ? 1 : 0
#   name                = "privatelink.azuredatabricks.net"
#   resource_group_name = var.private_dns_rg_name
#   tags                = var.tags
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "dbx_link" {
#   count                 = var.enable_private_link ? 1 : 0
#   name                  = "${var.vnet_name}-dbx-link"
#   resource_group_name   = var.private_dns_rg_name
#   private_dns_zone_name = azurerm_private_dns_zone.dbx[0].name
#   virtual_network_id    = data.azurerm_virtual_network.vnet.id
#   registration_enabled  = false
# }

locals {
  pe_subnet_id = var.privatelink_subnet_id
}

resource "azurerm_private_endpoint" "pe_ui" {
  count               = var.enable_private_link && var.enable_pe_ui ? 1 : 0
  name                = "${var.workspace_name}-pe-ui"
  location            = var.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = local.pe_subnet_id
  private_service_connection {
    name                           = "${var.workspace_name}-psc-ui"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "pe_backend" {
  count               = var.enable_private_link && var.enable_pe_backend ? 1 : 0
  name                = "${var.workspace_name}-pe-backend"
  location            = var.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = local.pe_subnet_id
  private_service_connection {
    name                           = "${var.workspace_name}-psc-backend"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["databricks_backend_api"]
  }
  tags = var.tags
}

resource "azurerm_private_endpoint" "pe_browser" {
  count               = var.enable_private_link && var.enable_pe_browser ? 1 : 0
  name                = "${var.workspace_name}-pe-browser"
  location            = var.location
  resource_group_name = azurerm_resource_group.ws.name
  subnet_id           = local.pe_subnet_id
  private_service_connection {
    name                           = "${var.workspace_name}-psc-browser"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["browser_authentication"]
  }
  tags = var.tags
}

resource "azurerm_private_dns_a_record" "ui" {
  count               = var.enable_private_link && var.enable_pe_ui ? 1 : 0
  name                = "ui"
  zone_name           = data.azurerm_private_dns_zone.dbx_zone.name
  resource_group_name = var.private_dns_rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe_ui[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "backend" {
  count               = var.enable_private_link && var.enable_pe_backend ? 1 : 0
  name                = "backend"
  zone_name           = data.azurerm_private_dns_zone.dbx_zone.name
  resource_group_name = var.private_dns_rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe_backend[0].private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_a_record" "browser" {
  count               = var.enable_private_link && var.enable_pe_browser ? 1 : 0
  name                = "browser"
  zone_name           = data.azurerm_private_dns_zone.dbx_zone.name
  resource_group_name = var.private_dns_rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe_browser[0].private_service_connection[0].private_ip_address]
}

# Workspace-scoped provider (handy later)
provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.this.id
}
