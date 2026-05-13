@description('Azure region for monitoring resources.')
param location string

@description('Name of the Log Analytics Workspace.')
param logAnalyticsName string

@description('Name of the workspace-based Application Insights component.')
param appInsightsName string

@description('Standard governance tags.')
param tags object

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: union(tags, {
    'hidden-link:${workspace.id}': 'Resource'
  })
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 30
  }
}

output logAnalyticsWorkspaceId string = workspace.id
output logAnalyticsWorkspaceName string = workspace.name
output applicationInsightsName string = appInsights.name
output applicationInsightsConnectionString string = appInsights.properties.ConnectionString
