output "node_resource_group" {
    value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
    description = "Name of the resource group that contains the AKS resources."
}

output "fqdn" {
    value = azurerm_kubernetes_cluster.aks_cluster.fqdn
    description = "FQDN of the Kubernetes API."
}
