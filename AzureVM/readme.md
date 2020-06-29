[[_TOC_]]

# Requirements
Requires AzureRM Provider 1.33.0 or later

<br>

# Updates
Changes from AzureVM 1.1.0.0
* Upgraded to support Terraform HCL2 syntax
* The input variable count is now named quantity and is a number type. (count has become a reserved keyword in HCL 2)
* Moved data disk under virtual machine resource
* Added support for multiple data disks
* Changed OS variable to Image.  Moved image table to AzureVMImage module
* The input variable resource_group is now resource_group_name
* Added a principal_id output for system managed identity
* Dynamic blocks for data disks allowed the remove of separate data disk resources.  There is now just win_vm and linux_vm.

Changes from AzureVM 1.0.0.0
* Does not delete data disks on VM destroy (fixes issue with data disks being deleted but still being in state).
* Enabled Windows Server Hybrid Use Benefit.
* Configures WinRM to that Terraform provisioner can connect.
* Added additional OS support

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|quantity|No|Number of Virtual Machines to create|number|quantity=2<br>quantity=10|1|
|location|Yes|Location or region to create the resource.<br>Can be from the output of another resource or data source.|string|location="CentralUS"<br>location=azure_resource_group.rg.location<br>location=data.azure_resource_group.rg.location||
|resource_group_name|Yes|Name of the resource group where the new resources will be placed.<br>Can be from the output of another resource or data source.|string|resource_group_name = "RG-SomeRGName"<br>resource_group_name = azure_resource_group.rg.name<br>resource_group_name = data.azure_resource_group.rg.name||
|vm_prefix|Yes|Base name of the VM and it's related resources<br>Use the standard \<ENV\>\<APP_NAME\>\<PURPOSE\>|string|vm_prefix="DEVENVWFE"<br>vm_prefix="PRDDIISQL"||
|vm_size|Yes|Azure VM Size<br>az vm list-sizes --location centralus --output table|string|vm_size="Standard_D2s_v3"||
|vnet_resource_group_name|Yes|Name of the resource group of the virtual network|string|vnet_resource_group_name="RG-<SubName>-Networking"||
|vnet_name|Yes|Name of the virtual network|string|vnet_name="VN-<SubName>-SouthCentralUS-App"||
|subnet_name|Yes|Name of the subnet the VM will join|string|subnet_name="SN-<SubName>-SouthCentralUS-App-Prod"||
|ipaddress|Yes|IP addresses of VM(s) as a map using count indexes<br>example: 0,1,2,3...|map|ip_address = \{<br>&emsp;"0"="10.0.0.1"<br>&emsp;"1"="10.0.0.2"<br>\}||
|image|No|Operating system to be used as an OS<br>[OS Table](#Supported-OSes)|string|os="WS2019"<br>os="SQL2016SP2-WS2016"|WS2016|
|os_disk_size|No|Size of the OS disk in GB<br>There is no variable default, but the module uses 128 GB for both Windows and Linux VMs<br>[Azure disk sizing](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage-performance#premium-storage-disk-sizes)|string|os_disk_size="256"||
|data_disk|No|Data Disk configuration details<br>Valid values for Caching are Blank(defaults to ReadOnly), ReadOnly, ReadWrite, or None.<br>[Azure disk sizing](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/premium-storage-performance#premium-storage-disk-sizes)|list of maps|data_disk=[<br>&emsp;{<br>&emsp;&emsp;LUN = "1"<br>&emsp;&emsp;Size="1024"<br>&emsp;&emsp;Caching="None"<br>&emsp;},<br>&emsp;{<br>&emsp;&emsp;LUN = "2"<br>&emsp;&emsp;Size="1024"<br>&emsp;&emsp;Caching="ReadWrite"<br>&emsp;}<br>]||
|admin_username|Yes|Admin user for the system.  Azure does not allow Admin or Administrator.<br>Defaults are winadmin for Windows and unixadm for Linux.<br>This may become integrated into the module in the future.|string|admin_username="winadmin"<br>admin_username="unixadm"||
|admin_password|No|Used only for Windows VMs<br>Should either be a variable provided at runtime or replaced as a token during build|string|admin_password=var.admin_password<br>admin_password="#\{ADO_RELEASE_VAR_TOKEN\}#"||
|ssh_key|No|Used only for Linux VMs.<br>Path to a key file relative to the configuration root|string|ssh_key=".\\ssh_key.pub"<br>ssh_key="..\\keypath\\ssh_key.pub"||
|diag_storage_account_name|Yes|Name of the storage account for diagnostic data<br>Each subscription has an account created for this.<br>The name will typically be stgstd<sub_name>diags.|string|diag_storage_account_name="stgstd<SubName>diags"||
|diag_storage_account_rg|Yes|Name of the resource group for the diagnostic storage account<br>The name will typically be RG-<Sub_Name>-<Region>-Infrastructure.|string|diag_storage_account_rg="RG-<SubName>-SouthCentralUS-Infrastructure"||
|tags|Yes|Key-Value pair for Azure resource tagging. Best if described as local and used repeatedly.|map|locals<br>&emsp;tags=\{<br>&emsp;&emsp;Department="IT"<br>&emsp;&emsp;Project="X"<br>\}<br>...<br>tags=local.tags||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|network_interface_id|Resource IDs of created interfaces|list|
|id|Resource IDs of created VMs|list|
|name|Names of created VMs|list|
|principal_id|Manages system identity of the VM|list|

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
&emsp;tags     = local.tags
}

module "vm" {
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureVM.zip"

&emsp;count = "2"
&emsp;admin_username = "admin_username"
&emsp;admin_password = "dont_include_in_code"
&emsp;location = azurerm_resource_group.rg.location
&emsp;resource_group_name = azurerm_resource_group.rg.name
&emsp;subnet_name = "SN-SubnetName"
&emsp;vm_prefix = "DEVPSPWFE"
&emsp;vm_size = "Standard_D3s_v3"
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

<br>

## Example 2 - Multiple Data Disks
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
&emsp;source = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureVM.zip"

&emsp;count = "2"
&emsp;admin_username = "admin_username"
&emsp;admin_password = "dont_include_in_code"
&emsp;location = azurerm_resource_group.rg.location
&emsp;resource_group_name = azurerm_resource_group.rg.name
&emsp;subnet_name = "SN-SubnetName"
&emsp;vm_prefix = "DEVPSPWFE"
&emsp;vm_size = "Standard_D3s_v3"
&emsp;os = "WS2016"
&emsp;os_disk_size = "256"
&emsp;data_disk = [
&emsp;    {
&emsp;&emsp;LUN     = "1"
&emsp;&emsp;Size    = "1024"
&emsp;&emsp;Caching = ""
&emsp;},
&emsp;{
&emsp;&emsp;LUN     = "2"
&emsp;&emsp;Size    = "1024"
&emsp;&emsp;Caching = "ReadWrite"
&emsp;}
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

<br>

# Supported Image Names
|Terraform OS Name|Description|
|---|---|
|Ubuntu16|Ubuntu 16.04 LTS|
|Ubuntu18|Ubuntu 18.04 LTS|
|WS2019|Windows Server 2019|
|WS2019-Core|Windows Server 2019 Core|
|WS2016|Windows Server 2016|
|WS2016-Core|Windows Server 2016 Core|
|WS2012R2|Windows Server 2012 R2|
|SQL2016SP2STD-WS2016|SQL Server 2016 SP2 Standard on Windows Server 2016|
|SQL2016SP2ENT-WS2016|SQL Server 2016 SP2 Enterprise on Windows Server 2016|
|SQL2016SP2DEV-WS2016|SQL Server 2016 SP2 Developer (No Cost) on Windows Server 2016|
|SQL2017STD-WS2016|SQL Server 2017 SP2 Standard on Windows Server 2016|
|SQL2017ENT-WS2016|SQL Server 2017 SP2 Enterprise on Windows Server 2016|
|SQL2017DEV-WS2016|SQL Server 2017 SP2 Developer (No Cost) on Windows Server 2016|
