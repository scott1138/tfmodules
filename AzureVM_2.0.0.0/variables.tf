variable "location" {
  description = "(Required) The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "resource_group_name" {
  description = "(Required) The name of the resource group where the VM resources will be placed."
}

variable "quantity" {
  description = "Number of VMs to deploy"
  default     = 1
  type        = number
}

variable "vm_prefix" {
  description = "(Required) Default prefix to use with your VM name. example: PRDAPPWFE"
}

variable "vm_size" {
  description = "(Required) Azure VM size"
}

variable "subnet_name" {
  description = "(Required) Name of the subnet to deploy the VM in."
}

variable "vnet_resource_group_name" {
  description = "(Required) Name of the resource group where the Virtual Network resides."
}

variable "vnet_name" {
  description = "(Required) Name of the Virtual Network where the subnet resides."
}

variable "ipaddresses" {
  description = "(Required) List of IP addresses used for VMs.  Example \"0\" = \"10.0.0.1\""
  type        = map(string)
}

variable "image" {
  description = "Use the key from the standard_os variable to specify the desired os"
  default     = "WS2016"
}

variable "data_disk" {
  description = <<EOD
(Optional) Data Disk details.  Leave blank if not needed.
Valid values for Caching are Blank(defaults to ReadOnly), ReadOnly, ReadWrite, or None.
Check application documentation for the correct caching settings.
data_disk = [
  {
    LUN     = "1"
    Size    = "512"
    Caching = ""
  },
  {
    LUN     = "2"
    Size    = "1024"
    Caching = "None"
  }
]
EOD
  default     = []
  type        = list(map(string))
}

variable "os_disk_size" {
  description = "Size of a OS disk.  Leave blank for default"
  default     = ""
}

variable "admin_username" {
  description = "(Required)  Administrator username"
}

variable "admin_password" {
  description = "(Required)  Administrator password"
  default     = ""
}

variable "diag_storage_account_name" {
  description = "(Required) Storage account used for diag logs, should be on per subscription - stgstd<SubName>diags"
}

variable "diag_storage_account_rg" {
  description = "(Required) Resource group where the diag storage account exists, should be RG-<Subscription>-Infrastructure-[Prod|NonProd]"
}

variable "ssh_key" {
  description = "SSH Key for Windows Systems"
  default     = ""
}

variable "tags" {
  type = map(string)
}

