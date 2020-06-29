[[_TOC_]]

# Requirements

* Provider
  * AzureRM 2.0.0 or greater
* Terraform
  * 0.12.23 or greater

# Description

This module will create an AKS cluster and all of the required components:
* AzureAD Applications
  * App and service principal for Azure resource creation
  * App and service principal for Server operations
  * App for client authentication
  * Grant required API permissions
* SSH keys
* Azure Key Vault
  * Add secrets for resource and server apps
  * Add secrets for SSH keys
  * Add the current execution identity to the Key Vault access policy.
* Create Log Analytics Workspace when required
* Create AKS 
  * OS Disk size set to 1TB for improved IOPS
  * Use is_hightrust and udr_required variables to determine:
    * Network module, Azure or Kubenet
    * Max Pods per Node, 50 or 150
    * Log Analytics Retention, 30 or 365 days
  * AzureAD RBAC enabled
  * Basic Load Balancer (Due to the Public IP forced on the Standard SKU)
  * No Availability Zones (Does not work well with managed disks)
  * Admin user aksadmin, keys stored in vault.



# Updates
No updates, this is the initial module creation

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|location|Yes|Location or region to create the resource.<br>Can be from the output of another resource or data source.|string|location="CentralUS"<br>location=azure_resource_group.rg.location<br>location=data.azure_resource_group.rg.location||
|resource_group_name|Yes|Name of the resource group where the new resources will be placed.<br>Can be from the output of another resource or data source.|string|resource_group_name = "RG-SomeRGName"<br>resource_group_name = azure_resource_group.rg.name<br>resource_group_name = data.azure_resource_group.rg.name||
|vnet_resource_group_name|Yes|Name of the resource group where the VNet resides.|string|vnet_resource_group_name = "RG-CentralUS-Networking"||
|cluster_name|Yes|Short name that represents the use of the cluster.<br>Examples: T1-Prod1, NonProd2, Sandbox1|string|cluster_name = Sandbox1||
|node_size|Yes|Azure VM size for the default node pool|string|node_size = "Standard_DS2_v2"||
|node_count|Yes|The number of nodes in the default node pool|number|node_count = 5||
|kubernetes_version|Yes|The version of Kubernetes to use for the masters and default node pool.<br>You can find available version using = az aks get-versions -l <region> -o table<br>NOTE: Changing this does not upgrade the node pool, only the masters.|string|kubernetes_version = "1.15.7"||
|include_log_analytics|No|Set value to true to create a log analytics workspace for the container logs and kubernetes insights|bool|include_log_analytics = true|false|
|is_hightrust|No|Set to true if the network zone is high trust.<br>Currently this sets the following values when false:<br>&emsp;Log Analytics retention to 30 days<br>Currently this sets the following values when true:<br>&emsp;Log Analytics retention to 365 days|bool|is_hightrust = true|false|
|udr_required|No|Set to true if user defined routing is required to reach a VNA<br>&emsp;Currently this sets the following when false:<br>&emsp;&emsp;Use the kubenet network plugin<br>&emsp;&emsp;Set the pod CIDR to 10.253.32.0/19<br>&emsp;&emsp;Set max pods per node to 150<br><br>&emsp;Currently this sets the following when true:<br>&emsp;&emsp;Use the Azure CNI network plugin<br>&emsp;&emsp;Does NOT set a pod CIDR<br>&emsp;&emsp;Set max pods per node to 50|bool|udr_required = true|false|
|tags|Yes|Key-Value pair for Azure resource tagging. Best if described as local and used repeatedly.|map(string)|locals<br>&emsp;tags=\{<br>&emsp;&emsp;Department="IT"<br>&emsp;&emsp;Project="X"<br>\}<br>...<br>tags = local.tags||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|node_resource_group|Name of the resource group that contains the AKS resources.|string|
|fqdn|FQDN of the Kubernetes API.|string|

<br>

# Usage

## Example 1 - Basic Deployment
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->

<br>

# Any other important stuff
