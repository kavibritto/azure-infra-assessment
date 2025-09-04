resource "azurerm_databricks_workspace" "this" {
  name                        = "${var.prefix}-dbx"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku                         = var.sku
  managed_resource_group_name = "${var.prefix}-dbx-managed"

  custom_parameters {
    no_public_ip         = true
    virtual_network_id   = var.vnet_id
    public_subnet_name   = var.public_subnet_name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.public.id
    private_subnet_name  = var.private_subnet_name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
    
  }

  tags = var.tags
}

# vnet data
data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}
# public and private subnet
resource "azurerm_subnet" "public" {
  
  name                 = var.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.2.11.0/24"]
    delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private" {
  
  name                 = var.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.2.12.0/24"]
    delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
                "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# network association public_subnet_network_security_group_association_id

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# nsg
resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  
}