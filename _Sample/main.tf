# SAMPLE TWO-TIER APPLICATION
# The #{xxx}# is used for token replacement with Azure DevOps Variables

provider "azurerm" {
  version = "~> 1.33.0"
}

terraform {
  required_version = "~> 0.12.0"

  backend "azurerm" {
    resource_group_name  = "RG-<Subscription_Name>-SouthCentralUS-Infrastructure"
    storage_account_name = "<storage_account_name>"
    container_name       = "<application_name>-#{env_name}#-tfstate"
    key                  = "<application_name>-#{env_name}#.tfstate"
  }

}

# Set tags values for all resources
# The env_name is entered on lowercase so we title case it for resource names
locals {
  tags = {
    Department = "Department"
    Project    = "Project"
    ProjectID  = "ProjectID"
  }

  env_name = title("#{env_name}#")
}

# Create our resource group
resource "azurerm_resource_group" "rg" {
  name     = "RG-<application_name>-${local.env_name}"
  location = "#{location}#"
  tags     = local.tags
}

# Create the web servers
module "vm" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureVM_2.0.0.0.zip"

  # VM definition
  quantity            = "#{vm_quantity}#"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_prefix           = "#{vm_prefix}#"
  vm_size             = "#{vm_size}#"
  image               = "Ubuntu18"

  data_disk = [
    {
      LUN     = "1"
      Size    = "1024"
      Caching = ""
    }
  ]

  ipaddresses = {
    "0" = "#{ip0}#"
    "1" = "#{ip1}#"
  }

  admin_username = "unixadm"
  ssh_key        = "./ssh.pub"
  
  diag_storage_account_rg   = "RG-<Subscription_Name>-SouthCentralUS-Infrastructure"
  diag_storage_account_name = "stgstd<Subscription_Name>diags"
  
  # Virtual Networking
  vnet_resource_group_name = "RG-<Subscription_Name>-Networking"
  vnet_name                = "VN-<Subscription_Name>-SouthCentralUS-App"
  subnet_name              = "#{subnet_name}#"

  tags = local.tags
}

# Create the web server load balancer
module "lb" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureBasicILB_2.0.0.0.zip"

  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  lb_prefix                   = "#{vm_prefix}#"
  frontend_private_ip_address = "#{lb_ip}#"
  
  lb_port = {
    http  = ["80","tcp","80"]
    https = ["443","tcp","443"]
  }

  network_interface_id = module.vm.network_interface_id

  # Virtual Networking
  vnet_resource_group_name = "RG-<Subscription_Name>-Networking"
  vnet_name                = "VN-<Subscription_Name>-SouthCentralUS-App"
  subnet_name              = "#{subnet_name}#"

  tags = local.tags
}

# Create the Azure MySQL PaaS instance
module "mysql_server" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureMySQLServer_2.0.0.0.zip"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "#{mysql_server_name}#"
  capacity            = "#{mysql_server_capacity}#"
  tier                = "#{mysql_server_tier}#"
  admin_name          = "mysqladmin"
  admin_password      = "#{admin_password}#"
  tags                = local.tags
}

# Allow Access to MySQL from Azure Services
resource "azurerm_mysql_firewall_rule" "mysql_fw_azure" {
  name                = "Azure_Services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = module.mysql_server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Allow Access to MySQL from the Freeman Akard datacenter and vpn
resource "azurerm_mysql_firewall_rule" "mysql_fw_akard" {
  name                = "DC_and_VPN"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = module.mysql_server.name
  start_ip_address    = "63.164.100.60"
  end_ip_address      = "63.164.100.64"
}

# Allow Access to MySQL from the Freeman Corporate office
resource "azurerm_mysql_firewall_rule" "mysql_fw_corp" {
  name                = "Corporate_Office"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = module.mysql_server.name
  start_ip_address    = "209.163.178.60"
  end_ip_address      = "209.163.178.60"
}

# Create a databse for freeman.com
module "mysql_database" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureMySQLDatabase_2.0.0.0.zip"

  name                = "#{mysql_database_name}#"
  resource_group_name = azurerm_resource_group.rg.name
  mysql_server_name   = module.mysql_server.name
}

# Create a key vault for storing secrets
module "kv" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKeyVault_2.0.0.0.zip"

  name = "KV-<application_name>-${local.env_name}"
  resource_group_name = azurerm_resource_group.rg.name
  tags = local.tags
}

# Allow the VM managed identities to access the key vault
module "kv_access_vm" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVAccess_2.0.0.0.zip"

  quantity            = "#{vm_quantity}#"
  key_vault_id        = module.kv.id
  object_id           = module.vm.principal_id
  secret_permissions  = ["get","set","list"]
}


# Allow SP used in ADO pipeline to add or read secrets
module "kv_access_ado_sp" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVAccess_2.0.0.0.zip"

  quantity                = "1"
  key_vault_id            = module.kv.id
  service_principal_name  = ["SP-Infrastructure-AzDevOps"]
  secret_permissions      = ["get","set","list","delete"]
  certificate_permissions = ["get","import","list","delete"]
}

# Add secret - MySQL Server FQDN
module "kv_secret_mysql_fqdn" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVSecret_2.0.0.0.zip"

  key_vault_id = module.kv.id
  name         = "mysql-fqdn"
  value        = module.mysql_server.fqdn
  tags         = local.tags
}

# Add secret - MySQL database name
module "kv_secret_mysql_db" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVSecret_2.0.0.0.zip"

  key_vault_id = module.kv.id
  name         = "mysql-db"
  value        = "#{mysql_database_name}#"
  tags         = local.tags
}

# Add secret - MySQL app user
module "kv_secret_mysql_app_user" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVSecret_2.0.0.0.zip"

  key_vault_id = module.kv.id
  name         = "mysql-app-user"
  value        = "#{mysql_app_user}#"
  tags         = local.tags
}

# Add secret - MySQL app user password
module "kv_secret_mysql_app_user_pw" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVSecret_2.0.0.0.zip"

  key_vault_id = module.kv.id
  name         = "mysql-app-user-pw"
  value        = "#{mysql_app_user_pw}#"
  tags         = local.tags
}

# Add certificate - web server cert
module "kv_cert_app" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVCert_2.0.0.0.zip"

  key_vault_id  = module.kv.id
  name          = "<application_name>"
  cert_path     = "../Certs/${local.env_name}.pfx"
  cert_password = "#{cert_password}#"
  tags          = local.tags
}

# Add secret - MySQL app user password
module "kv_secret_cert_pw" {
  source = "https://<storage_account_name>.blob.core.windows.net/terraformtemplates/AzureKVSecret_2.0.0.0.zip"

  key_vault_id = module.kv.id
  name         = "cert-password"
  value        = "#{cert_password}#"
  tags         = local.tags
}

output "vm" {
  value = module.vm
}

output "mysql_server" {
    value = module.mysql_server
}

output "mysql_database" {
    value = module.mysql_database
}