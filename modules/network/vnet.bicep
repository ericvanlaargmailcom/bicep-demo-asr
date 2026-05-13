@description('Azure region for the network resources.')
param location string

@description('Name of the virtual network.')
param vnetName string

@description('Standard governance tags.')
param tags object

var appSubnetName = 'subnet-app'
var dataSubnetName = 'subnet-data'
var privateEndpointSubnetName = 'subnet-private-endpoints'

resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${vnetName}-app'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsOutbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
      {
        name: 'DenyInternetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource dataNsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${vnetName}-data'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'DenyInternetInbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: appSubnetName
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: appNsg.id
          }
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: '10.10.2.0/24'
          networkSecurityGroup: {
            id: dataNsg.id
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: '10.10.10.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output appSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, appSubnetName)
output dataSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, dataSubnetName)
output privateEndpointSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, privateEndpointSubnetName)
