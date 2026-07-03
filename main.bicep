targetScope = 'subscription'

@description('Deployment environment. Used for naming, tags and environment-specific configuration.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Short lowercase application name used for consistent resource naming.')
@minLength(2)
@maxLength(5)
param applicationName string

@description('Azure region for all resources in this demo.')
@allowed([
  'westeurope'
])
param location string = 'westeurope'

@description('Business owner for governance and cost accountability.')
param owner string

@description('Cost center for showback/chargeback reporting.')
param costCenter string

@description('Optional Entra ID group object ID for the sample role assignment. Leave empty to skip role assignment.')
param principalId string = ''

@description('Role definition ID for the optional sample role assignment. Defaults to Reader.')
param roleDefinitionId string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

@description('Deploy the staging slot. Set to false to compare incremental Bicep behavior with Deployment Stack lifecycle management.')
param deployStagingSlot bool = true

var locationShort = 'we'
var normalizedApplicationName = toLower(applicationName)
var suffix = 'asr-${normalizedApplicationName}-${environment}-${locationShort}-001'
var globalUniqueSuffix = uniqueString(subscription().id)

var resourceGroupName = 'rg-${suffix}'
var vnetName = 'vnet-${suffix}'
var logAnalyticsName = 'log-${suffix}'
var appInsightsName = 'appi-${suffix}'
var appServicePlanName = 'asp-${suffix}'
var webAppName = 'app-${suffix}-${globalUniqueSuffix}'
var storageAccountName = 'st${normalizedApplicationName}${environment}${globalUniqueSuffix}'

var tags = {
  application: normalizedApplicationName
  environment: environment
  owner: owner
  costCenter: costCenter
  managedBy: 'bicep'
  customer: 'ASR'
}

resource appResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module monitoring 'modules/monitoring/logAnalytics.bicep' = {
  name: 'monitoring-${environment}'
  scope: appResourceGroup
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
    tags: tags
  }
}

module network 'modules/network/vnet.bicep' = {
  name: 'network-${environment}'
  scope: appResourceGroup
  params: {
    location: location
    vnetName: vnetName
    tags: tags
  }
}

module storage 'modules/storage/storageAccount.bicep' = {
  name: 'storage-${environment}'
  scope: appResourceGroup
  params: {
    location: location
    storageAccountName: storageAccountName
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    vnetId: network.outputs.vnetId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
}

module webApp 'modules/webapp/webApp.bicep' = {
  name: 'webapp-${environment}'
  scope: appResourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    deployStagingSlot: deployStagingSlot
    tags: tags
  }
}

// Demo-friendly: role assignment is enabled only when a real principalId is supplied.
module security 'modules/security/roleAssignments.bicep' = if (!empty(principalId)) {
  name: 'security-rbac-${environment}'
  scope: appResourceGroup
  params: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}

output resourceGroupName string = appResourceGroup.name
output vnetName string = network.outputs.vnetName
output storageAccountName string = storage.outputs.storageAccountName
output webAppName string = webApp.outputs.webAppName
output webAppDefaultHostName string = webApp.outputs.webAppDefaultHostName
output stagingSlotName string = webApp.outputs.stagingSlotName
output stagingSlotDefaultHostName string = webApp.outputs.stagingSlotDefaultHostName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
