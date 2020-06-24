[[_TOC_]]

# Requirements

<br>

# Description
Create RBAC role assignments for Azure resources.

IMPORTANT: Use the object_id input whenever possible on resources created in the configuration.  Using "name" value requires look ups that may require the roles to be applied after the main configutation completes.

<br>

# Updates
First release

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|scope|Yes|The target resource id|string|scope = module.kv.id<br>scope = azurerm_resource_group.rg.id||
|role_name|Yes|The RBAC role to be used in the operation.<br>Use 'az role definition list' to view roles|string|role_name = "Contributor"<br>role_name = "AKS Cluster Configuration Reader"||
|service_principal_name|No|Name(s) of service prinicipal(s)|list|service_principal_name=["SP-Envision-Prod"]<br>service_prinicipal_name=["VM-PRDENVWFE01","VM-PRDENVWFE02"]<br>service_principal_name="${module.vm.server_names}"||
|user_principal_name|No|Name(s) of user(s)|list|user_principal_name=["Bob"]<br>user_principal_name=["Bob","Todd"]||
|group_name|No|Name(s) of group(s)|list|group_name=["GS-Envision-Devs"]<br>group_name=["GS-Envision-Devs","GS-DevOps"]||
|object_id|No|Object ID(s) of resources|list|object_id=["BIG_LONG_GUID"]<br>object_id=["BIG_LONG_GUID","ANOTHER_BIG_LONG_GUID"]||


<br>

# Outputs
|Name|Description|Type|
|---|---|---|

<br>

# Usage

## Example 1 - Basic Deployment
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->

<br>

# Any other important stuff
