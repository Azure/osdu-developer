targetScope = 'resourceGroup'

@description('Used to name all resources')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Tags.')
param tags object = {}

@allowed([
  'CanNotDelete'
  'NotSpecified'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = 'NotSpecified'

@description('Specifies the storage account sku type.')
@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'Standard_GRS'
])
param sku string = 'Standard_LRS'

@description('Specifies the storage account access tier.')
@allowed([
  'Cool'
  'Hot'
])
param accessTier string = 'Hot'


@description('Optional. Array of Storage Containers to be created.')
param containers array = [
  /* example
  'one'
  'two'
  */
]

@description('Optional. Array of Storage Tables to be created.')
param tables array = [
  /* example
  'one'
  'two'
  */
]

@description('Optional. Array of Storage Shares to be created.')
param shares array = [
  /* example
  'one'
  'two'
  */
]

@description('Optional. The maximum size of the share, in gigabytes. Must be greater than 0, and less than or equal to 5120 (5TB). For Large File Shares, the maximum size is 102400 (100TB).')
param shareQuota int = 5120

@allowed([
  'NFS'
  'SMB'
])
@description('Optional. The authentication protocol that is used for the file share. Can only be specified when creating a share.')
param enabledProtocols string = 'SMB'

@allowed([
  'AllSquash'
  'NoRootSquash'
  'RootSquash'
])
@description('Optional. Permissions for NFS file shares are enforced by the client OS rather than the Azure Files service. Toggling the root squash behavior reduces the rights of the root user for NFS shares.')
param rootSquash string = 'NoRootSquash'

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
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
])
param logsToEnable array = [
  'StorageRead'
  'StorageWrite'
  'StorageDelete'
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

@description('Amount of days the soft deleted data is stored and available for recovery. 0 is off.')
@minValue(0)
@maxValue(365)
param deleteRetention int = 0

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



// Create Storage Account
resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: length(name) > 24 ? substring(name, 0, 24) : name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'

  identity: enableCMEK ? {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${cmekConfiguration.identityId}': {}
    }
  } : null

  properties: {
    accessTier: accessTier
    minimumTlsVersion: 'TLS1_2'

    encryption: enableCMEK ? {
      identity: {
        userAssignedIdentity: cmekConfiguration.identityId
      }
      services: {
         blob: {
           enabled: true
         }
         table: {
            enabled: true
         }
         file: {
            enabled: true
         }
      }
      keySource: 'Microsoft.Keyvault'
      keyvaultproperties: {
        keyname: cmekConfiguration.keyName
        keyvaulturi: cmekConfiguration.kvUrl
      }
    } : {
      services: {
         blob: {
           enabled: true
         }
         table: {
            enabled: true
         }
         file: {
            enabled: true
         }
      }
      keySource: 'Microsoft.Storage'
    }

    networkAcls: enablePrivateLink ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    } : {}
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storage
  name: 'default'
  properties: deleteRetention > 0 ? {
    changeFeed: {
      enabled: true
    }
    restorePolicy: {
      enabled: true
      days: 6
    }
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: deleteRetention
    }
  } : {
    deleteRetentionPolicy: {
      enabled: false
      allowPermanentDelete: false
    }
  }
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2022-05-01' = {
  name: 'default'
  parent: storage
  properties: {}
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  name: 'default'
  parent: storage
  properties: {
    protocolSettings: {}
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource storage_containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = [for item in containers: {
  parent: blobServices
  name: item
  properties: {
    defaultEncryptionScope:      '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess:                'None'
  }
}]

resource storage_tables 'Microsoft.Storage/storageAccounts/tableServices/tables@2022-05-01' = [for item in tables: {
  parent: tableServices
  name: item
}]

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-05-01' = [for item in shares: {
  parent: fileServices
  name: item
  properties: {
    shareQuota: shareQuota
    rootSquash: enabledProtocols == 'NFS' ? rootSquash : null
    enabledProtocols: enabledProtocols
  }
}]

// Apply Resource Lock
resource resource_lock 'Microsoft.Authorization/locks@2017-04-01' = if (lock != 'NotSpecified') {
  name: '${storage.name}-${lock}-lock'
  properties: {
    level: lock
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: storage
}

module storage_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principals: roleAssignment.principals
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    resourceId: storage.id
    crossTenant: crossTenant
  }
}]



// Hook up Diagnostics
resource storage_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'storage-diagnostics'
  scope: blobServices
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  dependsOn: [
    storage
  ]
}

@description('The resource ID.')
output id string = storage.id

@description('The name of the resource.')
output name string = storage.name

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

var publicDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
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
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
    subnet: {
      id: privateLinkSettings.subnetId
    }
  }
  dependsOn: [
    storage
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

////////////////
// Secrets
////////////////

@description('Optional: Key Vault Name to store secrets into')
param keyVaultName string = ''

@description('Optional: To save storage account name into vault set the secret name.')
param storageAccountSecretName string = ''

@description('Optional: To save storage account key into vault set the secret name.')
param storageAccountKeySecretName string = ''

@description('Optional: To save storage account connectionstring into vault set the secret name.')
param storageAccountConnectionString string = ''

@description('Optional: Current Date Time')
param basetime string = utcNow('u')

@description('Optional: Default SAS TOken Properties to download Blob.')
param sasProperties object = {
  signedServices: 'b'
  signedPermission: 'rl'
  signedExpiry: dateTimeAdd(basetime, 'P1Y')
  signedResourceTypes: 'sco'
  signedProtocol: 'https'
}

@description('Optional: To save storage account sas token into vault set the properties.')
param saveToken bool = false

module secretStorageAccountName  '.bicep/keyvault_secrets.bicep' = if (!empty(keyVaultName) && !empty(storageAccountSecretName)) {
  name: '${deployment().name}-secret-name'
  params: {
    keyVaultName: keyVaultName
    name: storageAccountSecretName
    value: storage.name
  }
}

module secretStorageAccountKey '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(storageAccountKeySecretName)) {
  name: '${deployment().name}-secret-key'
  params: {
    keyVaultName: keyVaultName
    name: storageAccountKeySecretName
    value: storage.listKeys().keys[0].value
  }
}

module secretStorageAccountConnection '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(storageAccountConnectionString)) {
  name: '${deployment().name}-secret-connectionstring'
  params: {
    keyVaultName: keyVaultName
    name: storageAccountConnectionString
    value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

module secretSASToken  '.bicep/keyvault_secrets.bicep' = if (!empty(keyVaultName) && saveToken) {
  name: '${deployment().name}-secret-sasToken'
  params: {
    keyVaultName: keyVaultName
    name: '${storage.name}-SAS'
    value: listAccountSAS(storage.name, '2022-05-01', sasProperties).accountSasToken
  }
}
