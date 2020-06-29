data "azurerm_client_config" "current" {
}

data "azurerm_subscription" "current" {
}

data "azurerm_resource_group" "rg_name" {
  name = var.resource_group_name
}

# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureKeyVault"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
  
}

resource "azurerm_key_vault" "kv" {
  name                        = var.name
  location                    = data.azurerm_resource_group.rg_name.location
  resource_group_name         = data.azurerm_resource_group.rg_name.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  tags                        = merge(local.tf_tag, var.tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }
}

