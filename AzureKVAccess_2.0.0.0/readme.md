[[_TOC_]]

# Requirements
Requires AzureRM provider 1.27.1 or later.

<br>

# Description
The AzureKVAccess module creates a key vault access policy. The object id for the security prinicipal directly or it can be provided as a service prinicipal, user, or group name.  Only one of these is required, but multiple types can be included.  Key, Secret, and Certificate permissions can set, but all permissions will be the same for all security principals.  At least one type of permission must be set.

IMPORTANT: Use the object_id and quantity inputs whenever possible on resources created in the configuration.  Using "name" values requires look ups that may require the access policies to be ablied after the main configutation completes.

# Updates
Changes since AzureKVAccess 1.0.0.0
* Add the ability to pass service principals, groups, or users as lists to create multiple resources

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|key_vault_id|Yes|Key vault to set access policies on|string|vault_name = module.kv.id||
|quantity|No|Number of policies to create, should match the number of identities input|number|quantity=2<br>quantity=10|1|
|service_principal_name|No|Name(s) of service prinicipal(s)|list|service_principal_name=["SP-Envision-Prod"]<br>service_prinicipal_name=["VM-PRDENVWFE01","VM-PRDENVWFE02"]<br>service_principal_name="${module.vm.server_names}"||
|user_principal_name|No|Name(s) of user(s)|list|user_principal_name=["Bob"]<br>user_principal_name=["Bob","Todd"]||
|group_name|No|Name(s) of group(s)|list|group_name=["GS-Envision-Devs"]<br>group_name=["GS-Envision-Devs","GS-DevOps"]||
|object_id|No|Object ID(s) of resources|list|object_id=["BIG_LONG_GUID"]<br>object_id=["BIG_LONG_GUID","ANOTHER_BIG_LONG_GUID"]||
|key_permissions|No|List of key permissions, must be one or more from the following:<br>backup, create, decrypt, delete, encrypt, get, import,<br>list, purge, recover, restore, sign, unwrapKey, update, verify and wrapKey|list|key_permissions=["get"]<br>key_permissions=["get","set","list"]||
|secret_permissions|No|List of secret permissions, must be one or more from the following:<br>backup, delete, get, list, purge, recover, restore and set|list|secret_permissions=["get"]<br>secret_permissions=["get","set","list"]||
|certificate_permissions|No|List of certificate permissions, must be one or more from the following:<br>backup, create, delete, deleteissuers, get, getissuers, import,<br>list, listissuers, managecontacts, manageissuers, purge, recover,<br>restore, setissuers and update|list|certificate_permissions=["get"]<br>certificate_permissions=["get","set","list"]||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|id|Resource IDs of policies created|list|

<br>

# Usage

## Example 1 - Deployment with VM Service Principal Names
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->
locals {
&emsp;tags = {
&emsp;&emsp;Department = "SomeDept"
&emsp;&emsp;Project    = "SomeProject"
&emsp;&emsp;Shared     = "False"
&emsp;}
}

resource "azurerm_resource_group" "rg" {
&emsp;name     = "RG-Region-Application-Environment"
&emsp;location = "Region"
&emsp;tags     = local.tags
}

module "vm" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureVM_2.0.0.0.zip"

&emsp;count = "2"
&emsp;admin_username = "admin_username"
&emsp;admin_password = "dont_include_in_code"
&emsp;location = azurerm_resource_group.rg.location
&emsp;resource_group = azurerm_resource_group.rg.name
&emsp;subnet_name = "SN-SubnetName"
&emsp;vm_prefix = "DEVPSPWFE"
&emsp;vm_size = "Standard_D2s_v3"
&emsp;os = "WS2016"
&emsp;os_disk_size = "256"
&emsp;vnet_name = "VN-VirtualNetworkName"
&emsp;vnet_resource_group_name = "RG-VirtualNetworkRGName"
&emsp;ipaddresses = {
&emsp;&emsp;"0" = "10.0.0.4"
&emsp;&emsp;"1" = "10.0.0.5"
&emsp;}
&emsp;diag_storage_account_name = "stgstd<SubName>diags"
&emsp;diag_storage_account_rg = "RG-<SubName>-SouthCentralUS-Infrastructure"
&emsp;tags = local.tags
}

module "kv" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureKeyVault_2.0.0.0.zip"

&emsp;name = "KV-AppName-Environment"
&emsp;resource_group_name = azurerm_resource_group.rg.name
&emsp;tags = local.tags
}

module "kv_access" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureKVAccess_2.0.0.0.zip"

&emsp;key_vault_id = module.kv.id
&emsp;resource_group_name = azurerm_resource_group.rg.name
&emsp;object_id = module.vm.id
&emsp;secret_permissions=["get"]
}

<br>

## Example 2 - Creating Key Vault access for a known group
module "kv_access" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureKVAccess_2.0.0.0.zip"

&emsp;key_vault_id = module.kv.id
&emsp;resource_group_name = azurerm_resource_group.rg.name
&emsp;group_name= ["GS-AzureHT-DevOps"]
&emsp;secret_permissions=["get","set","list"]
}

<br>
