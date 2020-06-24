variable "key_vault_id" {
  type = string
}

variable "quantity" {
  description = "Number of policies that needs to be created.  Default is 1."
  default = 1
}

variable "service_principal_name" {
  description = "(Optional) You must supply an ObjectID or the name of a Service Prinical, User, or Group"
  type        = list(string)
  default     = []
}

variable "user_principal_name" {
  description = "(Optional) You must supply an ObjectID or the name of a Service Prinical, User, or Group"
  type        = list(string)
  default     = []
}

variable "group_name" {
  description = "(Optional) You must supply an ObjectID or the name of a Service Prinical, User, or Group"
  type        = list(string)
  default     = []
}

variable "object_id" {
  description = "(Optional) You must supply an ObjectID or the name of a Service Prinical, User, or Group"
  type        = list(string)
  default     = []
}

variable "key_permissions" {
  description = "(Optional) List of key permissions, must be one or more from the following: backup, create, decrypt, delete, encrypt, get, import, list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey."
  type        = list(string)
  default     = []
}

variable "secret_permissions" {
  description = "(Optional) List of secret permissions, must be one or more from the following: backup, delete, get, list, purge, recover, restore and set."
  type        = list(string)
  default     = ["get"]
}

variable "certificate_permissions" {
  description = "(Optional) List of certificate permissions, must be one or more from the following: backup, create, delete, deleteissuers, get, getissuers, import, list, listissuers, managecontacts, manageissuers, purge, recover, restore, setissuers and update."
  type        = list(string)
  default     = []
}

