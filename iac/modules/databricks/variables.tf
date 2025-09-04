variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vnet_id" {
  description = "ID of the existing VNet for VNet injection"
  type        = string
}
variable "vnet_name" {
  description = "Name of the existing VNet for VNet injection"
  type = string
}

variable "public_subnet_name" {
  description = "Name of the public subnet for Databricks"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet for Databricks"
  type        = string
}

variable "sku" {
  description = "Databricks SKU"
  type        = string
  default     = "standard"
}

variable "tags" {
  type = map(string)
  default = {
    env = "sandbox"
  }
}
