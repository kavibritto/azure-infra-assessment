# HUB Vnet
module "hub" {
  source              = "./modules/vnet"
  resource_group_name = "rg-sandbox-hub"
  location            = var.location
  prefix              = "sandbox_hub"
  vnet_cidr           = "10.0.0.0/16"
  subnets = {
    snet-pe       = "10.0.0.0/24"
    snet-bastion  = "10.0.1.0/24"
    snet-firewall = "10.0.2.0/24"
  }
  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }
}

# App Spoke Vnet
module "app" {
  source              = "./modules/vnet"
  resource_group_name = "rg-sandbox-app"
  location            = var.location
  prefix              = "sandbox_app"
  vnet_cidr           = "10.1.0.0/16"
  enable_nat          = true
  subnets = {
    snet-private = "10.1.0.0/24"
  }
  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }
}

# Data Spoke Vnet
module "data" {
  source              = "./modules/vnet"
  resource_group_name = "rg-sandbox-data"
  location            = "centralindia"
  prefix              = "sandbox_data"
  vnet_cidr           = "10.2.0.0/16"
  subnets = {
    snet-private = "10.2.0.0/24"
  }
  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }
}

# -----------------------
# 
#   Private DNS Zone
#
# -----------------------

module "private_zones" {
  source              = "./modules/hostedzone"
  resource_group_name = "rg-sandbox-hub"
  private_dns_zones = [
    "privatelink.vaultcore.azure.net",
    "privatelink.blob.core.windows.net",
    "privatelink.dfs.core.windows.net",
    "privatelink.database.windows.net",
    "privatelink.azuredatabricks.net"
  ]
  vnet_link_ids = [
    module.hub.vnet_id,
    module.app.vnet_id,
    module.data.vnet_id
  ]

}

# -----------------------
# 
#   Key Vault
#
# -----------------------
module "kv" {
  source              = "./modules/keyvault"
  name                = "kv-sandbox-assesment"
  location            = var.location
  resource_group_name = "rg-sandbox-hub"
  sku_name            = "standard"
  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }
}

# -----------------------
# 
#   Private Endpoints
#
# -----------------------

module "private_endpoints" {
  source              = "./modules/private-endpoints"
  location            = var.location
  resource_group_name = "rg-sandbox-hub"
  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }

  private_endpoints = {
    keyvault = {
      name                 = "pe-keyvault"
      subnet_id            = module.hub.subnet_ids["snet-pe"]
      resource_id          = module.kv.id
      subresource_names    = ["vault"]
      private_dns_zone_ids = [module.private_zones.private_dns_zone_ids["privatelink.vaultcore.azure.net"]]
    }
    # sql = {
    #   name                 = "pe-sql"
    #   subnet_id            = module.hub.subnet_ids["snet-pe"]
    #   resource_id          = data.azurerm_mssql_server.sql.id
    #   subresource_names    = ["sqlServer"]
    #   private_dns_zone_ids = [data.azurerm_private_dns_zone.sql.id]
    # }
    # databricks = {
    #   name                 = "pe-dbx"
    #   subnet_id            = module.hub.subnet_ids["snet-pe"]
    #   resource_id          = data.azurerm_databricks_workspace.dbx.id
    #   subresource_names    = ["databricks_ui_api"]
    #   private_dns_zone_ids = [data.azurerm_private_dns_zone.dbx.id]
    # }
  }
}

# AKS

module "aks" {
  source              = "./modules/aks"
  name                = "aks-sandbox"
  location            = var.location
  resource_group_name = "rg-sandbox-app"
  subnet_id           = module.app.subnet_ids["snet-private"] # your App-Spoke AKS subnet

  # Networking (Azure CNI)
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.2.0.0/26"
  dns_service_ip = "10.2.0.10"

  # Public API (tight allowlist) or toggle to private later
  enable_private_cluster = false
  authorized_ip_ranges   = ["0.0.0.0/0"] # open for now

  node_pool = {
    name            = "sysnp"
    vm_size         = "standard_b2s"
    node_count      = 1
    max_pods        = 50
    os_disk_size_gb = 30
  }

  tags = {
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
  }
}

module "databricks" {
  source              = "./modules/databricks"
  location = var.location
  tags = { 
    environment = "sandbox"
    project     = "azure-infra-assessment"
    terraform   = "true"
   }
vnet_resource_group_name     = "rg-sandbox-data"
vnet_name                    = module.data.vnet_name
existing_private_subnet_name = "snet-private"   # your current one

create_public_subnet = true
public_subnet_name   = "snet-dbx-public"
public_subnet_cidr   = "10.2.2.0/24"
# route tables (optional)
# public_subnet_route_table_id  = ""
# private_subnet_route_table_id = "/subscriptions/xxxx/resourceGroups/rg-data-network/providers/Microsoft.Network/routeTables/rt-default"

workspace_rg_name            = "rg-sandbox-dbx"
workspace_name               = "dbx-sandbox-ws"
workspace_sku                = "premium"
workspace_managed_rg_name    = "rg-sandbox-dbx-managed"
public_network_access_enabled     = true
infrastructure_encryption_enabled = false

enable_private_link   = true
private_dns_rg_name   = "rg-sandbox-hub"
privatelink_subnet_id = module.data.subnet_ids["snet-private"]
  
}

# -----------------------
# 
#   Monitoring
#
# -----------------------
module "demo_monitoring" {
  source                    = "./modules/monitoring"
  prefix                    = "sandbox"
  resource_group_name       = "rg-sandbox-app"
  location                  = var.location
  aks_cluster_id            = module.aks.id
  log_analytics_workspace_id = "test"
  alert_email               = "kavikg7@outlook.com"
}
