metadata name = 'App Configuration'
metadata description = 'This module deploys an App Configuration.'
metadata owner = 'Azure/azure-global-energy'

targetScope = 'resourceGroup'

@minLength(3)
@maxLength(48)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Tags.')
param tags object = {}

@allowed([
  'Free'
  'Standard'
])
@description('Optional. Pricing tier of App Configuration.')
param sku string = 'Standard'

@allowed([
  'Default'
  'Recover'
])
@description('Optional. Indicates whether the configuration store need to be recovered.')
param createMode string = 'Default'

@description('Optional. Disables all authentication methods other than AAD authentication.')
param disableLocalAuth bool = false

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. All Key / Values to create.')
param keyValues array = [
  /* example
    {
      key: 'myKey'
      value: 'myValue'
    }
  */
]

@description('Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep')
param roleAssignments array = [
  /* example
      {
        roleDefinitionIdOrName: 'Reader'
        principalIds: [
          '222222-2222-2222-2222-2222222222'
        ]
        principalType: 'ServicePrincipal'
      }
  */
]

@description('Optional. Resource ID of the diagnostic log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'HttpRequest'
  'Audit'
])
param logsToEnable array = [
  'HttpRequest'
  'Audit'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}


var name = '${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

var enableCMEK = !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) && !empty(cmekConfiguration.identityId) ? true : false


var diagnosticsLogs = [for log in logsToEnable: {
  category: log
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in metricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var identityType = systemAssignedIdentity ? 'SystemAssigned' : !empty(userAssignedIdentities) ? 'UserAssigned' : 'None'


resource configStore 'Microsoft.AppConfiguration/configurationStores@2023-08-01-preview' = {
  name: length(name) > 50 ? substring(name, 0, 50) : name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  identity: !empty(userAssignedIdentities) ? {
    type: identityType
    userAssignedIdentities: userAssignedIdentities
  } : {
    type: identityType
  }

  properties: {
    createMode: createMode
    disableLocalAuth: disableLocalAuth
    dataPlaneProxy: disableLocalAuth ? {
      authenticationMode: 'Pass-through'
      privateLinkDelegation: 'Disabled'
  } : null
    encryption: enableCMEK ? {
      keyVaultProperties: {
        identityClientId: cmekConfiguration.identityId
        keyIdentifier: '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}'
      }
    } : null
  }
}

module configurationStore_keyValues './.bicep/key_values.bicep' = [for (keyValue, index) in keyValues: {
  name: '${deployment().name}-keyvalues-${index}'
  params: {
    appConfigurationName: configStore.name
    name: keyValue.name
    value: keyValue.value
    label: contains(keyValue, 'label') ? keyValue.label : ''
    contentType: contains(keyValue, 'contentType') ? keyValue.contentType : ''
    tags: contains(keyValue, 'tags') ? keyValue.tags : {}
  }
}]

// Apply Resource Lock
resource resource_lock 'Microsoft.Authorization/locks@2020-05-01' = if (lock != 'NotSpecified') {
  name: '${configStore.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: configStore
}

// Hook up Diagnostics
resource configstore_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'appconfig-diagnostics'
  scope: configStore
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
}


module configStore_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: configStore.id
  }
}]

@description('The name of the azure app configuration service.')
output name string = configStore.name

@description('The resourceId of the azure app configuration service.')
output id string = configStore.id

@description('The endpoint of the azure app configuration service.')
output endpoint string = configStore.properties.endpoint

////////////////
// Private Link
////////////////

@description('Settings Required to Enable Private Link')
param privateLinkSettings object = {
  subnetId: '1' // Specify the Subnet for Private Endpoint
  vnetId: '1'  // Specify the Virtual Network for Virtual Network Link
}

var enablePrivateLink = privateLinkSettings.vnetId != '1' && privateLinkSettings.subnetId != '1'


@description('Specifies the name of the private link to the Resource.')
var privateEndpointName = '${name}-PrivateEndpoint'

var publicDNSZoneForwarder = 'azconfig.io'
var privateDnsZoneName = 'privatelink.${publicDNSZoneForwarder}'


resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = if (enablePrivateLink) {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: configStore.id
          groupIds: [
            'configurationStores'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSettings.subnetId
    }
  }
  dependsOn: [
    configStore
  ]
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = if (enablePrivateLink) {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateDNSZone
  ]
}

#disable-next-line BCP081
resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateLink) {
  parent: privateDNSZone
  name: 'link_to_vnet'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: privateLinkSettings.vnetId
    }
  }
  dependsOn: [
    privateDNSZone
  ]
}
