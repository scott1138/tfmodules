[CmdletBinding()]
param
(
    [string]$AppId
)

$subscriptionId = $env:ARM_SUBSCRIPTION_ID
$tenantId = $env:ARM_TENANT_ID
$clientId = $env:ARM_CLIENT_ID
$secret = $env:ARM_CLIENT_SECRET

$Context = az account show | ConvertFrom-Json

if ($Context)
{
    Write-Host "Executing under local user context"
}
else
{
    az login --service-principal --username $clientId --password $secret --tenant $tenantId --output none
}


az ad app permission admin-consent --id $AppId