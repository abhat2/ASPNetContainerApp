# Script to deploy infrastructure resource in Azure for the container app
# Instructions:
# 1. In PowerShell terminal run the command - .\infrastructure\deploy.ps1 -TenantId "your tenant ID" -SubscriptionId "your subscription ID"
# #################################################
param (
    [Parameter(Mandatory = $true)]
    [string]
    $TenantId,

    [Parameter(Mandatory = $true)]
    [string]
    $SubscriptionId
)

$dateTimeStamp = Get-Date -Format "yyyyMMddhhmm"
$location = "Australia East"

# Connect to Azure tenant and subscription
Connect-AzAccount -Tenant $TenantID -Subscription $SubscriptionId

# Deploy resource groups template
$deploymentName =  "ResourceGroupsDeployment$dateTimeStamp"
New-AzSubscriptionDeployment -Name $deploymentName -Location $location -TemplateFile .\infrastructure\resource-group.bicep

$resourceGroupName = "rg-asp-container-app"

# Deploy resources template
$deploymentName =  "ResourcesDeployment$dateTimeStamp"
New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $resourceGroupName -Location $location -TemplateFile .\infrastructure\resources.bicep
