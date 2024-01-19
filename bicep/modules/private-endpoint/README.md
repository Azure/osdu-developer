# Private Endpoint Module

This module deploys an Azure Private Endpoint.

## Description

This module supports the following features.

- Private Link (Secure network)

## Parameters

| Name                                  | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :------------------------------------ | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                        | `string` | Yes      | Required. Name of the private endpoint resource to create.                                                                                                                                                                                                                    |
| `subnetResourceId`                    | `string` | Yes      | Required. Resource ID of the subnet where the endpoint needs to be created.                                                                                                                                                                                                   |
| `serviceResourceId`                   | `string` | Yes      | Required. Resource ID of the resource that needs to be connected to the network.                                                                                                                                                                                              |
| `groupIds`                            | `array`  | Yes      | Required. Subtype(s) of the connection to be created. The allowed values depend on the type serviceResourceId refers to.                                                                                                                                                      |
| `applicationSecurityGroups`           | `array`  | No       | Optional. Application security groups in which the private endpoint IP configuration is included.                                                                                                                                                                             |
| `customNetworkInterfaceName`          | `string` | No       | Optional. The custom name of the network interface attached to the private endpoint.                                                                                                                                                                                          |
| `ipConfigurations`                    | `array`  | No       | Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.                                                                                                                                                 |
| `privateDnsZoneGroup`                 | `object` | No       | Optional. The private DNS zone group configuration used to associate the private endpoint with one or multiple private DNS zones. A DNS zone group can support up to 5 DNS zones.                                                                                             |
| `location`                            | `string` | No       | Optional. Location for all Resources.                                                                                                                                                                                                                                         |
| `crossTenant`                         | `bool`   | No       | Optional. Indicates if the module is used in a cross tenant scenario. If true, a resourceId must be provided in the role assignment's principal object.                                                                                                                       |
| `roleAssignments`                     | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `tags`                                | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `lock`                                | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                           |
| `customDnsConfigs`                    | `array`  | No       | Optional. Custom DNS configurations.                                                                                                                                                                                                                                          |
| `manualPrivateLinkServiceConnections` | `array`  | No       | Optional. Manual PrivateLink Service Connections.                                                                                                                                                                                                                             |

## Outputs

| Name              | Type   | Description                                                |
| :---------------- | :----: | :--------------------------------------------------------- |
| resourceGroupName | string | The resource group the private endpoint was deployed into. |
| name              | string | The name of the private endpoint.                          |
| id                | string | The resource ID of the private endpoint.                   |
| location          | string | The location the resource was deployed into.               |

## Examples

### Example 1

```bicep
// Dependency: Storage
module storage 'br:osdubicep.azurecr.io/public/storage-account:1.0.4' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    sku: 'Standard_LRS'
  }
}

// Dependency: Network
module network 'br:osdubicep.azurecr.io/public/virtual-network:1.0.4' = {
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

// Dependency: Private DNS Zone
var publicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var privateDnsZoneName = 'privatelink.${publicDNSZoneForwarder}'

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

//  Module --> Create a Private DNS zone
module endpoint '.br:osdubicep.azurecr.io/bicep/modules/public/private-endpoint:1.0.2' = {
  name: 'privateDnsZoneModule'
  params: {

    resourceName: resourceName

    groupIds: [
      'blob' // Storage Specific
    ]

    privateDnsZoneGroup: {
      privateDNSResourceIds: [
        privateDNSZone.id
      ]
    }

    serviceResourceId: storage.outputs.id
    subnetResourceId: network.outputs.subnetIds[0]

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
```