# Existing variables for RG/VNet already defined earlier…

variable "private_dns_zones" {
  description = "List of Private DNS zone FQDNs to create in the Hub RG."
  type        = list(string)
  default     = []
}

variable "vnet_link_ids" {
  description = "List of VNet IDs (Hub and Spokes) to link to each Private DNS zone."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {

  }
}
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the private DNS zones."
}