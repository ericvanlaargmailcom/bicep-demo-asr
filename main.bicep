targetScope = 'subscription'

@description('Deployment environment. Used for naming, tags and environment-specific configuration.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Short lowercase application name. Keep this to 5 characters or fewer because Key Vault names have a 24 character limit.')
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

@description('Optional Entra ID principal object ID for the sample role assignment. Leave empty to skip role assignment.')
param principalId string = ''

@description('Role definition ID for the optional sample role assignment. Defaults to Reader.')
param roleDefinitionId string = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

var locationShort = 'we'
var normalizedApplicationName = toLower(applicationName)
var suffix = 'asr-${normalizedApplicationName}-${environment}-${locationShort}-001'

var resourceGroupName = 'rg-${suffix}'
var vnetName = 'vnet-${suffix}'
var logAnalyticsName = 'log-${suffix}'
var appInsightsName = 'appi-${suffix}'
var keyVaultName = 'kv-${suffix}'
var storageAccountName = 'st${normalizedApplicationName}${environment}${locationShort}001'

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

module keyVault 'modules/keyvault/keyVault.bicep' = {
  name: 'keyvault-${environment}'
  scope: appResourceGroup
  params: {
    location: location
    keyVaultName: keyVaultName
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
    vnetId: network.outputs.vnetId
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
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
output keyVaultName string = keyVault.outputs.keyVaultName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output applicationInsightsName string = monitoring.outputs.applicationInsightsName
