[[_TOC_]]

# Requirements

<br>

# Updates

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|name|Yes|Name of the Key Vault to be created|string|vault_name="KV-<AppName>-Prod"<br>vault_name = "KV-<AppName>-NonProd"||
|resource_group_name|Yes|Name of the resource group where the new resources will be placed.<br>Can be from the output of another resource or data source.|string|resource_group_name = "RG-SomeRGName"<br>resource_group = azure_resource_group.rg.name<br>resource_group = data.azure_resource_group.rg.name||
|tags|Yes|Key-Value pair for Azure resource tagging. Best if described as local and used repeatedly.|map|locals<br>&emsp;tags = {<br>&emsp;&emsp;Department = "IT"<br>&emsp;&emsp;Project = "X"<br>}<br>...<br>tags = local.tags||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|id|Resource ID of the key vault|string|
|uri|URI of the key vault for https connectivity|string|
|name|Name of the key vault|string|

<br>

# Usage

## Example 1 - Basic Deployment
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
&emsp;tags     = "local.tags
}

module "kv" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/terraformtemplates/AzureKeyVault_2.0.0.0.zip"

&emsp;name = "KV-AppName-Environment"
&emsp;resource_group_name = "RG-AppName-Region-Environment"
&emsp;tags = local.tags
}

<br>

