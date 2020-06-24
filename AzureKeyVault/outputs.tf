output "id" {
  description = "vault id for the Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "uri" {
  description = "vault uri for the KeyVault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "name" {
  description = "Key Vault Name"
  value       = azurerm_key_vault.kv.name
}

