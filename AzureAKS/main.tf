terraform {
  required_version = ">=0.12.23"
  required_providers {
    azurerm = ">= 2.0.0"
  }
}

# User running Terraform
module "userinfo" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

module "location" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureLocations.zip"

  location = lower(var.location)
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

# Variables used internally
locals {

  base_tags = {
    Source       = "TFModule-AzureAKS"
    CreatedDate  = timestamp()
    CreatorName  = module.userinfo.name
    CreatorObjId = module.userinfo.object_id
    CreatorType  = module.userinfo.object_type
  }

  tf_tags = merge(module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags, var.tags)

  sub_name = data.azurerm_subscription.current.display_name

  # Cluster name to be used throughout the module
  cluster_name = "AKS-${local.sub_name}-${module.location.long}-${var.cluster_name}"

  # Names for the AAD Applications
  resources_name = "${local.cluster_name}-Resources"
  server_name = "${local.cluster_name}-Server"
  client_name = "${local.cluster_name}-Client"

}


# Create Key Vault for AKS cluster secrets
module "kv" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKeyVault_2.1.0.0.zip"

  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "KV-AKS-${module.location.short}-${var.cluster_name}"
  tags                = local.tf_tags
}

module "kv_access_infra" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVAccess.zip"

  key_vault_id        = module.kv.id
  object_id           = [data.azurerm_client_config.current.object_id]
  secret_permissions  = ["list","get","set","delete"]
}


# Create AAD Applications, Service Principals, and assign permissions
# The "Resources" app is how the AKS cluster creates resources in Azure
# The "Server" app is used to query AAD for for user data
# The "Client" app is used to impersonate the user
resource "azuread_application" "resources" {
  name                       = local.resources_name
  identifier_uris            = ["https://${local.resources_name}"]
}

resource "azuread_service_principal" "resources" {
  application_id               = azuread_application.resources.application_id
  app_role_assignment_required = false
}

resource "random_password" "resources" {
  length  = 20
  special = true
}

resource "azuread_service_principal_password" "resources" {
  service_principal_id = azuread_service_principal.resources.id
  value                = random_password.resources.result
  end_date             = "2099-12-31T00:00:00Z"
}

resource "azurerm_role_assignment" "aks_sub_permissions" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.resources.object_id
}

resource "azuread_application" "server" {
  name                       = local.server_name
  identifier_uris            = ["https://${local.server_name}"]
  group_membership_claims    = "All"

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }

    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a"
      type = "Scope"
    }

    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "server" {
  application_id               = azuread_application.server.application_id
  app_role_assignment_required = false
}

resource "random_password" "server" {
  length  = 20
  special = true
}

resource "azuread_service_principal_password" "server" {
  service_principal_id = azuread_service_principal.server.id
  value                = random_password.server.result
  end_date             = "2099-12-31T00:00:00Z"
}

resource "null_resource" "server_grant" {
  depends_on = [
    azuread_service_principal.server
  ]

  provisioner "local-exec" {
    command = "${path.module}/Grant-Server.ps1 -AppId ${azuread_application.server.application_id}"
    interpreter = ["pwsh", "-Command"]
  }
}


resource "azuread_application" "client" {
  name                  = local.client_name
  reply_urls            = ["https://${local.client_name}"]
  type                  = "native"
  public_client         = true

  required_resource_access {
    resource_app_id = azuread_application.server.application_id

    resource_access {
      id   = azuread_application.server.oauth2_permissions[0].id
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "client" {
  application_id               = azuread_application.client.application_id
  app_role_assignment_required = false
}

resource "null_resource" "client_grant" {
  depends_on = [
    azuread_service_principal.client
  ]

  provisioner "local-exec" {
    command = "${path.module}/Grant-Client.ps1 -AppId ${azuread_application.client.application_id} -Api_AppId ${azuread_application.server.application_id}"
    interpreter = ["pwsh", "-Command"]
  }
}

# Windows Password
resource "random_password" "windows" {
  length  = 20
  special = true
}

# Create SSH Keys
resource "null_resource" "ssh_keys" {
  provisioner "local-exec" {
    command = "${path.module}/Create-SshKeys.ps1 -ClusterName ${local.cluster_name} -KeyVaultName ${module.kv.name}"
    interpreter = ["pwsh","-command"]
  }
}

data "azurerm_key_vault_secret" "public_key" {
  depends_on   = [null_resource.ssh_keys]
  name         = "SSHPublicKey"
  key_vault_id = module.kv.id
}

module "kv_secret_resources_appid" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

  name           = "ResourcesAppID"
  value          = azuread_service_principal.resources.application_id
  key_vault_id   = module.kv.id
  tags           = merge(local.tf_tags,{req_resources = module.kv_access_infra.id[0]})
}

module "kv_secret_resources_secret" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

  name           = "ResourcesSecret"
  value          = random_password.resources.result
  key_vault_id   = module.kv.id
  tags           = merge(local.tf_tags,{req_resources = module.kv_access_infra.id[0]})
}

module "kv_secret_server_appid" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

  name           = "ServerAppID"
  value          = azuread_service_principal.server.application_id
  key_vault_id   = module.kv.id
  tags           = merge(local.tf_tags,{req_resources = module.kv_access_infra.id[0]})
}

