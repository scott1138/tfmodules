data "azurerm_client_config" "current" {
}

data "azuread_service_principal" "sp" {
  count        = var.service_principal_name != "" ? 1 : 0
  display_name = var.service_principal_name
}

data "azuread_group" "group" {
  count = var.group_name != "" ? 1 : 0
  name  = var.group_name
}

data "azuread_user" "user" {
  count               = var.user_principal_name != "" ? 1 : 0
  user_principal_name = var.user_principal_name
}

# Role Assigment does not tke count, so we append the [0] to make sure we conver the single itme list into a string
locals {
 principal_id = var.object_id != [] ? var.object_id : compact(concat(data.azuread_service_principal.sp[*].object_id,data.azuread_group.group[*].id,data.azuread_user.user[*].id))
}

resource "azurerm_role_assignment" "test" {
  scope                = var.scope
  role_definition_name = var.role_name
  principal_id         = local.principal_id
}