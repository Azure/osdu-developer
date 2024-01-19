targetScope = 'resourceGroup'


@description('Required. Name of the private endpoint resource to create.')
param resourceName string

@description('Required. Resource ID of the subnet where the endpoint needs to be created.')
param subnetResourceId string

@description('Required. Resource ID of the resource that needs to be connected to the network.')
param serviceResourceId string

@description('Required. Subtype(s) of the connection to be created. The allowed values depend on the type serviceResourceId refers to.')
param groupIds array

@description('Optional. Application security groups in which the private endpoint IP configuration is included.')
param applicationSecurityGroups array = []

@description('Optional. The custom name of the network interface attached to the private endpoint.')
param customNetworkInterfaceName string = ''

@description('Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.')
param ipConfigurations array = []


@description('Optional. The private DNS zone group configuration used to associate the private endpoint with one or multiple private DNS zones. A DNS zone group can support up to 5 DNS zones.')
param privateDnsZoneGroup object = {}

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Indicates if the module is used in a cross tenant scenario. If true, a resourceId must be provided in the role assignment\'s principal object.')
param crossTenant bool = false

@description('Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep')
param roleAssignments array = [
  /* example
      {
        roleDefinitionIdOrName: 'Reader'
        principals: [
          {
            id: '222222-2222-2222-2222-2222222222'
            resourceId: '/subscriptions/111111-1111-1111-1111-1111111111/resourcegroups/rg-osdu-bicep/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-ManagedIdentityName'
          }
        ]
        principalType: 'ServicePrincipal'
      }
  */
]

@description('Tags.')
param tags object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Optional. Custom DNS configurations.')
param customDnsConfigs array = []

@description('Optional. Manual PrivateLink Service Connections.')
param manualPrivateLinkServiceConnections array = []

var name = 'pep-${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

// TODO Should I change serviceResourceId(param) to accept an array of all the resources yo want to assign this privateEndpoint to?
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: length(name) > 24 ? substring(name, 0, 24) : name
  location: location
  tags: tags
  properties: {
    applicationSecurityGroups: applicationSecurityGroups
    customNetworkInterfaceName: customNetworkInterfaceName
    ipConfigurations: ipConfigurations
    manualPrivateLinkServiceConnections: manualPrivateLinkServiceConnections
    customDnsConfigs: customDnsConfigs
    privateLinkServiceConnections: [
      {
        name: resourceName
        properties: {
          privateLinkServiceId: serviceResourceId
          groupIds: groupIds
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

module privateEndpoint_privateDnsZoneGroup './.bicep/private_dns_zone_groups.bicep' = if (!empty(privateDnsZoneGroup)) {
  name: '${deployment().name}-${privateEndpoint.name}'

  params: {
    privateDNSResourceIds: privateDnsZoneGroup.privateDNSResourceIds
    privateEndpointName: privateEndpoint.name
  }
}

module privateEndpoint_roleAssignments './.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principals: roleAssignment.principals
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    condition: contains(roleAssignment, 'condition') ? roleAssignment.condition : ''
    resourceId: privateEndpoint.id
    crossTenant: crossTenant
  }
}]

// Apply Resource Lock
resource resource_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${privateEndpoint.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: privateEndpoint
}

@description('The resource group the private endpoint was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the private endpoint.')
output name string = privateEndpoint.name

@description('The resource ID of the private endpoint.')
output id string = privateEndpoint.id

@description('The location the resource was deployed into.')
output location string = privateEndpoint.location
