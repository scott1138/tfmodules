# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureBasicILB"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
  
}

# Azure load balancer module
data "azurerm_subnet" "azlb" {
  name                 = var.subnet_name
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = var.vnet_name
}

resource "azurerm_lb" "azlb" {
  name                = "LB-${var.lb_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = merge(local.tf_tag, var.tags)
  sku                 = "Basic"

  frontend_ip_configuration {
    name                          = "FrontEndIPConfig"
    subnet_id                     = data.azurerm_subnet.azlb.id
    private_ip_address            = var.frontend_private_ip_address
    private_ip_address_allocation = "Static"
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

resource "azurerm_lb_backend_address_pool" "azlb" {
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.azlb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_assoc" {
  count                   = length(var.network_interface_id)
  network_interface_id    = element(var.network_interface_id,count.index)
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.azlb.id
}

resource "azurerm_lb_probe" "azlb" {
  count               = length(var.lb_port)
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.azlb.id
  name                = element(keys(var.lb_port), count.index)
  protocol            = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  port                = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  interval_in_seconds = var.lb_probe_interval
  number_of_probes    = var.lb_probe_unhealthy_threshold
}

resource "azurerm_lb_rule" "azlb" {
  count                          = length(var.lb_port)
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.azlb.id
  name                           = element(keys(var.lb_port), count.index)
  protocol                       = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  frontend_port                  = element(var.lb_port[element(keys(var.lb_port), count.index)], 0)
  backend_port                   = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  frontend_ip_configuration_name = "FrontEndIPConfig"
  enable_floating_ip             = false
  load_distribution              = var.load_distribution
  backend_address_pool_id        = azurerm_lb_backend_address_pool.azlb.id
  idle_timeout_in_minutes        = 5
  probe_id                       = element(azurerm_lb_probe.azlb.*.id, count.index)
  depends_on                     = [azurerm_lb_probe.azlb]
}

