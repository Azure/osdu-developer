targetScope = 'resourceGroup'

@minLength(3)
@maxLength(22)
@description('Required. Used to name all resources')
param resourceName string

// Dependency: Storage
module storage '../../storage-account/main.bicep' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    sku: 'Standard_LRS'
  }
}

// Dependency: Private DNS Zone
var publicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var privateDnsZoneName = 'privatelink.${publicDNSZoneForwarder}'

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

// Dependency: Network
module network '../../virtual-network/main.bicep' = {
  name: 'azure_vnet'
  params: {
    resourceName: resourceName
    addressPrefixes: [
      '192.168.0.0/24'
    ]
    subnets: [
      {
        name: 'default'
        addressPrefix: '192.168.0.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

//  Module --> Create a PrivateEndpoint and privateEndpoints/privateDnsZoneGroups
module privateEndpoint '../main.bicep' = {
  name: 'private_endpoint'
  params: {
    resourceName: resourceName
    subnetResourceId: network.outputs.subnetIds[0]
    serviceResourceId: storage.outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [privateDNSZone.id]
    }
  }
}
