[[_TOC_]]

# Requirements
Requires AzureRM Provider 1.33.0 or later

<br>

# Updates
Changes from AzureImages 1.0.0.0
* Upgraded to support Terraform .12.x syntax
* Changed module name to AzureVMImage

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|image|No|Name of Image values to retrieve|string|image = "WS2019"|WS2016|

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|info|List of image values [Publisher,Offer,Sku,Windows\Linux]|List|

<br>

# Usage

## Example 1 - Use with default WS2016
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->
module "image" {
&emsp;source  = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureVMImage.zip"
}

## Example 2 - Provide an Image name (see table below)
module "image" {
&emsp;source  = "https://somestorageaccount.blob.core.windows.net/tfmodules/AzureVMImage.zip"
&emsp;image   = "WS2019"
}

<br>

# Supported OSes
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
