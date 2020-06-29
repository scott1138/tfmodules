# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureMySQLServer"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags

  tier_table = {
    "B" = "Basic"
    "GP" = "GeneralPurpose"
    "MO" = "MemoryOptimized"
  }

  sku_name = join("_",[var.tier,var.family,var.capacity])

  tier_full = local.tier_table[var.tier]
 
}

resource "azurerm_mysql_server" "mysql" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = local.sku_name
    capacity = var.capacity
    tier     = local.tier_full
    family   = var.family
  }

  storage_profile {
    storage_mb            = var.storage_mb
    backup_retention_days = 30
    geo_redundant_backup  = var.tier == "B" ? "Disabled" : "Enabled"
  }

  administrator_login          = var.admin_name
  administrator_login_password = var.admin_password
  version                      = var.mysql_version
  ssl_enforcement              = "Enabled"

  tags = merge(local.tf_tag, var.tags)

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