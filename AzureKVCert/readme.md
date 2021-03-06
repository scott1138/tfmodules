[[_TOC_]]

# Requirements

<br>

# Description
The AzureKVCert module imports a certificate.  At this time it only supports importing a PFX.  Creating a cert or importing a PEM may be added later.

<br>

# Updates
NA

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|name|Yes|Name of the certificate|string|secret_name = "SENSIBLE_NAME"||
|cert_path|Yes|Path to the PFX file|string|cert_path = ".\cert.pfx"||
|cert_password|Yes|Password for the PFX file<br>This should be stored as a secret in the release and<br>replaced as a token at run time|cert_password = "{#cert_password#}"||
|key_vault_id|ID of the target Key Vault|string|keyvault_id = data.azurerm_key_vault.kv.id<br>keyvault_id = module.kv.keyvault_id||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|id|Azure resource ID for the certificate imported|string|
|thumbprint|X509 thumbprint of the certificate|string|

<br>

# Usage

## Example 1 - Data source output for the key vault id, Module output as key vault secret.
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->
locals {
&emsp;tags = {
&emsp;&emsp;Department = "SomeDept"
&emsp;&emsp;Project    = "SomeProject"
&emsp;&emsp;Shared     = "False"
&emsp;}
}

data "azurerm_key_vault" "kv" {
&emsp;name = "KV-SomeKeyVault"
&emsp;resource_group_name = "RG-SomeRGName"
}

module "storage" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVStorage.zip"

&emsp;storage_account_name = "somelowercasename"
&emsp;resource_group_name = "RG-SomeRGName"
&emsp;tags = local.tags
}

module "kvsecret" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

&emsp;secret_name = "SomeDescriptiveName"
&emsp;\# We want to use the output of another resource to hide the value of the secret and enhance our automation
&emsp;secret_value module.storage.primary_access_key
&emsp;keyvault_id = data.azurerm_key_vault.kv.id
&emsp;tags = local.tags
}

<br>

## Example 1 - Module output as the key vault id, token as key vault secret.
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

module "kv" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKeyVault.zip"

&emsp;name = "KV-AppName-Environment"
&emsp;resource_group_name = "RG-AppName-Region-Environment"
&emsp;tags = local.tags
}


module "kvsecret" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureKVSecret.zip"

&emsp;secret_name = "SomeDescriptiveName"
&emsp;\# We want to use a token replaced at run time to hide the value of the secret and enhance our automation
&emsp;secret_value "#{ReplaceMe!}#"
&emsp;keyvault_id = module.kv.id
&emsp;tags = local.tags
}

<br>

