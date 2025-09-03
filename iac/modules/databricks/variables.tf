variable "location" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

# Existing VNet info
variable "vnet_resource_group_name" {
  type = string
}
variable "vnet_name" {
  type = string
}
variable "existing_private_subnet_name" { type = string }

# Create the missing (public) subnet here if you only have one today
variable "create_public_subnet" {
  type    = bool
  default = true
}
variable "public_subnet_name" {
  type    = string
  default = "snet-dbx-public"
}
variable "public_subnet_cidr" {
  type    = string
  default = "10.2.1.0/24"
}

# Optional UDRs (ensure 0.0.0.0/0 exists if you use NAT/FW or Databricks provisioning can fail)
variable "public_subnet_route_table_id" {
  type    = string
  default = ""
}
variable "private_subnet_route_table_id" {
  type    = string
  default = ""
}

# Workspace
variable "workspace_rg_name" { type = string }
variable "workspace_name" { type = string }
variable "workspace_sku" {
  type    = string
  default = "premium"
}
variable "workspace_managed_rg_name" { type = string }
variable "public_network_access_enabled" {
  type    = bool
  default = true
}
variable "infrastructure_encryption_enabled" {
  type    = bool
  default = false
}

# Private Link (optional)
variable "enable_private_link" {
  type    = bool
  default = false
}
variable "private_dns_rg_name" {
  type    = string
  default = ""
}
variable "privatelink_subnet_id" {
  type    = string
  default = ""
} # PE subnet (recommended dedicated)
variable "enable_pe_ui" {
  type    = bool
  default = true
}
variable "enable_pe_backend" {
  type    = bool
  default = true
}
variable "enable_pe_browser" {
  type    = bool
  default = true
}
