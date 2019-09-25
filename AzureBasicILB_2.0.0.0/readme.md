[[_TOC_]]

# Requirements
AzureRM module 1.33.x

<br>

# Description
This module create an Azure Basic Internal Load Balancer and assigns VM network interfaces to it.

<br>

# Updates
Changes since AzureBasicILB_1.0.0.0
* You can now provide network interface ids directly to the module to create the lb association
* The input variable resource_group is now resource_group_name

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|location|Yes|Location or region to create the resource.<br>Can be from the output of another resource or data source.|string|location="CentralUS"<br>location=azure_resource_group.rg.location<br>location=data.azure_resource_group.rg.location||
|resource_group_name|Yes|Name of the resource group where the new resources will be placed.<br>Can be from the output of another resource or data source.|string|resource_group_name = "RG-SomeRGName"<br>resource_group_name = azure_resource_group.rg.name<br>resource_group_name = data.azure_resource_group.rg.name||
|lb_prefix|Yes|Base name of the VM and it's related resources<br>Use the standard \<ENV\>\<APP_NAME\>\<PURPOSE\>|string|vm_prefix="DEVENVWFE"<br>vm_prefix="PRDDIISQL"||
|vnet_resource_group_name|Yes|Name of the resource group of the virtual network|string|vnet_resource_group_name="RG-<SubName>-Networking"||
|vnet_name|Yes|Name of the virtual network|string|vnet_name="VN-<SubName>-SouthCentralUS-App"||
|subnet_name|Yes|Name of the subnet for the LB resource|string|subnet_name="SN-<SubName>-SouthCentralUS-App-Prod"||
|frontend_private_ip_address|Yes|IP addressof the load balancer|string|frontend_private_ip_address = "10.10.10.10"||
|lb_port|No|Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]|map(list(string))|lb_port = {<br>&emsp;http = ["80","tcp","80"]<br>&emsp;https = ["443","tcp","443"]<br>}|lb_port = {<br>&emsp;https = ["443","tcp","443"]<br>}|
|lb_probe_unhealthy_threshold|No|Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy|number|lb_probe_unhealthy_threshold = 5|2|
|lb_probe_interval|No|Interval in seconds the load balancer health probe rule does a check|number|lb_probe_interval = 10|5|
|load_distribution|No|(Optional) Specifies the load balancing distribution type to be used by the Load Balancer. Possible values are:<br>**Default** – The load balancer is configured to use a 5 tuple hash to map traffic to available servers.<br>**SourceIP** – The load balancer is configured to use a 2 tuple hash to map traffic to available servers.<br>**SourceIPProtocol** – The load balancer is configured to use a 3 tuple hash to map traffic to available servers.<br>Also known as Session Persistence, where the options are called None, Client IP and Client IP and Protocol respectively.|string|load_distribution = "SourceIPProtocol"|"Default"|
|network_interface_id|Yes|The network interface ids to be assigned to this load balancer|list|network_interface_id = module.vm.network_interface_id||
|tags|Yes|Key-Value pair for Azure resource tagging. Best if described as local and used repeatedly.|map|locals<br>&emsp;tags=\{<br>&emsp;&emsp;Department="IT"<br>&emsp;&emsp;Project="X"<br>\}<br>...<br>tags=local.tags||

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
