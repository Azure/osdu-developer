/////////////////
// Partition Blade 
/////////////////
// import * as type from 'types.bicep'

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('The tags to apply to the resources')
param tags object = {}

@description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account. For security reasons, it is recommended to set it to false.')
param enableBlobPublicAccess bool

@description('Feature Flag to Enable Private Link')
param enablePrivateLink bool

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('The subnet id for Private Endpoints')
param subnetId string

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

@description('The name of the Key Vault where the secret exists')
param kvName string 

@description('Storage DNS Zone Id')
param storageDNSZoneId string

@description('Cosmos DNS Zone Id')
param cosmosDNSZoneId string

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
])
@description('The Partition Size')
param partitionSize string = 'CostOptimised'

@description('List of Data Partitions')
param partitions array = [
  {
    name: 'opendes'
  }
]

/////////////////////////////////
// Configuration 
/////////////////////////////////
var partitionLayerConfig = {
  secrets: {
    storageAccountName: 'storage'
    storageAccountKey: 'key'
    cosmosConnectionString: 'cosmos-connection'
    cosmosEndpoint: 'cosmos-endpoint'
    cosmosPrimaryKey: 'cosmos-primary-key'
  }
  storage: {
    sku: 'Standard_LRS'
    containers: [
      'legal-service-azure-configuration'
      'osdu-wks-mappings'
      'wdms-osdu'
      'file-staging-area'
      'file-persistent-area'
    ]
  }
  database: {
    name: 'osdu-db'
    CostOptimised : {
      throughput: 2000
    }
    Standard: {
      throughput: 4000
    }
    HighSpec: {
      throughput: 12000
    }
    backup: 'Continuous'
    containers: [
      {
        name: 'LegalTag'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageRecord'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageSchema'
        kind: 'Hash'
        paths: [
          '/kind'
        ]
      }
      {
        name: 'TenantInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'UserInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'Authority'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'EntityType'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'SchemaInfo'
        kind: 'Hash'
        paths: [
          '/partitionId'
        ]
      }
      {
        name: 'Source'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'RegisterAction'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterDdms'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterSubscription'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'IngestionStrategy'
        kind: 'Hash'
        paths: [
          '/workflowType'
        ]
      }
      {
        name: 'RelationshipStatus'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'MappingInfo'
        kind: 'Hash'
        paths: [
          '/sourceSchemaKind'
        ]
      }
      {
        name: 'FileLocationInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'WorkflowCustomOperatorInfo'
        kind: 'Hash'
        paths: [
          '/operatorId'
        ]
      }
      {
        name: 'WorkflowV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowRunV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowCustomOperatorV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowTasksSharingInfoV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'Status'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
      {
        name: 'DataSetDetails'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
    ]
  }
  servicebus: {
    sku: 'Standard'
    topics: [
      {
        name: 'indexing-progress'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'indexing-progresssubscription'
          }
        ]
      }
      {
        name: 'legaltags'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'legaltagssubscription'
          }
        ]
      }
      {
        name: 'recordstopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'recordstopicsubscription'
          }
        ]
      }
      {
        name: 'recordstopicdownstream'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'downstreamsub'
          }
        ]
      }
      {
        name: 'recordstopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_wkssubscription'
          }
        ]
      }
      {
        name: 'schemachangedtopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'schemachangedtopicsubscription'
          }
        ]
      }
      {
        name: 'schemachangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_schemasubscription'
          }
        ]
      }
      {
        name: 'legaltagschangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_legaltagssubscription'
          }
        ]
      }
      {
        name: 'statuschangedtopic'
        maxSizeInMegabytes: 5120
        subscriptions: [
          {
            name: 'eg_sb_statussubscription'
          }
        ]
      }
      {
        name: 'statuschangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: []
      }
      {
        name: 'replayrecordtopic'
        maxSizeInMegabytes: 1024
        subscriptions: []
      }
    ]
  }
}



/*
.______      ___      .______     .___________. __  .___________. __    ______   .__   __.      _______.
|   _  \    /   \     |   _  \    |           ||  | |           ||  |  /  __  \  |  \ |  |     /       |
|  |_)  |  /  ^  \    |  |_)  |   `---|  |----`|  | `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
|   ___/  /  /_\  \   |      /        |  |     |  |     |  |     |  | |  |  |  | |  . `  |     \   \    
|  |     /  _____  \  |  |\  \----.   |  |     |  |     |  |     |  | |  `--'  | |  |\   | .----)   |   
| _|    /__/     \__\ | _| `._____|   |__|     |__|     |__|     |__|  \______/  |__| \__| |_______/                                 
*/