module "kv_secret_server_secret" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

  name           = "ServerSecret"
  value          = random_password.server.result
  key_vault_id   = module.kv.id
  tags           = merge(local.tf_tags,{req_resources = module.kv_access_infra.id[0]})
}

module "kv_secret_windows_secret" {
  source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

  name           = "WindowsPassword"
  value          = random_password.windows.result
  key_vault_id   = module.kv.id
  tags           = merge(local.tf_tags,{req_resources = module.kv_access_infra.id[0]})
}

# Create Log Analytics Workspaces
resource "azurerm_log_analytics_workspace" "log_analytics" {
  count               = var.include_log_analytics ? 1 : 0
  name                = "LAW-${local.cluster_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.is_hightrust ? 365 : 90
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  count               = var.log_analytics_name != "" ? 1 : 0
  name                = var.log_analytics_name
  resource_group_name = var.log_analytics_resource_group
  
}

# Set up local with log analytics workspace id to be used in the AKS cluster when required.
# Because we are using count to control instance creation we use [0] to get the first (and only) instance.
locals {
  log_analytics_configuration = var.include_log_analytics ? [azurerm_log_analytics_workspace.log_analytics[0].id] : var.log_analytics_name != "" ?  [data.azurerm_log_analytics_workspace.log_analytics[0].id] : []
}


# Set VNet Name based on naming policies for standard networks vs UDR networks
# For UDR networks we have separate Vnets for each cluster

locals {
  suffix = try(regex(".*(-Prod|-NonProd)",var.vnet_resource_group_name)[0], "")
  virtual_network_name = "VN-${local.sub_name}-${var.location}-AKS${local.suffix}"
  subnet_name = "SN-${local.sub_name}-${var.location}-${var.cluster_name}"
}

data "azurerm_virtual_network" "vn" {
  resource_group_name  = var.vnet_resource_group_name
  name                 = local.virtual_network_name
}


data "azurerm_subnet" "subnet" {
  count = 1

  name                 = local.subnet_name
  virtual_network_name = local.virtual_network_name
  resource_group_name  = var.vnet_resource_group_name
}

