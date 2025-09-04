variable "name" {}
variable "location" {}
variable "resource_group_name" {}
variable "dns_prefix" { default = null }
variable "kubernetes_version" { default = null }

variable "subnet_id" {} # App-Spoke AKS subnet
variable "service_cidr" { default = "10.1.0.0/24" }
variable "dns_service_ip" { default = "10.1.0.10" }
variable "pod_cidr" { default = null }          # only if kubenet; keep null for Azure CNI
variable "network_plugin" { default = "azure" } # azure = Azure CNI
variable "network_policy" { default = "azure" }

variable "node_pool" {
  type = object({
    name : string
    vm_size : string
    node_count : number
    max_pods : number
    os_disk_size_gb : number
  })
}

variable "enable_private_cluster" {
  type    = bool
  default = false
}
variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "acr_name" {
  type = string
  
}