module partitionStorage './storage-account/main.bicep' = [for (partition, index) in partitions:  {
  name: '${bladeConfig.sectionName}-azure-storage-${index}'
  params: {
    #disable-next-line BCP335 BCP332
    name: '${replace('data${index}${substring(uniqueString(partition.name), 0, 6)}', '-', '')}${uniqueString(resourceGroup().id, 'data${index}${substring(uniqueString(partition.name), 0, 6)}')}'
    location: location

    // Assign Tags

    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
        partition: partition.name
        purpose: 'data'
      }
    )

    // Hook up Diagnostics
    diagnosticWorkspaceId: workspaceResourceId
    diagnosticLogsRetentionInDays: 0

    // Apply Security
    allowBlobPublicAccess: enableBlobPublicAccess

    // Configure Service
    sku: partitionLayerConfig.storage.sku
    containers: concat(partitionLayerConfig.storage.containers, [partition.name])

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: kvName
    storageAccountSecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountName}'
    storageAccountKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountKey}'
  }
}]

module partitionStorageEndpoint './private-endpoint/main.bicep' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${bladeConfig.sectionName}-azure-storage-endpoint-${index}'
  params: {
    resourceName: partitionStorage[index].outputs.name
    subnetResourceId: subnetId
    serviceResourceId: partitionStorage[index].outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZoneId]
    }
  }
}]

module partitionDb './cosmos-db/main.bicep' = [for (partition, index) in partitions: { 
  name: '${bladeConfig.sectionName}-cosmos-db-${index}'
  params: {
    #disable-next-line BCP335
    resourceName: 'data${index}${substring(uniqueString(partition.name), 0, 6)}'
    resourceLocation: location

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
        partition: partition.name
        purpose: 'data'
      }
    )

    // Hook up Diagnostics
    diagnosticWorkspaceId: workspaceResourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sqlDatabases: [
      {
        name: partitionLayerConfig.database.name
        containers: partitionLayerConfig.database.containers
      }
    ]
    maxThroughput: partitionLayerConfig.database[partitionSize].throughput
    backupPolicyType: partitionLayerConfig.database.backup

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${cmekConfiguration.identityId}': {}
    } : {}
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: kvName
    databaseEndpointSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosEndpoint}'
    databasePrimaryKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosPrimaryKey}'
    databaseConnectionStringSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosConnectionString}'
  }
}]

module partitionDbEndpoint './private-endpoint/main.bicep' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${bladeConfig.sectionName}-cosmos-db-endpoint-${index}'
  params: {
    resourceName: partitionDb[index].outputs.name
    subnetResourceId: subnetId
    serviceResourceId: partitionDb[index].outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZoneId]
    }
  }
}]


module partitonNamespace 'br/public:avm/res/service-bus/namespace:0.4.2' = [for (partition, index) in partitions:  {
  name: '${bladeConfig.sectionName}-service-bus-${index}'
  params: {
    name: '${replace('data${index}${substring(uniqueString(partition.name), 0, 6)}', '-', '')}${uniqueString(resourceGroup().id, 'data${index}${substring(uniqueString(partition.name), 0, 6)}')}'
    location: location

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
        partition: partition.name
        purpose: 'data'
      }
    )

    // Hook up Diagnostics
    diagnosticSettings: [
      {
        workspaceResourceId: workspaceResourceId
      }
    ]

    skuObject: {
      name: partitionLayerConfig.servicebus.sku
    }

    authorizationRules: [
      {
        name: 'RootManageSharedAccessKey'
        rights: [
          'Listen'
          'Manage'
          'Send'
        ]
      }
    ]

    topics: [
      for topic in partitionLayerConfig.servicebus.topics: {
        name: topic.name
        maxSizeInMegabytes: topic.maxSizeInMegabytes
        authorizationRules: [
          {
            name: 'RootManageSharedAccessKey'
            rights: [
              'Listen'
              'Manage'
              'Send'
            ]
          }
        ]
        subscriptions: topic.subscriptions
      }
    ]
  }
}]

// Output partitionStorage names
output partitionStorageNames string[] = [for (partition, index) in partitions: partitionStorage[index].outputs.name]
output partitionServiceBusNames string[] = [for (partition, index) in partitions: partitonNamespace[index].outputs.name]
