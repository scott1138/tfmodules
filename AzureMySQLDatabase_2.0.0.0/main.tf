resource "azurerm_mysql_database" "mysqldb" {
  name                = var.name
  resource_group_name = var.resource_group_name
  server_name         = var.mysql_server_name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}