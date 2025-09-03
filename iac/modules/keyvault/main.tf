resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  soft_delete_retention_days    = 7
  purge_protection_enabled      = true
  public_network_access_enabled = false # important when using private endpoints

  tags = var.tags
}

data "azurerm_client_config" "current" {}
