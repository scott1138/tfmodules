provider "azurerm" {
    version = "~>2.0"
    subscription_id = "SubscriptionID"
    features {}
}

provider "azurerm" {
    alias = "second_sub"
    version = "~>2.0"
    subscription_id = "SubscriptionID"
    features {}
}

terraform {
    required_version = "~> 0.12.24"

    backend "azurerm" {}
}


# Set up locals used for the build
locals {
    app_name = "MyCoolApp"
    app_short_name = "MCApp"
    subnet_name = "SN-${local.app_short_name}-${local.env_name}"
    location = "SouthCentralUS"
    location_short = "SCUS"
    env_name = title(var.env_name)

    env_abbreviations = {
        Dev = "DEV"
        Test = "TST"
        Prod = "PRD"
    }

    env_name_short = local.env_abbreviations[local.env_name]

    tags = {
        Application = "My Cool App"
        Environment = "${var.env_tag}"
    }
}

# Current Azure Conenction info
data "azurerm_client_config" "current" {
}

# Get Log Analytics Workspace info
data "azurerm_log_analytics_workspace" "law" {
    provider = azurerm.second_sub
    name = "LAW-MyOrg"
    resource_group_name = "RG-LogAnalytics"
}

# Get subnet info for VM
data "azurerm_subnet" "app_subnet" {
    name = var.vm_subnet_name
    virtual_network_name = "VN-MySubscription-SouthCentralUS-MyCoolApp"
    resource_group_name = "RG-MySubscription-Networking-SouthCentralUS"
}

# Data - MyCoolApp AD group
data "azuread_group" "dev_group" {
    name = "GS-Azure-Developer-MyCoolApp"
}

data "azuread_group" "sqladmin_group" {
    name = "GS-Azure-SQLAdmins"
}

/*
# This has already been done manually, but leaving it in for info
resource "azurerm_marketplace_agreement" "wowza_agreement" {
    publisher = "wowza"
    offer = "wowzastreamingengine"
    plan = "windows-paid"
}
*/


# Resource group
resource "azurerm_resource_group" "rg" {
    name = "RG-${local.app_name}-${local.location}-${local.env_name}"
    location = local.location
    tags = local.tags
}


# RG permissions for Dev Group
resource "azurerm_role_assignment" "rg_rbac_devs_reader" {
    scope = azurerm_resource_group.rg.id
    principal_id = data.azuread_group.dev_group.id
    role_definition_name = "Reader"
}

resource "azurerm_role_assignment" "rg_rbac_devs_website_contributor" {
    scope = azurerm_resource_group.rg.id
    principal_id = data.azuread_group.dev_group.id
    role_definition_name = "Website Contributor"
}


# Subnet for App Service Plan VNI, should be at least a /27, /26 is better
resource "azurerm_subnet" "vni_subnet" {
    name = local.subnet_name
    address_prefixes = var.vni_address_prefixes
    resource_group_name = "RG-MySubscription-Networking-SouthCentralUS"
    virtual_network_name = "VN-MySubscription-SouthCentralUS-MyCoolApp-VNI"
    service_endpoints = ["Microsoft.Sql"]

    delegation {
        name = "Vnet Integration"

        service_delegation {
            name = "Microsoft.Web/serverFarms"
        }
    }

    # Extend delete time out to wait for VNI to be removed.
    timeouts {
        delete = "30m"
    }

}

# Key Vault
module "kv" {
    source = "https://github.com/scott1138/tfmodules/AzureKeyVault"

    name = "KV-${local.app_name}-${local.env_name}"
    resource_group_name = azurerm_resource_group.rg.name
    location = local.location
    tags = local.tags
}

# Key Vault Acccess Policy for account running tf
module "kv_access_ado" {
    source = "https://github.com/scott1138/terraformtemplates/AzureKVAccess"

    key_vault_id = module.kv.id
    object_id = [data.azurerm_client_config.current.object_id]
    secret_permissions = ["get","set","list","delete"]
}


# Storage account
resource "azurerm_storage_account" "stg_acct" {
    name = "${lower(local.app_short_name)}${lower(local.location_short)}${lower(local.env_name)}"
    resource_group_name = azurerm_resource_group.rg.name
    location = local.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    enable_https_traffic_only = true
    tags = local.tags
}

