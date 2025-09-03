variable "resource_group_name" {
  description = "Name of the resource group for the Hub"
  type        = string
}

variable "location" {
  description = "Azure location/region"
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
}

variable "subnets" {
  description = "Map of subnet names to CIDRs"
  type        = map(string)
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
}

variable "enable_nat" {
  type        = bool
  default     = false
  description = "Enable NAT gateway"
}