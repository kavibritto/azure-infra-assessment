variable "location" {}
variable "resource_group_name" {}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "private_endpoints" {
  type = map(object({
    name                 = string
    subnet_id            = string
    resource_id          = string
    subresource_names    = list(string)
    private_dns_zone_ids = list(string)
  }))
}
