output "id" {
  description = "ID for KeyVault Certificate"
  value       = azurerm_key_vault_certificate.kv_cert.id
}

output "thumbprint" {
  description = "X509 Thumbprint of the certificate"
  value       = azurerm_key_vault_certificate.kv_cert.thumbprint
}