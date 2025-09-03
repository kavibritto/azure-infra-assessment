output "id" { value = azurerm_kubernetes_cluster.this.id }
output "name" { value = azurerm_kubernetes_cluster.this.name }
output "kubelet_object_id" { value = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id }
output "oidc_issuer_url" { value = azurerm_kubernetes_cluster.this.oidc_issuer_url }
