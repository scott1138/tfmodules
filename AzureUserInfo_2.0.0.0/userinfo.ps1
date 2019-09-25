$subscriptionId = $env:ARM_SUBSCRIPTION_ID
$tenantId = $env:ARM_TENANT_ID
$clientId = $env:ARM_CLIENT_ID
$secret = $env:ARM_CLIENT_SECRET

az.cmd login --service-principal --username $clientId --password $secret --tenant $tenantId --output none

$az_info = az account show --query "{displayName : user.name,objectType : user.type}" | ConvertFrom-Json

try {
    [guid]$az_info.displayName | Out-Null
    $isGUID = $true
}
catch {
    $isGUID = $false
}

if ($isGUID) {
    $spInfo = az ad sp show --id $az_info.displayName --query "{displayName : appDisplayName}" | ConvertFrom-Json
    $az_info | Add-Member -MemberType NoteProperty -Name 'objectId' -Value $az_info.displayName
    $az_info.displayName = $spInfo.displayName
} else {
    $userInfo = az ad user show --id $az_info.displayName --query "{displayName : displayName, objectId : objectId}" | ConvertFrom-Json
    $az_info | Add-Member -MemberType NoteProperty -Name 'objectId' -Value $userInfo.objectId
    $az_info.displayName = $userInfo.displayName
}

Write-Output "
{
    `"displayName`" : `"$($az_info.displayName)`",
    `"objectId`" : `"$($az_info.objectId)`",
    `"objectType`" : `"$($az_info.objectType)`",
    `"user`" : `"$env:Release_Deployment_RequestedFor`"
}
"


