@description('Entra ID group object ID.')
param principalId string

@description('Role definition ID. Defaults to Reader when supplied by main.bicep.')
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    principalType: 'Group'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

output roleAssignmentId string = roleAssignment.id
