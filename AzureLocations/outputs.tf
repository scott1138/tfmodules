
output "pascal_long" {
    value = lookup(local.location_map["pascal_long"],var.location)
}

output "lc_short" {
    value = lookup(local.location_map["lc_short"],var.location)
}

output "uc_short" {
    value = lookup(local.location_map["uc_short"],var.location)
}