/*
********************************************************************
This section is not currently required - the subnet and route table
are  created via the VNet creation process, but could be moved to
the AKS cluster process in the future.
********************************************************************


# Configure Subnet based on CNI
# For Azure CNI we use the entire VNet address space
# For kubenet we use a /24 from the VNet address space


locals {
  subnet_exists = contains(data.azurerm_virtual_network.vn.subnets, "SN-${local.cluster_name}")
}

data "azurerm_subnet" "subnet" {
  count = local.subnet_exists ? 1 : 0

  name                 = "SN-${local.cluster_name}"
  virtual_network_name = "VN-${local.sub_name}-${var.location}-AKS"
  resource_group_name  = var.vnet_resource_group_name
}


# Get the number of bits in the VN address space prefix
# Set the modifier value so that cluster using Azure CNI will use the full
# VNet address range for a single subnet and clusters using kubenet
# Will use a /24 network from the VNet address space.
# The next process uses the address space of the subnet if it exists
# or gets the address space fron the vnet and then uses the modifier
# and the current count of subnets and get the cidr for the next subnet.
# 0 will return the first subnet, 1 the second, and so on
locals {
  bits = split("/",data.azurerm_virtual_network.vn.address_space[0])[1]
  modifier = var.udr_required ? local.bits : 24 - local.bits
  subnet_address_prefix = local.subnet_exists ? (
    data.azurerm_subnet.subnet[0].address_prefix
  ) : (
    cidrsubnet(data.azurerm_virtual_network.vn.address_space[0],local.modifier,length(data.azurerm_virtual_network.vn.subnets))
  )
}

resource "azurerm_subnet" "subnet" {
  name                 = "SN-${local.cluster_name}"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = "VN-${local.sub_name}-${var.location}-AKS"
  address_prefix       = local.subnet_address_prefix
}

# Custom route table
resource "azurerm_route_table" "rt" {
  count = var.udr_required ? 1 : 0

  name    = "RT-Test"
  location = var.location
  resource_group_name  = var.vnet_resource_group_name
}

resource "azurerm_route" "route_localvnet" {
  count                  = var.udr_required ? 1 : 0

  name                   = "Route-LocalVNetToVirtualAppliance"
  resource_group_name    = var.vnet_resource_group_name
  route_table_name       = azurerm_route_table.rt[0].name
  address_prefix         = data.azurerm_virtual_network.vn.address_space[0] # We typically use a single address space per AKS VNet
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.0.1"
}

# Make sure the local subnet does not go to the VNA
resource "azurerm_route" "route_localsubnet" {
  count                  = var.udr_required ? 1 : 0
  
  name                   = "Route-WithinSubnet"
  resource_group_name    = var.vnet_resource_group_name
  route_table_name       = azurerm_route_table.rt[0].name
  address_prefix         = azurerm_subnet.subnet.address_prefix
  next_hop_type          = "VnetLocal"
}

resource "azurerm_subnet_route_table_association" "example" {
  count = var.udr_required ? 1 : 0

  subnet_id      = azurerm_subnet.subnet.id
  route_table_id = azurerm_route_table.rt[0].id
}
*/

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  depends_on          = [azurerm_role_assignment.aks_sub_permissions]
  name                = local.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  node_resource_group = "RG-${local.cluster_name}-Resources"
  dns_prefix          = local.cluster_name
  kubernetes_version  = var.kubernetes_version


  default_node_pool {
    name               = "main"
    node_count         = var.node_count
    vm_size            = var.node_size
    os_disk_size_gb    = "1024"
    # Availability zones doesn't work with managed disks, therefore we cannot use at this time
    #availability_zones = []
    max_pods           = var.udr_required ? "50" : "150"
    type               = "VirtualMachineScaleSets"
    vnet_subnet_id     = data.azurerm_subnet.subnet[0].id
  }

  service_principal {
    client_id     = azuread_application.resources.application_id
    client_secret = random_password.resources.result
  }

  network_profile {
    # When using UDRs we must use Azure CNI to avoid route table issues
    network_plugin     = var.udr_required ? "azure" : "kubenet"
    load_balancer_sku  = "Basic"
    # When using Azure CNI we do not provide a pod cidr as subnet IPs are used
    pod_cidr           = var.udr_required ? null : "10.253.32.0/19"
    service_cidr       = "10.253.0.0/19"
    dns_service_ip     = "10.253.0.10"
    docker_bridge_cidr = "10.253.255.1/24"
  }

  linux_profile {
    admin_username = "aksadmin"
    ssh_key {
      key_data = data.azurerm_key_vault_secret.public_key.value
    }
  }

  dynamic "windows_profile" {
    for_each = var.udr_required ? [1] : []
    content {
      admin_username = "aksadmin"
      admin_password = random_password.windows.result
    }
  }

  role_based_access_control {
    enabled = true
    azure_active_directory {
      client_app_id     = azuread_service_principal.client.application_id
      server_app_id     = azuread_service_principal.server.application_id
      server_app_secret = random_password.server.result
    }
  }

  addon_profile {
    
    dynamic "oms_agent" {
      for_each = local.log_analytics_configuration
      content {
        enabled = true
        log_analytics_workspace_id = oms_agent.value
      }
    }

    kube_dashboard {
      enabled = true
    }
  }

  lifecycle {
    ignore_changes = [
      linux_profile[0].ssh_key,
      tags["CreatedDate"],
      tags["CreatorName"],
      tags["CreatorObjId"],
      tags["CreatorType"],
      tags["InitiatedBy"]
    ]
  }

  tags = local.tf_tags

}