# App Insights
resource "azurerm_application_insights" "ai" {
  name                = "AI-${local.app_name}-${local.location}-${local.env_name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"

  tags = local.tags
}

# SQL Server
# Enable Adv Data Security? 
# azurerm_mssql_server_security_alert_policy, azurerm_mssql_server_vulnerability_assessment
# Audit Logging?
resource "azurerm_mssql_server" "sql_server" {
    name = "sql-server-${lower(local.app_short_name)}-${lower(local.location_short)}-${lower(local.env_name)}"
    resource_group_name          = azurerm_resource_group.rg.name
    location                     = local.location
    version                      = "12.0"
    administrator_login          = "sqladmin"
    administrator_login_password = var.sqladmin_password
    tags = local.tags

    azuread_administrator {
        login_username = data.azuread_group.sqladmin_group.name
        object_id      = data.azuread_group.sqladmin_group.id
    }

}

# SQL Server Firewall Rules
# Allow internet - datcenters and office
# Deny Azure Services
resource "azurerm_sql_firewall_rule" "sql_fw_dc" {
    name                = "Allow Datacenter"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mssql_server.sql_server.name
    start_ip_address    = "10.1.1.0"
    end_ip_address      = "10.1.1.3"
}

resource "azurerm_sql_firewall_rule" "sql_fw_office" {
    name                = "Allow Office"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mssql_server.sql_server.name
    start_ip_address    = "10.1.2.0"
    end_ip_address      = "10.1.2.3"
}

# Sql Server Virtual Network Rule
# Allow VNI subnet
resource "azurerm_sql_virtual_network_rule" "sql_fw_vni" {
    name                = "Allow-MycoolApp-VNI"
    resource_group_name = azurerm_resource_group.rg.name
    server_name         = azurerm_mssql_server.sql_server.name
    subnet_id           = azurerm_subnet.vni_subnet.id
}

# SQL Database
# Diagnostics Settings?
resource "azurerm_mssql_database" "sql_db" {
    name       = "sql-db-${lower(local.app_short_name)}-${lower(local.location_short)}-${lower(local.env_name)}"
    server_id  = azurerm_mssql_server.sql_server.id
    sku_name   = "S2"
    tags       = local.tags
}

# Build string from SQL Database output
locals {
    ConnectionStringsDefault = join("",list(
        "Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;",
        "Initial Catalog=${azurerm_mssql_database.sql_db.name};",
        "Persist Security Info=False;",
        "User ID=${var.sql_app_userid};",
        "Password=${var.sql_app_password};",
        "MultipleActiveResultSets=False;",
        "Encrypt=True;",
        "TrustServerCertificate=False;",
        "Connection Timeout=30;"
    ))
}

# SQL Connection string secret
resource "azurerm_key_vault_secret" "sql_conn_string" {
  name         = "ConnectionStringsDefault"
  value        = local.ConnectionStringsDefault
  key_vault_id = module.kv.id
  tags         = local.tags
  depends_on   = [module.kv_access_ado]
}

# App Service Plan
resource "azurerm_app_service_plan" "app_svc_plan" {
  name                = "AP-${local.app_name}-${lower(local.location_short)}-${local.env_name}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true # requirement with Linux app service plan
  tags                = local.tags

  sku {
    tier = var.app_service_tier
    size = var.app_service_sku
  }
}

# web app service
resource "azurerm_app_service" "web" {
    name = "${lower(local.app_short_name)}-web-${lower(local.location_short)}-${lower(local.env_name)}"
    location = local.location
    resource_group_name = azurerm_resource_group.rg.name
    app_service_plan_id = azurerm_app_service_plan.app_svc_plan.id
    enabled = true
    https_only = true
    tags = local.tags

    site_config {
        always_on = true
        ftps_state = "FtpsOnly"
        use_32_bit_worker_process = false

        
        ip_restriction {
            name = "Allow Datacenter"
            ip_address = "10.1.1.0/30"
            priority = 100
            action = "Allow"
        }

        ip_restriction {
            name = "Allow Office"
            ip_address = "10.1.2.0/30"
            priority = 200
            action = "Allow"
        }

        ip_restriction {
            name = "Allow Application Gateway"
            ip_address = var.app_gw_ip
            priority = 300
            action = "Allow"
        }
    }

}

