/////////////////
// Common Blade 
/////////////////

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}


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

@description('Feature Flag to Enable Private Link')
param enablePrivateLink bool

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('The Diagnostics Workspace Name')
param workspaceName string

@description('The managed identity name for deployment scripts')
param deploymentScriptIdentity string

@description('The subnet id for Private Endpoints')
param subnetId string

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
    ]
    tables: [
      'partitionInfo'
    ]
    shares: [
      'crs'
      'crs-conversion'
      'unit'
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

module insights 'br/public:avm/res/insights/component:0.3.0' = {
  name: '${bladeConfig.sectionName}-insights'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    enableTelemetry: enableTelemetry
    kind: commonLayerConfig.insights.sku
    workspaceResourceId: workspaceResourceId
    
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: workspaceResourceId
      }
    ]
  }
}

/*
 __  ___  ___________    ____ ____    ____  ___      __    __   __      .___________.
|  |/  / |   ____\   \  /   / \   \  /   / /   \    |  |  |  | |  |     |           |
|  '  /  |  |__   \   \/   /   \   \/   / /  ^  \   |  |  |  | |  |     `---|  |----`
|    <   |   __|   \_    _/     \      / /  /_\  \  |  |  |  | |  |         |  |     
|  .  \  |  |____    |  |        \    / /  _____  \ |  `--'  | |  `----.    |  |     
|__|\__\ |_______|   |__|         \__/ /__/     \__\ \______/  |_______|    |__|                                                                     
*/

var name = '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'

@description('The list of secrets to persist to the Key Vault')
var vaultSecrets = [ 
  {
    secretName: 'tenant-id'
    secretValue: subscription().tenantId
  }
  {
    secretName: 'app-dev-sp-tenant-id'
    secretValue: subscription().tenantId
  }
  {
    secretName: 'subscription-id'
    secretValue: subscription().subscriptionId
  }
  // Azure AD Secrets
  {
    secretName: 'app-dev-sp-password'
    secretValue: applicationClientSecret == '' ? 'dummy' : applicationClientSecret
  }
  {
    secretName: 'app-dev-sp-id'
    secretValue: applicationClientId
  }
  {
    secretName: 'cpng-user-name'
    secretValue: 'dbuser'
  }
  {
    secretName: 'cpng-user-password'
    secretValue: substring(uniqueString('dbuser', resourceGroup().id, bladeConfig.sectionName), 0, 8)
  }
  {
    secretName: 'cpng-superuser-name'
    secretValue: 'dbadmin'
  }
  {
    secretName: 'cpng-superuser-password'
    secretValue: substring(uniqueString('dbadmin', resourceGroup().id, bladeConfig.sectionName), 0, 8)
  }
  {
    secretName: 'airflow-db-connection'
    secretValue: 'postgresql://dbuser:${substring(uniqueString('dbuser', resourceGroup().id, bladeConfig.sectionName), 0, 8)}@airflow-cluster-rw.postgresql.svc.cluster.local:5432/airflow-db'
  }
  {
    secretName: 'airflow-admin-username'
    secretValue: 'airflow'
  }
  {
    secretName: 'airflow-admin-password'
    secretValue: substring(uniqueString('airflow', resourceGroup().id, bladeConfig.sectionName), 0, 8)
  }
  {
    secretName: 'airflow-fernet-key'
    secretValue: substring(uniqueString('airflow-fernet', resourceGroup().id, bladeConfig.sectionName), 0, 8)
  }
  {
    secretName: 'airflow-webserver-key'
    secretValue: substring(uniqueString('airflow-webserver', resourceGroup().id, bladeConfig.sectionName), 0, 8)
  }
]

var roleAssignment = {
  roleDefinitionIdOrName: 'Key Vault Secrets User'
  principalId: applicationClientPrincipalOid
  principalType: 'ServicePrincipal'
}

