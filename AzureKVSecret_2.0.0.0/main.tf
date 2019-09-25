# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureUserInfo_2.0.0.0.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureKVSecret_2.0.0.0"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
  
}

resource "azurerm_key_vault_secret" "kv_secret" {
  name         = var.name
  value        = var.value
  key_vault_id = var.key_vault_id
  tags         = merge(local.tf_tag, var.tags)

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

