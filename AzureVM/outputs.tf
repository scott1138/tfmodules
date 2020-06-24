output "network_interface_id" {
  value = azurerm_network_interface.ni.*.id
}

output "id" {
  value = local.server_ids
}

output "name" {
  value = local.server_names
}

output "principal_id" {
  value = local.server_principal_ids
}

