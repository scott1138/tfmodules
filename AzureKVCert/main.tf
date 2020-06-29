# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureKVCert"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
  
}

resource "azurerm_key_vault_certificate" "kv_cert" {
  key_vault_id = var.key_vault_id
  name         = var.name
  
  certificate {
    contents = filebase64(var.cert_path)
    password = var.cert_password
  }
  
  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }

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

