# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureVM"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
  
}

# Image Info
module "image" {
  source      = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureVMImage.zip"
  image = var.image
}

# Virtual Network and Subnet data
data "azurerm_resource_group" "net_rg" {
  name = var.vnet_resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.net_rg.name
}

data "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.net_rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# Diagnostic Storage Account Data
# The local variable is to strip the trailing slash if it exists
data "azurerm_storage_account" "diag_storage" {
  name                = var.diag_storage_account_name
  resource_group_name = var.diag_storage_account_rg
}

locals {
  diagstguriraw  = data.azurerm_storage_account.diag_storage.primary_blob_endpoint
  diagstorageuri = substr(local.diagstguriraw, -1, 1) == "/" ? substr(local.diagstguriraw, 0, length(local.diagstguriraw) - 1) : local.diagstguriraw
}

# Deployment Resource Group Data
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_network_interface" "ni" {
  count               = var.quantity
  name                = "NI-${format("%s%02d", var.vm_prefix, count.index + 1)}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = merge(local.tf_tag, var.tags)

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "static"
    private_ip_address            = var.ipaddresses[count.index]
    #load_balancer_backend_address_pools_ids = ["${var.lb_backend_address_pool_id == "" ? "" : var.lb_backend_address_pool_id}"]
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }
}

resource "azurerm_availability_set" "availabilityset" {
  name                = "HA-${var.vm_prefix}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  managed             = true
  tags                = merge(local.tf_tag, var.tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }
}

# win_vm - if offer is WindowsServer, the count is var.quantity, else it is 0
resource "azurerm_virtual_machine" "win_vm" {
  count                 = element(module.image.info, 3) == "Windows" ? var.quantity : 0
  name                  = "VM-${format("%s%02d", var.vm_prefix, count.index + 1)}"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.ni.*.id, count.index)]
  vm_size               = var.vm_size
  availability_set_id   = azurerm_availability_set.availabilityset.id
  license_type          = "Windows_Server"
  tags                  = merge(local.tf_tag, var.tags)

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = element(module.image.info, 0)
    offer     = element(module.image.info, 1)
    sku       = element(module.image.info, 2)
    version   = "latest"
  }

  storage_os_disk {
    name              = "DISK-${format("%s%02d", var.vm_prefix, count.index + 1)}-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = var.os_disk_size == "" ? "128" : var.os_disk_size
  }

  dynamic "storage_data_disk" {
    for_each = var.data_disk
    content {
      name            = "DISK-${format("%s%02d", var.vm_prefix, count.index)}-DATA${format("%02d",storage_data_disk.value["LUN"])}"
      create_option   = "Empty"
      managed_disk_type = "Premium_LRS"
      lun             = storage_data_disk.value["LUN"] 
      disk_size_gb    = storage_data_disk.value["Size"]
      caching         = storage_data_disk.value["Caching"] == "" ? "ReadOnly" : storage_data_disk.value["Caching"]
    }
  }

  os_profile {
    computer_name  = "VM-${format("%s%02d", var.vm_prefix, count.index + 1)}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
    timezone                  = "Central Standard Time"

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("${path.module}/FirstLogonCommands.xml")
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = local.diagstorageuri
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }
}

# linux_vm - if os offer is Linux, the count is var.quantity, else it is 0
resource "azurerm_virtual_machine" "linux_vm" {
  count                 = element(module.image.info, 3) == "Linux" ? var.quantity : 0
  name                  = "VM-${format("%s%02d", var.vm_prefix, count.index + 1)}"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.ni.*.id, count.index)]
  vm_size               = var.vm_size
  availability_set_id   = azurerm_availability_set.availabilityset.id
  tags                  = merge(local.tf_tag, var.tags)

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = element(module.image.info, 0)
    offer     = element(module.image.info, 1)
    sku       = element(module.image.info, 2)
    version   = "latest"
  }

  storage_os_disk {
    name              = "DISK-${format("%s%02d", var.vm_prefix, count.index + 1)}-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = var.os_disk_size == "" ? "128" : var.os_disk_size
  }

  dynamic "storage_data_disk" {
    for_each = var.data_disk
    content {
      name            = "DISK-${format("%s%02d", var.vm_prefix, count.index)}-DATA${format("%02d",storage_data_disk.value["LUN"])}"
      create_option   = "Empty"
      managed_disk_type = "Premium_LRS"
      lun             = storage_data_disk.value["LUN"] 
      disk_size_gb    = storage_data_disk.value["Size"]
      caching         = storage_data_disk.value["Caching"] == "" ? "ReadOnly" : storage_data_disk.value["Caching"]
    }
  }

  os_profile {
    computer_name  = "VM-${format("%s%02d", var.vm_prefix, count.index + 1)}"
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file(var.ssh_key)
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = local.diagstorageuri
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }
}

locals {
  server_names = compact(
    concat(
      azurerm_virtual_machine.win_vm.*.name,
      azurerm_virtual_machine.linux_vm.*.name,
    ),
  )

  server_ids = compact(
    concat(
      azurerm_virtual_machine.win_vm.*.id,
      azurerm_virtual_machine.linux_vm.*.id,
    ),
  )

  # The VMs identity returns a list of lists, so we use flatten so that we can concat the lists.
  # Compact is then used to remove the empty lists.
  server_principal_ids = compact(
    concat(
      flatten(azurerm_virtual_machine.win_vm[*].identity[*]["principal_id"]),
      flatten(azurerm_virtual_machine.linux_vm[*].identity[*]["principal_id"]),
    ),
  )
} # End locals


