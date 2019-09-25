variable "scope" {
    description = "(Required) The target resource id."
}

variable "role_name" {
    description = "(Required) The RBAC role to be used in the operation. Use 'az role definition list' to view roles."
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
