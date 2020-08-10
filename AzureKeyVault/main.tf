data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

# Variables used internally
locals {
  tf_tags = {
    Source       = "TFModule-AzureKeyVault"
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = var.name
  location                    = var.resource_group_name
  resource_group_name         = var.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  tags                        = merge(local.tf_tags, var.tags)
}
