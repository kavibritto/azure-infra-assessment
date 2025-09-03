output "private_dns_zone_ids" {
  description = "Map of Private DNS zone name -> ID"
  value       = { for k, z in azurerm_private_dns_zone.this : z.name => z.id }
}

output "private_dns_zone_names" {
  description = "Set of Private DNS zone names created"
  value       = toset([for z in azurerm_private_dns_zone.this : z.name])
}
