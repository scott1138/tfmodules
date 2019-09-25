output "name" {
  value = data.external.userinfo.result.displayName
}

output "object_id" {
  value = data.external.userinfo.result.objectId
}

output "object_type" {
  value = data.external.userinfo.result.objectType
}

output "ado_user" {
  value = data.external.userinfo.result.user
}