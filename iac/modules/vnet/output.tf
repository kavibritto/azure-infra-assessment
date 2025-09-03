output "vnet_id" {
  description = "ID of the  Virtual Network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the  Virtual Network"
  value       = azurerm_virtual_network.this.name
}
output "subnet_ids" {
  description = "IDs of the  subnets"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_names" {
  description = "Names of the  subnets"
  value       = { for k, s in azurerm_subnet.this : k => s.name }
}

# route table id
output "route_table_id" {
  description = "ID of the  route table"
  value       = azurerm_route_table.this.id
}

# route table name
output "route_table_name" {
  description = "Name of the  route table"
  value       = azurerm_route_table.this.name
}
