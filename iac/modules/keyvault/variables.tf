variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "sku_name" {
  type    = string
  default = "standard"
}
variable "tags" {
  type    = map(string)
  default = {}
}
