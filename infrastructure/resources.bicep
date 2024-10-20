targetScope = 'resourceGroup'

param location string

var tags = {
  Project: 'ASP Container App'
  ResourceGroup: resourceGroup().name
}

// Log Analytics Workspaces
var logAnalyticsName = 'log-asp-container-app'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
}

// Storage Account - Diagnostics
var diagnosticsStorageAccountName = 'staspcontainerapp'

resource diagnosticsStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: diagnosticsStorageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_RAGRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

// Key Vault
var keyVaultName = 'kv-asp-container-app'

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    accessPolicies: [
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    enableRbacAuthorization: false
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
  }
}

resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'log-${keyVaultName}'
  scope: keyVault
  properties: {
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    storageAccountId: diagnosticsStorageAccount.id
    workspaceId: logAnalytics.id
  }
}

// App Serivce Plan
var appServicePlanName = 'asp-asp-container-app'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    tier: 'Premium0V3'
    name: 'P0V3'
  }
  properties: {
    targetWorkerCount: 1
    targetWorkerSizeId: 1
    reserved: false
  }
}

resource appServicePlanDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'log-${appServicePlanName}'
  scope: appServicePlan
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: true
        }
      }
    ]
    storageAccountId: diagnosticsStorageAccount.id
    workspaceId: logAnalytics.id
  }
}

// App Service


// Outputs
output logAnalyticsName string = logAnalytics.name
output logAnalyticsId string = logAnalytics.id
output diagnosticsStorageAccountName string = diagnosticsStorageAccount.name
output diagnosticsStorageAccountId string = diagnosticsStorageAccount.id
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output appServicePlanName string = appServicePlan.name
output appServicePlanId string = appServicePlan.id
