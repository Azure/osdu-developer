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

@description('The KeyVault Secret Name for the Workspace Id')
param workspaceIdName string

@description('The KeyVault Secret Name for the Workspace Key')
param workspaceKeySecretName string

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
  storage: {
    sku: 'Standard_LRS'
    tables: [
      'partitionInfo'
    ]
    shares: [
      'crs'
      'crs-conversion'
      'unit'
      'sample-share'
    ]
  }
  database: {
    name: 'graph-db'
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

/*
 __  ___  ___________    ____ ____    ____  ___      __    __   __      .___________.
|  |/  / |   ____\   \  /   / \   \  /   / /   \    |  |  |  | |  |     |           |
|  '  /  |  |__   \   \/   /   \   \/   / /  ^  \   |  |  |  | |  |     `---|  |----`
|    <   |   __|   \_    _/     \      / /  /_\  \  |  |  |  | |  |         |  |     
|  .  \  |  |____    |  |        \    / /  _____  \ |  `--'  | |  `----.    |  |     
|__|\__\ |_______|   |__|         \__/ /__/     \__\ \______/  |_______|    |__|                                                                     
*/

var name = 'kv-${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'

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
    secretName: 'redis-hostname'
    secretValue: 'redis-master.redis-cluster.svc.cluster.local'
  }
  {
    secretName: 'redis-password'
    secretValue: ''
  }
]

var roleAssignment = {
  roleDefinitionIdOrName: 'Key Vault Secrets User'
  principalId: applicationClientPrincipalOid
  principalType: 'ServicePrincipal'
}

module keyvault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: '${bladeConfig.sectionName}-keyvault'
  params: {
    name: length(name) > 24 ? substring(name, 0, 24) : name
    location: location
    enableTelemetry: enableTelemetry
    
    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

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
    workspaceIdName: workspaceIdName
    workspaceKeySecretName: workspaceKeySecretName
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
    name: 'sa${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: workspaceResourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sku: commonLayerConfig.storage.sku
    tables: commonLayerConfig.storage.tables
    shares: commonLayerConfig.storage.shares

    // Apply Security
    allowBlobPublicAccess: enableBlobPublicAccess

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: 'tbl-storage'
    storageAccountKeySecretName: 'tbl-storage-key'
    storageAccountEndpointSecretName: 'tbl-storage-endpoint'
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
    tags: {
      layer: bladeConfig.displayName
    }

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

output keyvaultName string = keyvault.outputs.name
output keyvaultUri string = keyvault.outputs.uri
output storageAccountName string = configStorage.outputs.name
output storageDNSZoneId string = storageDNSZone.id
output cosmosDNSZoneId string = cosmosDNSZone.id
