# Creates any number of Private DNS zones and links them to one or more VNets.

# Example zones you might pass:
# - privatelink.vaultcore.azure.net         (Key Vault)
# - privatelink.blob.core.windows.net       (Storage: Blob)
# - privatelink.dfs.core.windows.net        (Storage: ADLS Gen2 / DFS)
# - privatelink.database.windows.net        (Azure SQL)
# - privatelink.azuredatabricks.net         (Databricks - front end, optional)
# - <add any other PaaS private link zones you use>

resource "azurerm_private_dns_zone" "this" {
  for_each            = toset(var.private_dns_zones)
  name                = each.value
  resource_group_name = var.resource_group_name
}

# Link each zone to every VNet id provided (Hub + Spokes)
# We create a cartesian product of (vnet_link_ids x zones).
locals {
  link_matrix = {
    for pair in setproduct(var.vnet_link_ids, keys(azurerm_private_dns_zone.this)) :
    "${pair[0]}|${pair[1]}" => {
      vnet_id  = pair[0]
      zone_key = pair[1]
    }
  }
}

# resource "azurerm_private_dns_zone_virtual_network_link" "links" {
#   for_each              = local.link_matrix
#   name                  = "${split("|", each.key)[1]}-${element(split("/", each.value.vnet_id), length(split("/", each.value.vnet_id)) - 1)}"
#   resource_group_name   = var.resource_group_name
#   private_dns_zone_name = azurerm_private_dns_zone.this[each.value.zone_key].name
#   virtual_network_id    = each.value.vnet_id
#   registration_enabled  = false
# }

resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each              = toset(var.private_dns_zones)
  name                  = each.value
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.value].name
  virtual_network_id    = var.vnet_link_ids[0]
  registration_enabled  = false
}

