resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = coalesce(var.dns_prefix, "${var.name}-dns")
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = var.node_pool.name
    vm_size                      = var.node_pool.vm_size
    node_count                   = var.node_pool.node_count
    max_pods                     = var.node_pool.max_pods
    os_disk_size_gb              = var.node_pool.os_disk_size_gb
    type                         = "VirtualMachineScaleSets"
    # vnet_subnet_id               = var.subnet_id
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m" # demo-friendly; set higher for prod
  }

  network_profile {
    network_plugin = var.network_plugin
    # network_policy = var.network_policy
    # service_cidr   = var.service_cidr
    # dns_service_ip = var.dns_service_ip

    # Force egress via NAT GW (User Defined Routing on subnet)
    # outbound_type = "userDefinedRouting"
    # For Demo puposes, force egress via NAT GW
    outbound_type  = "managedNATGateway"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.enable_private_cluster ? null : var.authorized_ip_ranges
    # enable_private_cluster = var.enable_private_cluster
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version
    ]
  }

  tags = var.tags
}

# Grant AKS kubelet identity RBAC to read secrets from your Key Vault (scope passed in usage)
resource "azurerm_role_assignment" "kv_secrets_user" {
  count                = 1                                                     # set to 1 in usage when you pass kv_scope_id
  scope                = "/subscriptions/267bb7a7-50eb-4c5b-81ee-4adc1b915849" # placeholder
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

# import {
#   to = azurerm_kubernetes_cluster.this
#   id = "/subscriptions/267bb7a7-50eb-4c5b-81ee-4adc1b915849/resourceGroups/rg-sandbox-app/providers/Microsoft.ContainerService/managedClusters/aks-sandbox"
# }
data "azurerm_container_registry" "acr" {
  name = var.acr_name
  resource_group_name = "rg-containers"
}
resource "azurerm_role_assignment" "acr" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id

  # depends_on = [time_sleep.wait_for_kubelet_identity]

  # Avoid duplicate assignment flaps on re-apply
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scope, role_definition_name, principal_id]
  }
}