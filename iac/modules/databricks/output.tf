output "workspace_id"   { value = azurerm_databricks_workspace.this.id }
output "workspace_url"  { value = data.azurerm_databricks_workspace.current.workspace_url }
output "vnet_id"        { value = data.azurerm_virtual_network.vnet.id }
output "private_subnet_id" { value = azurerm_subnet.private_delegate.id }
output "public_subnet_id"  { value = var.create_public_subnet ? azurerm_subnet.public[0].id : null }

output "pe_ui_ip"      { value = try(azurerm_private_endpoint.pe_ui[0].private_service_connection[0].private_ip_address, null) }
output "pe_backend_ip" { value = try(azurerm_private_endpoint.pe_backend[0].private_service_connection[0].private_ip_address, null) }
output "pe_browser_ip" { value = try(azurerm_private_endpoint.pe_browser[0].private_service_connection[0].private_ip_address, null) }
