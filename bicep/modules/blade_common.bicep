/////////////////
// Common Blade 
/////////////////

@description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account. For security reasons, it is recommended to set it to false.')
param enableBlobPublicAccess bool

@description('Optional. The tags to apply to the resources')
param tags object = {}

@description('The location of resources to deploy')
param location string

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('The Application Insights Instrumentation Key')
param insightsKey string

@description('Conditional. The name of the parent user assigned identity. Required if the template is used in a standalone deployment.')
param identityName string

@description('The IP address of the NAT cluster.')
param natClusterIP string

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Specify the AD Application Client Secret.')
@secure()
param applicationClientSecret string

@description('Specify the AD Application Principal Id.')
param applicationClientPrincipalOid string = ''


var commonLayerConfig = {
  insights: {
    sku: 'web'
  }
  storage: {
    sku: 'Standard_LRS'
    containers: [
      'system'
      'azure-webjobs-hosts'
      'azure-webjobs-eventhub'
      'gitops'
    ]
    tables: [
      'partitionInfo'
    ]
    shares: [
      'airflow-logs'
      'airflow-dags'
    ]
  }
  database: {
    name: 'osdu-graph'
    throughput: 2000
    backup: 'Continuous'
    graphs: [
      {
        name: 'Entitlements'
        automaticIndexing: true
        partitionKeyPaths: [
          '/dataPartitionId'
        ]
      }
    ]
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

/*
 __  ___  ___________    ____ ____    ____  ___      __    __   __      .___________.
|  |/  / |   ____\   \  /   / \   \  /   / /   \    |  |  |  | |  |     |           |
|  '  /  |  |__   \   \/   /   \   \/   / /  ^  \   |  |  |  | |  |     `---|  |----`
|    <   |   __|   \_    _/     \      / /  /_\  \  |  |  |  | |  |         |  |     
|  .  \  |  |____    |  |        \    / /  _____  \ |  `--'  | |  `----.    |  |     
|__|\__\ |_______|   |__|         \__/ /__/     \__\ \______/  |_______|    |__|                                                                     
*/

// var name = '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'

// @description('The list of secrets to persist to the Key Vault')
// var vaultSecrets = [ 
//   {
//     secretName: 'tenant-id'
//     secretValue: subscription().tenantId
//   }
//   {
//     secretName: 'app-dev-sp-tenant-id'
//     secretValue: subscription().tenantId
//   }
//   {
//     secretName: 'subscription-id'
//     secretValue: subscription().subscriptionId
//   }
//   // Azure AD Secrets
//   {
//     secretName: 'app-dev-sp-password'
//     secretValue: applicationClientSecret == '' ? 'dummy' : applicationClientSecret
//   }
//   {
//     secretName: 'app-dev-sp-id'
//     secretValue: applicationClientId
//   }
//   {
//     secretName: 'cpng-user-name'
//     secretValue: 'dbuser'
//   }
//   {
//     secretName: 'cpng-user-password'
//     secretValue: substring(uniqueString('dbuser', resourceGroup().id, bladeConfig.sectionName), 0, 8)
//   }
//   {
//     secretName: 'cpng-superuser-name'
//     secretValue: 'dbadmin'
//   }
//   {
//     secretName: 'cpng-superuser-password'
//     secretValue: substring(uniqueString('dbadmin', resourceGroup().id, bladeConfig.sectionName), 0, 8)
//   }
//   {
//     secretName: 'airflow-db-connection'
//     secretValue: 'postgresql://dbuser:${substring(uniqueString('dbuser', resourceGroup().id, bladeConfig.sectionName), 0, 8)}@airflow-cluster-rw.postgresql.svc.cluster.local:5432/airflow-db'
//   }
//   {
//     secretName: 'airflow-admin-username'
//     secretValue: 'admin'
//   }
//   {
//     secretName: 'airflow-admin-password'
//     secretValue: substring(uniqueString('airflow', resourceGroup().id, bladeConfig.sectionName), 0, 8)
//   }
//   {
//     secretName: 'airflow-fernet-key'
//     secretValue: substring(uniqueString('airflow-fernet', resourceGroup().id, bladeConfig.sectionName), 0, 8)
//   }
//   {
//     secretName: 'airflow-webserver-key'
//     secretValue: substring(uniqueString('airflow-webserver', resourceGroup().id, bladeConfig.sectionName), 0, 8)
//   }
// ]

// module keyvault 'br/public:avm/res/key-vault/vault:0.5.1' = {
//   name: '${bladeConfig.sectionName}-keyvault'
//   params: {
//     name: length(name) > 24 ? substring(name, 0, 24) : name
//     location: location
//     enableTelemetry: enableTelemetry
    
//     // Assign Tags
//     tags: union(
//       tags,
//       {
//         layer: bladeConfig.displayName
//       }
//     )

//     diagnosticSettings: [
//       {
//         workspaceResourceId: workspaceResourceId
//       }
//     ]

//     enablePurgeProtection: false
    
//     // Configure RBAC
//     enableRbacAuthorization: true
//     roleAssignments: union(
//       applicationClientPrincipalOid != '' ? [
//         {
//           roleDefinitionIdOrName: 'Key Vault Secrets User'
//           principalId: applicationClientPrincipalOid
//           principalType: 'ServicePrincipal'
//         }
//       ] : [],
//       []
//     )

//     // Configure Network Access
//     publicNetworkAccess: 'Enabled'
//     networkAcls: {
//       bypass: 'AzureServices'
//       defaultAction: 'Deny'
//       ipRules: [
//         {
//           value: natClusterIP
//         }
//       ]
//     }

//     // Configure Secrets
//     secrets: {
//       secureList: [for secret in vaultSecrets: {
//         name: secret.secretName
//         value: secret.secretValue
//       }]
//     }
//   }
// }


/*   _______.___________.  ______   .______          ___       _______  _______ 
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__   
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|  
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____ 
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|                                                                 
*/
// AVM Module Customized due to required Secrets.
// module storage './storage-account/main.bicep' = {
//   name: '${bladeConfig.sectionName}-storage'
//   params: {
//     name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
//     location: location
//     skuName: commonLayerConfig.storage.sku

//     // Assign Tags
//     tags: union(
//       tags,
//       {
//         layer: bladeConfig.displayName
//       }
//     )
    
//     // Hook up Diagnostics
//     diagnosticSettings: [
//       {
//         workspaceResourceId: workspaceResourceId
//       }
//     ]

//      // Configure Service
//      blobServices: {
//       containers: map(commonLayerConfig.storage.containers, container => {
//         name: container
//       })
//     }
//     tableServices: {
//       tables: map(commonLayerConfig.storage.tables, table => {
//         name: table
//       })
//     }
//     fileServices: {
//       shares: map(commonLayerConfig.storage.shares, share => {
//         name: share
//       })
//     }

//     // Apply Security
//     allowBlobPublicAccess: enableBlobPublicAccess
    
//     publicNetworkAccess: 'Enabled'

//     // TODO: Deployment Scripts don't support this yet.
//     // allowSharedKeyAccess: true
//     // https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#debug-deployment-scripts
//     networkAcls: {
//       bypass: 'AzureServices'
//       defaultAction: 'Allow'     // <--- Allow all traffic.  Should be changed to Deny.
//       ipRules: [
//         {
//           value: natClusterIP
//         }
//       ]
//     }

//     // Persist Secrets to Vault
//     secretsExportConfiguration: {
//       keyVaultResourceId: keyvault.outputs.resourceId
//       accountName: [
//         'system-storage'
//         'tbl-storage'
//       ]
//       accessKey1: [
//         'system-storage-key'
//         'tbl-storage-key'
//       ]
//       connectionString1: [
//         'system-storage-connection'
//       ]     
//       blobEndpoint: [
//         'system-storage-blob-endpoint'
//       ]
//       tableEndpoint: [
//         'tbl-storage-endpoint'
//       ]
//     }
//   }
// }


/*
  _______ .______          ___      .______    __    __  
 /  _____||   _  \        /   \     |   _  \  |  |  |  | 
|  |  __  |  |_)  |      /  ^  \    |  |_)  | |  |__|  | 
|  | |_ | |      /      /  /_\  \   |   ___/  |   __   | 
|  |__| | |  |\  \----./  _____  \  |  |      |  |  |  | 
 \______| | _| `._____/__/     \__\ | _|      |__|  |__| 
*/
// AVM Module Customized due to required Secrets.
// module database './cosmos-db/main.bicep' = {
//   name: '${bladeConfig.sectionName}-cosmos-db'
//   params: {
//     resourceName: bladeConfig.sectionName
//     resourceLocation: location

//     // Assign Tags
//     tags: union(
//       tags,
//       {
//         layer: bladeConfig.displayName
//       }
//     )

//     // Hook up Diagnostics
//     diagnosticWorkspaceId: workspaceResourceId
//     diagnosticLogsRetentionInDays: 0

//     // Configure Service
//     capabilitiesToAdd: [
//       'EnableGremlin'
//     ]
//     gremlinDatabases: [
//       {
//         name: commonLayerConfig.database.name
//         graphs: commonLayerConfig.database.graphs
//       }
//     ]
//     throughput: commonLayerConfig.database.throughput
//     backupPolicyType: commonLayerConfig.database.backup

//     // Hookup Customer Managed Encryption Key
//     systemAssignedIdentity: false
//     userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
//       '${cmekConfiguration.identityId}': {}
//     } : {}
//     defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
//     kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

//     // Persist Secrets to Vault
//     keyVaultName: keyvault.outputs.name
//     databaseEndpointSecretName: 'graph-db-endpoint'
//     databasePrimaryKeySecretName: 'graph-db-primary-key'
//     databaseConnectionStringSecretName: 'graph-db-connection'
    

//     roleAssignments: [
//       {
//         roleDefinitionIdOrName: 'Contributor'
//         principals: [
//           {
//             id: applicationClientPrincipalOid
//           }
//         ]
//         principalType: 'ServicePrincipal'
//       }
//     ]
//   }
// }


/*
     _______.  ______ .______       __  .______   .___________.    _______.
    /       | /      ||   _  \     |  | |   _  \  |           |   /       |
   |   (----`|  ,----'|  |_)  |    |  | |  |_)  | `---|  |----`  |   (----`
    \   \    |  |     |      /     |  | |   ___/      |  |        \   \    
.----)   |   |  `----.|  |\  \----.|  | |  |          |  |    .----)   |   
|_______/     \______|| _| `._____||__| | _|          |__|    |_______/    
*/


var directoryUploads = [
  {
    directory: 'software'
  }
  {
    directory: 'charts'
  }
  {
    directory: 'stamp'
  }
]

@batchSize(1)
module gitOpsUpload './software-upload/main.bicep' = [for item in directoryUploads: {
  name: '${bladeConfig.sectionName}-storage-${item.directory}-upload'
  params: {
    newStorageAccount: true
    location: location
    storageAccountName: storage.outputs.name
    identityName: userAssignedIdentity.name

    directoryName: item.directory
  }
  dependsOn: [
    storage
  ]
}]

module manifestDagShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-dag-upload-manifest'
  params: {
    newStorageAccount: true
    location: location
    storageAccountName: storage.outputs.name
    identityName: userAssignedIdentity.name

    shareName: 'airflow-dags'
    filename: 'src/osdu_dags'
    compress: true
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/archive/master/ingestion-dags-master.tar.gz'
  }
  dependsOn: [
    storage
  ]
}

module csvDagShareUpload './script-share-csvdag/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-dag-upload-csv'
  params: {
    newStorageAccount: true
    location: location
    storageAccountName: storage.outputs.name
    identityName: userAssignedIdentity.name
    
    shareName: 'airflow-dags'
    filename: 'airflowdags'
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz'
    keyVaultUrl: keyvault.outputs.uri
    insightsKey: insightsKey
    clientId: applicationClientId
    clientSecret: applicationClientSecret
  }
  dependsOn: [
    storage
  ]
}


// =============== //
//   Outputs       //
// =============== //

output keyvaultName string = keyvault.outputs.name
output keyvaultUri string = keyvault.outputs.uri
output storageAccountName string = storage.outputs.name
output storageAccountResourceId string = storage.outputs.resourceId


// =============== //
//   Definitions   //
// =============== //

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}
