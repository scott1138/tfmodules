variable "name" {
  type = string
}

variable "cert_path" {
  type = string
}

variable "cert_password" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "dependencies" {
  type    = list(string)
  default = []
}

