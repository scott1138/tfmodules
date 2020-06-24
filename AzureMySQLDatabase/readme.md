[[_TOC_]]

# Requirements

<br>

# Description

<br>

# Updates
Initial Module

<br>

# Inputs
|Name|Required|Description|Type|Usage|Default|
|---|---|---|---|---|---|
|resource_group_name|Yes|Name of the resource group that contains the MySQL server|string|resource_group_name = "RG-SomeName"<br>resource_group_name = azurerm_resource_group.rg.name||
|name|Yes|Name of the database|string|name = "mysql-db-dbname"||
|mysql_server_name|Yes|Name of the MySQL Server to hold the database|string|mysql_server_name = module.mysql_server.name||

<br>

# Outputs
|Name|Description|Type|
|---|---|---|
|id|Azure resource ID|string|
|name|Name of the database|string|

<br>

# Usage

## Example 1 - Basic Deployment
<!-- In VS Code the line feeds don't show in the markdown preview but it is correct on the Azure DevOps Wiki -->


<br>

# Any other important stuff
