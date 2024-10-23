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

// Azure Container Registry
var containerRegistryName = 'acraspcontainerapp'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

// App Service Plan
var appServicePlanName = 'asp-asp-container-app'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    tier: 'PremiumMV3'
    name: 'P1mv3'
  }
  kind: 'windows'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: true
    maximumElasticWorkerCount: 3
    isXenon: true
    hyperV: true
    targetWorkerCount: 1
    targetWorkerSizeId: 1
    reserved: false
    zoneRedundant: false
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

// App Insights
var appInsightsName = 'ai-asp-container-app'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 90
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: logAnalytics.id
  }
}

// App Service
var appServiceName = 'app-asp-container-app'

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,container,windows'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: true
    hyperV: true
    siteConfig: {
      numberOfWorkers: 1
      windowsFxVersion: 'DOCKER|mcr.microsoft.com/azure-app-service/windows/parkingpage:latest'
      alwaysOn: true
      http20Enabled: false
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://mcr.microsoft.com'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: null
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
      ]
      ipSecurityRestrictions: []
    }
    httpsOnly: true
    redundancyMode: 'None'
  }
}

// App Service Slot - staging
var slotName = 'staging'

resource appServiceStaging 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: appService
  name: slotName
  location: location
  tags: tags
  kind: 'app,container,windows'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    reserved: false
    isXenon: true
    hyperV: true
    siteConfig: {
      numberOfWorkers: 1
      windowsFxVersion: 'DOCKER|mcr.microsoft.com/azure-app-service/windows/parkingpage:latest'
      alwaysOn: true
      http20Enabled: false
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://mcr.microsoft.com'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: null
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'true'
        }
      ]
      ipSecurityRestrictions: []
    }
    httpsOnly: true
    redundancyMode: 'None'
  }
}

// Outputs
output logAnalyticsName string = logAnalytics.name
output logAnalyticsId string = logAnalytics.id
output diagnosticsStorageAccountName string = diagnosticsStorageAccount.name
output diagnosticsStorageAccountId string = diagnosticsStorageAccount.id
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output containerRegistryName string = containerRegistry.name
output containerRegistryId string = containerRegistry.id
output appServicePlanName string = appServicePlan.name
output appServicePlanId string = appServicePlan.id
output appInsightsName string = appInsights.name
output appInsightsId string = appInsights.id
output appServiceName string = appService.name
output appServiceId string = appService.id
output appServiceStagingName string = appServiceStaging.name
output appServiceStagingId string = appServiceStaging.id
