/////////////////
// Partition Blade
/////////////////

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('The tags to apply to the resources')
param tags object = {}

@description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account. For security reasons, it is recommended to set it to false.')
param enableBlobPublicAccess bool

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

@description('The name of the Key Vault where the secret exists')
param kvName string

@description('List of Data Partitions')
param partitions array = [
  {
    name: 'opendes'
  }
]

@description('The managed identity name for deployment scripts')
param managedIdentityName string

@description('The NAT Cluster IP')
param natClusterIP string

/////////////////////////////////
// Configuration
/////////////////////////////////
var partitionLayerConfig = {
  secrets: {
    storageAccountName: 'storage'
    storageAccountKey: 'storage-key'
    storageAccountBlob: 'storage-account-blob-endpoint'
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
  systemdb: {
    name: 'osdu-system-db'
    containers: [
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
        name: 'WorkflowV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
    ]
  }
  database: {
    name: 'osdu-db'
    throughput: 4000
    backup: 'Continuous'
    containers: [
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
        name: 'FileLocationEntity'
        kind: 'Hash'
        paths: [
          '/id'
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
        name: 'LegalTag'
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
        name: 'RelationshipStatus'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'ReplayStatus'
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
        name: 'Workflow'
        kind: 'Hash'
        paths: [
          '/workflowId'
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
        name: 'WorkflowCustomOperatorV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowRun'
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
        name: 'WorkflowRunStatus'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
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
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'legaltags'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'legaltagssubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'recordstopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'recordstopicsubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
          {
            name: 'wkssubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'recordstopicdownstream'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'downstreamsub'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'recordstopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_wkssubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'schemachangedtopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'schemachangedtopicsubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'schemachangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_schemasubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'legaltagschangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_legaltagssubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'statuschangedtopic'
        maxSizeInMegabytes: 5120
        subscriptions: [
          {
            name: 'statuschangedtopicsubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'statuschangedtopiceg'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'eg_sb_statussubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'recordstopic-v2'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'recordstopic-v2-subscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }
      {
        name: 'reindextopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'reindextopicsubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
            enableDeadLetteringOnMessageExpiration: false
          }
        ]
      }
      {
        name: 'entitlements-changed'
        maxSizeInMegabytes: 1024
        subscriptions: []
      }
      {
        name: 'replaytopic'
        maxSizeInMegabytes: 1024
        subscriptions: [
          {
            name: 'replaytopicsubscription'
            maxDeliveryCount: 5
            lockDuration: 'PT5M'
          }
        ]
      }

    ]
  }
}


var systemDatabase = {
  name: partitionLayerConfig.systemdb.name
  containers: partitionLayerConfig.systemdb.containers
}

var partitionDatabase = {
  name: partitionLayerConfig.database.name
  containers: partitionLayerConfig.database.containers
}

/////////////////////////////////
// Existing Resources
/////////////////////////////////

resource stampIdentity  'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}


/*   _______.___________.  ______   .______          ___       _______  _______
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|
*/
// AVM Module Customized due to required Secrets.

module storage 'storage-account/main.bicep' = [for (partition, index) in partitions:  {
  name: '${bladeConfig.sectionName}-azure-storage-${index}'

  params: {
    name: '${replace('data${index}${substring(uniqueString(partition.name), 0, 6)}', '-', '')}${uniqueString(resourceGroup().id, 'data${index}${substring(uniqueString(partition.name), 0, 6)}')}'
    location: location
    skuName: partitionLayerConfig.storage.sku

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

     // Configure Service
     blobServices: {
      containers: map(concat(partitionLayerConfig.storage.containers, [partition.name]), container => {
        name: container
      })
    }

    // Apply Roles
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalId: stampIdentity.properties.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    enableHierarchicalNamespace: true

    // Apply Security
    allowBlobPublicAccess: enableBlobPublicAccess
    publicNetworkAccess: 'Enabled'
    allowSharedKeyAccess: false
    // https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#debug-deployment-scripts
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'     // <--- Allow all traffic.  Should be changed to Deny.
      ipRules: [
        {
          value: natClusterIP
        }
      ]
    }

    // Persist Secrets to Vault
    secretsExportConfiguration: {
      keyVaultResourceId: keyVault.id
      accountName: [
        '${partition.name}-${partitionLayerConfig.secrets.storageAccountName}'
      ]
      accessKey1: [
        '${partition.name}-${partitionLayerConfig.secrets.storageAccountKey}'
      ]
      blobEndpoint: [
        '${partition.name}-${partitionLayerConfig.secrets.storageAccountBlob}'
      ]
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

    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      networkAclBypass: 'AzureServices'
      ipRules: [
        '${natClusterIP}'
      ]
      virtualNetworkRules: []
    }

    // Set isSystemPartition based on index
    isSystemPartition: index == 0 ? true : false

    // Configure Databases
    sqlDatabases: index == 0 ? union(
      array(systemDatabase),
      array(partitionDatabase)
    ) : array(partitionDatabase)

    maxThroughput: partitionLayerConfig.database.throughput
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

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principals: [
          {
            id: stampIdentity.properties.principalId
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}]

// Add SQL role assignment for the Cosmos DB account
module sqlRoleAssignment './cosmosdb-sql-role-assignment.bicep' = [for (partition, index) in partitions: {
  name: '${bladeConfig.sectionName}-cosmos-db-sql-role-${index}'
  params: {
    databaseAccountName: partitionDb[index].outputs.name
    principalId: stampIdentity.properties.principalId
    roleDefinitionId: '${partitionDb[index].outputs.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002' // Built-in Cosmos DB Built-in Data Contributor
  }
  dependsOn: [
    partitionDb[index]
  ]
}]

// First, create a variable to handle the subscription mapping
var topicsWithSubscriptions = [for topic in partitionLayerConfig.servicebus.topics: {
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
  subscriptions: topic.subscriptions ?? []
}]

// Then use this variable in the module
module partitonNamespace 'br/public:avm/res/service-bus/namespace:0.14.1' = [for (partition, index) in partitions:  {
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
      capacity: partitionLayerConfig.servicebus.sku == 'Premium' ? 2 : null
    }

    zoneRedundant: partitionLayerConfig.servicebus.sku == 'Premium' ? true : false

    disableLocalAuth: false

    roleAssignments: [
      {
        name: guid('Custom seed ${bladeConfig.sectionName}-receiver')
        principalId: stampIdentity.properties.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Azure Service Bus Data Receiver'
      }
      {
        name: guid('Custom seed ${bladeConfig.sectionName}-sender')
        principalId: stampIdentity.properties.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Azure Service Bus Data Sender'
      }
    ]

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

    topics: topicsWithSubscriptions
  }
}]


// TODO: This should be moved to the Kubernetes Job.
module blobUpload 'br/public:avm/res/resources/deployment-script:0.4.0' = [for (partition, index) in partitions: {
  name: '${bladeConfig.sectionName}-storage-blob-upload-${index}'
  params: {
    name: 'script-${storage[index].outputs.name}-Legal_COO'
    location: location
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    runOnce: true

    managedIdentities: {
      userAssignedResourcesIds: [
        stampIdentity.id
      ]
    }

    kind: 'AzureCLI'
    azCliVersion: '2.63.0'

    environmentVariables: [
      { name: 'CONTENT', value: loadTextContent('./deploy-scripts/Legal_COO.json') }
      { name: 'FILE_NAME', value: 'Legal_COO.json' }
      { name: 'CONTAINER', value: 'legal-service-azure-configuration' }
      { name: 'AZURE_STORAGE_ACCOUNT', value: storage[index].outputs.name }
    ]
    scriptContent: loadTextContent('./deploy-scripts/blob_upload.sh')
  }
}]


// TODO: ACL can only be applied after the blob upload.
// module storageAcl './network_acl_storage.bicep' = [for (partition, index) in partitions: {
//   name: '${bladeConfig.sectionName}-storage-acl-${index}'
//   params: {
//     storageName: storage[index].outputs.name
//     location: location
//     skuName: partitionLayerConfig.storage.sku
//     natClusterIP: natClusterIP
//   }
//   dependsOn: [
//     blobUpload[index]
//   ]
// }]

module partitionSecrets './keyvault_secrets_partition.bicep' = [for (partition, index) in partitions: {
  name: '${bladeConfig.sectionName}-secrets-${index}'
  params: {
    keyVaultName: kvName
    partitionName: partition.name
    serviceBusName: partitonNamespace[index].outputs.name
  }
}]


// =============== //
//   Outputs       //
// =============== //

output partitionStorageNames string[] = [for (partition, index) in partitions: storage[index].outputs.name]
output partitionServiceBusNames string[] = [for (partition, index) in partitions: partitonNamespace[index].outputs.name]


// =============== //
//   Definitions   //
// =============== //

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}
