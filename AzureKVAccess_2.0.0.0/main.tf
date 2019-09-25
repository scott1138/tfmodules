data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "sp" {
  count        = length(var.service_principal_name) > 0 ? length(var.service_principal_name) : 0
  display_name = var.service_principal_name[count.index]
}

data "azuread_group" "group" {
  count = length(var.group_name) > 0 ? length(var.group_name) : 0
  name  = var.group_name[count.index]
}

data "azuread_user" "user" {
  count               = length(var.user_principal_name) > 0 ? length(var.user_principal_name) : 0
  user_principal_name = var.user_principal_name[count.index]
}

# Combine all possible lists including the var object_id with concat and then remove them empty items with compact
# This allows us to have a single resource statement instead of checking for the length of data object to see what
# Was returned
locals {
  principal_id = length(var.object_id) > 0 ? var.object_id : compact(concat(data.azuread_service_principal.sp[*].object_id,data.azuread_group.group[*].id,data.azuread_user.user[*].id))
}

resource "azurerm_key_vault_access_policy" "kvaccess" {
  count = var.quantity

  key_vault_id          = var.key_vault_id
  
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = local.principal_id[count.index]

  key_permissions         = var.key_permissions
  secret_permissions      = var.secret_permissions
  certificate_permissions = var.certificate_permissions
}
