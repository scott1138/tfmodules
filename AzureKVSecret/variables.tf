variable "name" {
  type = string
}

variable "value" {
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

