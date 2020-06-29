[[_TOC_]]

# Requirements
External provider

<br>

# Description
Returns the name, object_id, and object_type of the user executing the commands.  Meant to be used internal to modules.

<br>

# Updates
Changes since <ModuleName> <Version>

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|name|Display name of the active user|string|
|object_id|Object ID of the active user|string|
|object_type|Object type of the active user:<br>User, ServicePrincipal, ManagedIdentity, etc|string|

<br>

# Usage

## Example 1 - Basic Deployment
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->
module "userinfo" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureUserInfo.zip"
}

locals {
&emsp;base_tags = {
&emsp;&emsp;Source       = "TFModule-AzureVM"
&emsp;&emsp;CreatedDate  = timestamp()
&emsp;&emsp;CreatorName  = module.userinfo.name
&emsp;&emsp;CreatorObjId = module.userinfo.object_id
&emsp;&emsp;CreatorType  = module.userinfo.object_type
&emsp;}
<br>
&emsp;tf_tag = module.userinfo.ado_user != "" ? merge(local.base_tags,{InitiatedBy = module.userinfo.ado_user}) : local.base_tags
}



<br>

# Any other important stuff
