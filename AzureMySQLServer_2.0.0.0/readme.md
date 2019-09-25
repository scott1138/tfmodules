[[_TOC_]]

# Requirements

<br>

# Description

<br>

# Updates
Changes since <ModuleName> <Version>

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|resource_group_name|Yes|Name of the resource group the MySQL server will be created|string|resource_group_name = "RG-SomeName"<br>resource_group_name = azurerm_resource_group.rg.name||
|location|Yes|Azure region where the MySQL server will be created|string|location = "South Central US"<br>location = azurerm_resource_group.rg.location||
|name|Yes|Name of the MySQL Server instance|string|name = "mysql-server-appname"||
|capacity|Yes|Number of vCores assigned to the MySQL instance<br>Available options determined by the tier|number|capacity = 2||
|family|No|CPU Generation Family to be used.  Currently only Gen5 is available|string|family = "Gen5"|Gen5|
|tier|Yes|The Sku Tier defines the Memory per vCore ratio, the storage type, and the maximum vCores<br>The options are:<br>B  = Base - 2GB per vcore, 1,2 vCores, Standard Storage (5GB - 1TB)<br>GP = GeneralPurpose - 5GB per vcore, 2,4,8,16,32,64 vCores, Premium Storage (5GB - 4TB)<br>MO = MemoryOptimized - 10GB per vcore, 2,4,8,16,32 vCores, Premium Storage (5GB - 4TB)<br>https://docs.microsoft.com/en-us/azure/mysql/concepts-pricing-tiers|string|tier = "B"<br>tier = "GP"<br>tier = "MO"||
|storage_mb|No|Max database size in MB. Min for all skus is 5120(5GB) and max is 104876(1TB) for Basic and 4194304(4TB) for the others|number|storage_mb = 10240|5120|
|admin_name|Yes|MySQL server administrator account name|string|admin_name = "something"||
|admin_password|Yes|MySQL server administrator account password|string|admin_password = "Th1si$@s3cr3T"||
|mysql_version|No|MySQL version, valid values are 5.6 and 5.7|string|mysql_version = "5.6"|5.7|
|tags|Yes|Key-Value pair for Azure resource tagging. Best if described as local and used repeatedly.|map|locals<br>&emsp;tags=\{<br>&emsp;&emsp;Department="IT"<br>&emsp;&emsp;Project="X"<br>\}<br>...<br>tags=local.tags|||


<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|name|Name of the MySQL Server|string|
|id|Azure resource ID|string|
|fqdn|Fully qualified domain name of the MySQL server for connection strings|string|

<br>

# Usage

## Example 1 - Basic Deployment
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->

<br>

# Any other important stuff
