variable "resource_group_name" {
  description = "(Required) The name of the resource group where the database resource will be placed."
}

variable "location" {
  description = "(Required) The Azure location where the database resource will be placed."
}

variable "name" {
  description = "(Required) The name of the database."
}

variable "capacity" {
  description = "(Required)"
  type = number
}

variable "family" {
  description = "(Optional) CPU Generation Family.  Currently Gen5 is the only option"
  default = "Gen5"
}

variable "tier" {
  description = <<EOD
(Required) The Sku Tier defines the Memory per vCore ratio, the storage type, and the maximum vCores
The options are:
B  = Base - 2GB per vcore, 1|2 vCores, Standard Storage (5GB - 1TB)
GP = GeneralPurpose - 5GB per vcore, 2|4|8|16|32|64 vCores, Premium Storage (5GB - 4TB)
MO = MemoryOptimized - 10GB per vcore, 2|4|8|16|32 vCores, Premium Storage (5GB - 4TB)
https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers
EOD
}

variable "storage_mb" {
  description = "Max database size in MB. Min for all skus is 5120(5GB) and max is 104876(1TB) for Basic and 4194304(4TB) for the others. Default is 5120."
  default = 5120
  type = number
}

variable "admin_name" {
  description = "(Required) Name for the default administration account."
}

variable "admin_password" {
  description = "(Required) Password for the default administration account."
}

variable "mysql_version" {
  description = "MySQL version, valid values are 5.6 and 5.7.  Default is 5.7."
  default = "5.7"
}

variable "tags" {
  type = map(string)
}