module keyvault 'br/public:avm/res/key-vault/vault:0.5.1' = {
  name: '${bladeConfig.sectionName}-keyvault'
  params: {
    name: length(name) > 24 ? substring(name, 0, 24) : name
    location: location
    enableTelemetry: enableTelemetry
    
    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    enablePurgeProtection: false
    
    // Configure RBAC
    enableRbacAuthorization: true
    roleAssignments: union(
      applicationClientPrincipalOid != '' ? array(roleAssignment) : [],
      []
    )

    // Configure Secrets
    secrets: {
      secureList: [for secret in vaultSecrets: {
        name: secret.secretName
        value: secret.secretValue
      }]
    }
  }
}

module keyvaultSecrets './keyvault_secrets.bicep' = {
  name: '${bladeConfig.sectionName}-diag-secrets'
  params: {
    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    workspaceName: workspaceName
    insightsName: insights.outputs.name
    cacheName: redis.outputs.name
  }
}

// Deployment Scripts are not enabled yet for Private Link
// https://github.com/Azure/bicep/issues/6540
module sshKey './script-sshkeypair/main.bicep' = {
  name: '${bladeConfig.sectionName}-keyvault-sshkey'
  params: {
    kvName: keyvault.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    sshKeyName: 'PrivateLinkSSHKey-'
  }
}

module certificates './script-kv-certificate/main.bicep' = {
  name: '${bladeConfig.sectionName}-keyvault-cert'
  params: {
    kvName: keyvault.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName: resourceGroup().name

    certificateNames: [
      'https-certificate'
    ]
    initialScriptDelay: '0'
    validity: 24
  }
}

resource vaultDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  properties: {}
}

module vaultEndpoint './private-endpoint/main.bicep' = if (enablePrivateLink) {
  name: '${bladeConfig.sectionName}-keyvault-pep'
  params: {
    resourceName: keyvault.outputs.name
    subnetResourceId: subnetId

    groupIds: [ 'vault']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [vaultDNSZone.id]
    }
    serviceResourceId: keyvault.outputs.resourceId
  }
  dependsOn: [
    vaultDNSZone
  ]
}

/*   _______.___________.  ______   .______          ___       _______  _______ 
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__   
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|  
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____ 
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|                                                                 
*/



var storageDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var storageDnsZoneName = 'privatelink.${storageDNSZoneForwarder}'

module configStorage './storage-account/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    // Hook up Diagnostics
    diagnosticWorkspaceId: workspaceResourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sku: commonLayerConfig.storage.sku
    tables: commonLayerConfig.storage.tables
    shares: commonLayerConfig.storage.shares
    containers: commonLayerConfig.storage.containers

    // Apply Security
    allowBlobPublicAccess: enableBlobPublicAccess

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: 'tbl-storage'
    storageAccountKeySecretName: 'tbl-storage-key'
    storageAccountTableEndpointSecretName: 'tbl-storage-endpoint'

    // Use as System Storage Account
    isSystem: true
  }
}

resource storageDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: storageDnsZoneName
  location: 'global'
  properties: {}
}

module storageEndpoint './private-endpoint/main.bicep' = if (enablePrivateLink) {
  name: '${bladeConfig.sectionName}-storage-endpoint'
  params: {
    resourceName: configStorage.outputs.name
    subnetResourceId: subnetId
    serviceResourceId: configStorage.outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZone.id]
    }
  }
  dependsOn: [
    storageDNSZone
  ]
}

module unitShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-share-upload-unit'
  params: {
    storageAccountName: configStorage.outputs.name
    location: location
    shareName: 'unit'
    filename: 'unit_catalog_v2.json'
    fileurl: 'https://community.opengroup.org/osdu/platform/system/reference/unit-service/-/raw/master/data/unit_catalog_v2.json'
    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name
  }
}

module catalogShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-share-upload-catalog'
  params: {
    storageAccountName: configStorage.outputs.name
    location: location
    shareName: 'crs'
    filename: 'crs_catalog_v2.json'
    fileurl: 'https://community.opengroup.org/osdu/platform/system/reference/crs-catalog-service/-/raw/master/data/crs_catalog_v2.json'
    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name
  }
}

module conversionShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-share-upload-conversion'
  params: {
    storageAccountName: configStorage.outputs.name
    location: location
    shareName: 'crs-conversion'
    filename: 'apachesis_setup'
    fileurl: 'https://community.opengroup.org/osdu/platform/system/reference/crs-conversion-service/-/archive/master/crs-conversion-service-master.tar.gz'
    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name
  }
}

module manifestDagShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-dag-upload-manifest'
  params: {
    storageAccountName: configStorage.outputs.name
    location: location
    shareName: 'airflow-dags'
    filename: 'osdu-ingest-r3.py'
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/raw/master/src/osdu_dags/osdu-ingest-r3.py'
    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name
  }
}

module manifestRefDagShareUpload './script-share-upload/main.bicep' = {
  name: '${bladeConfig.sectionName}-storage-dag-upload-manifest-by-ref'
  params: {
    storageAccountName: configStorage.outputs.name
    location: location
    shareName: 'airflow-dags'
    filename: 'osdu-ingest-r3-by-reference.py'
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/raw/master/src/osdu_dags/osdu-ingest-r3-by-reference.py'
    useExistingManagedIdentity: true
    managedIdentityName: deploymentScriptIdentity
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name
  }
}

/*
  _______ .______          ___      .______    __    __  
 /  _____||   _  \        /   \     |   _  \  |  |  |  | 
|  |  __  |  |_)  |      /  ^  \    |  |_)  | |  |__|  | 
|  | |_ | |      /      /  /_\  \   |   ___/  |   __   | 
|  |__| | |  |\  \----./  _____  \  |  |      |  |  |  | 
 \______| | _| `._____/__/     \__\ | _|      |__|  |__| 
*/

var cosmosDnsZoneName = 'privatelink.documents.azure.com'

module database './cosmos-db/main.bicep' = {
  name: '${bladeConfig.sectionName}-cosmos-db'
  params: {
    resourceName: bladeConfig.sectionName
    resourceLocation: location

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    // Hook up Diagnostics
    diagnosticWorkspaceId: workspaceResourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    capabilitiesToAdd: [
      'EnableGremlin'
    ]
    gremlinDatabases: [
      {
        name: commonLayerConfig.database.name
        graphs: commonLayerConfig.database.graphs
      }
    ]
    throughput: commonLayerConfig.database.throughput
    backupPolicyType: commonLayerConfig.database.backup

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${cmekConfiguration.identityId}': {}
    } : {}
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: 'graph-db-endpoint'
    databasePrimaryKeySecretName: 'graph-db-primary-key'
    databaseConnectionStringSecretName: 'graph-db-connection'
    

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principals: [
          {
            id: applicationClientPrincipalOid
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

resource cosmosDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: cosmosDnsZoneName
  location: 'global'
  properties: {}
}

module graphEndpoint './private-endpoint/main.bicep' = if (enablePrivateLink) {
  name: '${bladeConfig.sectionName}-cosmos-db-endpoint'
  params: {
    resourceName: database.outputs.name
    subnetResourceId: subnetId
    serviceResourceId: database.outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZone.id]
    }
  }
  dependsOn: [
    cosmosDNSZone
  ]
}

/*
  ______     ___       ______  __    __   _______ 
 /      |   /   \     /      ||  |  |  | |   ____|
|  ,----'  /  ^  \   |  ,----'|  |__|  | |  |__   
|  |      /  /_\  \  |  |     |   __   | |   __|  
|  `----./  _____  \ |  `----.|  |  |  | |  |____ 
 \______/__/     \__\ \______||__|  |__| |_______|                             
*/

module redis 'br/public:avm/res/cache/redis:0.3.2' = {
  name: '${bladeConfig.sectionName}-cache'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    skuName: 'Basic' 
    capacity: 1
    replicasPerMaster: 1
    replicasPerPrimary: 1
    zoneRedundant: false
    enableNonSslPort: true
  }
}

output keyvaultName string = keyvault.outputs.name
output keyvaultUri string = keyvault.outputs.uri
output storageAccountName string = configStorage.outputs.name
output storageAccountResourceId string = configStorage.outputs.id
output storageDNSZoneId string = storageDNSZone.id
output cosmosDNSZoneId string = cosmosDNSZone.id
output instrumentationKey string = insights.outputs.instrumentationKey
