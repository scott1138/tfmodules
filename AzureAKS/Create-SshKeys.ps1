<#
.Synopsis
This script checks a Key Vault to see if the private key exists,
and if does not the key pair is created.

#>

[CmdletBinding()]
param
(
    [string]$ClusterName,
    [string]$KeyVaultName
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


Remove-Item -Path 'aksadmin','aksadmin.pub' -Force -ErrorAction SilentlyContinue

# Look for the private key in the key vault.  We can always gen the public key from that
# Only show the id of the secret if it exists so we don't record it in the logs
if ([bool](az keyvault secret show --name 'SSHPrivateKey' --vault-name "$KeyVaultName" --query id))
{
    # Do nothing, keys exist
}
else
{
    ssh-keygen -t rsa -b 2048 -C "$ClusterName" -f 'aksadmin' -q -N `"`"
    az keyvault secret set --name 'SSHPublicKey' --file aksadmin.pub --vault-name $KeyVaultName --output none
    az keyvault secret set --name 'SSHPrivateKey' --file aksadmin --vault-name $KeyVaultName --output none
}