# api app service
# ip_restriction - allow data center and off IPS, allowed WAF Public IP (from var)
resource "azurerm_app_service" "api" {
    name = "${lower(local.app_short_name)}-api-${lower(local.location_short)}-${lower(local.env_name)}"
    location = local.location
    resource_group_name = azurerm_resource_group.rg.name
    app_service_plan_id = azurerm_app_service_plan.app_svc_plan.id
    enabled = true
    https_only = true
    tags = local.tags

    connection_string {
        name = "default"
        type = "SQLServer"
        value = "@Microsoft.Keyvault(${azurerm_key_vault_secret.sql_conn_string.id})"
    }

    identity {
        type = "SystemAssigned"
    }

    site_config {
        always_on = true
        ftps_state = "FtpsOnly"
        use_32_bit_worker_process = false

        ip_restriction {
            name = "Allow Datacenter"
            ip_address = "10.1.1.0/30"
            priority = 100
            action = "Allow"
        }

        ip_restriction {
            name = "Allow Office"
            ip_address = "10.1.2.0/30"
            priority = 200
            action = "Allow"
        }

        ip_restriction {
            name = "Application Gateway"
            ip_address = var.app_gw_ip
            priority = 300
            action = "Allow"
        }
    }

}

# Add VNet Integration for API App Service
resource "azurerm_app_service_virtual_network_swift_connection" "api_vni" {
    app_service_id = azurerm_app_service.api.id
    subnet_id = azurerm_subnet.vni_subnet.id
}


# Key vault access policy for api app service
# Get Secrets from key vault
module "kv_access_api" {
    source = "https://github.com/scott1138/terraformtemplates/AzureKVAccess"

    key_vault_id = module.kv.id
    object_id = [azurerm_app_service.api.identity[0].principal_id]
    secret_permissions = ["get"]
}


# Wowza VM NI
resource "azurerm_network_interface" "wowza_ni" {
  name                = "NI-${upper(local.env_name_short)}EOPWZA01"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Wowza VM
resource "azurerm_windows_virtual_machine" "wowza_vm" {
    name                = "VM-${upper(local.env_name_short)}MCAWZA01"
    resource_group_name = azurerm_resource_group.rg.name
    location            = local.location
    size                = "Standard_DS2_v2"
    admin_username      = "winadmin"
    admin_password      = var.winadmin_password
    network_interface_ids = [
        azurerm_network_interface.wowza_ni.id,
    ]

    os_disk {
        name                 = "DISK-${upper(local.env_name_short)}EOPWZA01-OS"
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "wowza"
        offer     = "wowzastreamingengine"
        sku       = "windows-paid"
        version   = "latest"
    }

    plan {
        name = "windows-paid"
        product = "wowzastreamingengine"
        publisher = "wowza"
    }

    identity {
        type = "SystemAssigned"
    }

    tags = local.tags
}

# Get Key Vault info for domain join secret
data "azurerm_key_vault" "dj_kv" {
  name = "KV-Deployment-SCUS"
  resource_group_name = "RG-MySubscription-SouthCentralUS-Infrastructure"
}

data "azurerm_key_vault_secret" "dj_pw" {
  name = "AutomatedDomainJoin"
  key_vault_id = data.azurerm_key_vault.dj_kv.id
}

# Domain Join Wowza server
module "domain_join_wowza" {
  source = "https://github.com/scott1138/terraformtemplates/AzureVMDomainJoin"

  quantity = 1
  virtual_machine_id = [azurerm_windows_virtual_machine.wowza_vm.id]
  domain = "example.com"
  user = "sa-domjoin"
  password = data.azurerm_key_vault_secret.dj_pw.value

  tags = local.tags
}


# Enable diagnostics for desired resources
module "enable_diags" {
    source = "https://github.com/scott1138/terraformtemplates/AzureDiagSetting"

    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
    resource_id = [module.kv.id,azurerm_windows_virtual_machine.wowza_vm.id]
}
