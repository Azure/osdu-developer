targetScope = 'resourceGroup'

@minLength(3)
@maxLength(20)
@description('Used to name all resources')
param resourceName string

@description('Optional: Resource Location.')
param resourceLocation string = resourceGroup().location

@description('Tags.')
param tags object = {}

@description('Enable lock to prevent accidental deletion')
param enableDeleteLock bool = false

@description('Optional. Locations enabled for the Cosmos DB account.')
param multiwriteRegions array = [
  /* example
    {
      failoverPriority: 0
      isZoneRedundant: false
      locationName: 'South Central US'
    }
  */
]

@description('Optional. Represents maximum throughput, the resource can scale up to. Cannot be set together with `throughput`. If `throughput` is set to something else than -1, this autoscale setting is ignored.')
param maxThroughput int = 4000

@description('Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.')
param throughput int = -1

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. The default identity to be used.')
param defaultIdentity string = ''

@description('Optional. The offer type for the Cosmos DB database account.')
@allowed([
  'Standard'
])
param databaseAccountOfferType string = 'Standard'

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('Optional. The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@description('Optional. Enable automatic failover for regions.')
param automaticFailover bool = true

@minValue(10)
@maxValue(2147483647)
@description('Optional. Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Optional. Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@description('Optional. Specifies the MongoDB server version to use.')
@allowed([
  '3.2'
  '3.6'
  '4.0'
  '4.2'
])
param serverVersion string = '4.2'

@description('Optional. SQL Databases configurations.')
param sqlDatabases array = []

@description('Optional. Gremlin Databases configurations.')
param gremlinDatabases array = []

@description('Optional. MongoDB Databases configurations.')
param mongodbDatabases array = []

@allowed([
  'EnableCassandra'
  'EnableTable'
  'EnableGremlin'
  'EnableMongo'
  'DisableRateLimitingResponses'
  'EnableServerless'
])
@description('Optional. List of Cosmos DB capabilities for the account.')
param capabilitiesToAdd array = []

@allowed([
  'Periodic'
  'Continuous'
])
@description('Optional. Describes the mode of backups.')
param backupPolicyType string = 'Periodic'

@allowed([
  'Continuous30Days'
  'Continuous7Days'
])
@description('Optional. Configuration values for continuous mode backup.')
param backupPolicyContinuousTier string = 'Continuous30Days'

@minValue(60)
@maxValue(1440)
@description('Optional. An integer representing the interval in minutes between two backups. Only applies to periodic backup type.')
param backupIntervalInMinutes int = 240

@minValue(2)
@maxValue(720)
@description('Optional. An integer representing the time (in hours) that each backup is retained. Only applies to periodic backup type.')
param backupRetentionIntervalInHours int = 8

@allowed([
  'Geo'
  'Local'
  'Zone'
])
@description('Optional. Enum to indicate type of backup residency. Only applies to periodic backup type.')
param backupStorageRedundancy string = 'Local'


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
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
])
param logsToEnable array = [
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param metricsToEnable array = [
  'AllMetrics'
]

@description('Optional. Customer Managed Encryption Key.')
param kvKeyUri string = ''

@description('Optional. Indicates if the module is used in a cross tenant scenario. If true, a resourceId must be provided in the role assignment\'s principal object.')
param crossTenant bool = false

@description('Optional. The network configuration of this module. Defaults to `{ ipRules: [], virtualNetworkRules: [], publicNetworkAccess: \'Disabled\' }`.')
param networkRestrictions networkRestrictionsType = {
  ipRules: []
  virtualNetworkRules: []
  publicNetworkAccess: 'Disabled'
}

var ipRules = [
  for i in (networkRestrictions.?ipRules ?? []): {
    ipAddressOrRange: i
  }
]

var virtualNetworkRules = [
  for vnet in (networkRestrictions.?virtualNetworkRules ?? []): {
    id: vnet.subnetResourceId
    ignoreMissingVnetServiceEndpoint: false
  }
]

var name = '${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'


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

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

var databaseAccount_locations = [for location in multiwriteRegions: {
  failoverPriority: location.failoverPriority
  isZoneRedundant: location.isZoneRedundant
  locationName: location.locationName
}]

var kind = !empty(sqlDatabases) || !empty(gremlinDatabases) ? 'GlobalDocumentDB' : (!empty(mongodbDatabases) ? 'MongoDB' : 'Parse')

var capabilities = [for capability in capabilitiesToAdd: {
  name: capability
}]

var backupPolicy = backupPolicyType == 'Continuous' ? {
  type: backupPolicyType
  continuousModeProperties: {
    tier: backupPolicyContinuousTier
  }
} : {
  type: backupPolicyType
  periodicModeProperties: {
    backupIntervalInMinutes: backupIntervalInMinutes
    backupRetentionIntervalInHours: backupRetentionIntervalInHours
    backupStorageRedundancy: backupStorageRedundancy
  }
}

var databaseAccount_properties = union({
    databaseAccountOfferType: databaseAccountOfferType
  }, ((!empty(sqlDatabases) || !empty(mongodbDatabases) || !empty(gremlinDatabases)) ? {
    // Common properties
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    enableMultipleWriteLocations: empty(multiwriteRegions) ? false : true
    locations: empty(multiwriteRegions) ? [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: resourceLocation
      }
    ] : databaseAccount_locations


    ipRules: ipRules
    virtualNetworkRules: virtualNetworkRules
    networkAclBypass: networkRestrictions.?networkAclBypass ?? 'AzureServices'
    publicNetworkAccess: networkRestrictions.?publicNetworkAccess ?? 'Enabled'
    isVirtualNetworkFilterEnabled: !empty(ipRules) || !empty(virtualNetworkRules)

    capabilities: capabilities
    backupPolicy: backupPolicy
  } : {}), (!empty(sqlDatabases) ? {
    // SQLDB properties
    enableAutomaticFailover: automaticFailover
    AnalyticalStorageConfiguration: {
      schemaType: 'WellDefined'
    }
    defaultIdentity: !empty(defaultIdentity) ? 'UserAssignedIdentity=${defaultIdentity}': 'FirstPartyIdentity'
    enablePartitionKeyMonitor: true
    enablePartitionMerge: false
    keyVaultKeyUri:  !empty(kvKeyUri) ? kvKeyUri : null
  } : {}), (!empty(mongodbDatabases) ? {
    // MongoDb properties
    apiProperties: {
      serverVersion: serverVersion
    }
  } : {
    EnabledApiTypes: [
      'Sql'
    ]
  }))




// Create Database Account
resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' = {
  name: length(name) > 26 ? substring(name, 0, 26) : name
  location: resourceLocation
  tags: tags
  identity: {
    type: identityType
    userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : {}
  }
  kind: kind
  properties: databaseAccount_properties
}

module databaseAccount_sqlDatabases '.bicep/sql_database.bicep' = [for sqlDatabase in sqlDatabases: {
  name: '${deployment().name}-${sqlDatabase.name}'
  params: {
    databaseAccountName: databaseAccount.name
    name: sqlDatabase.name
    throughput: throughput
    maxThroughput: maxThroughput
    containers: sqlDatabase.?containers ?? []
  }
}]

module databaseAccount_gremlinDatabases './.bicep/gremlin_database.bicep' = [for gremlinDatabase in gremlinDatabases: {
  name: '${deployment().name}-${gremlinDatabase.name}'
  params: {
    databaseAccountName: databaseAccount.name
    name: gremlinDatabase.name
    throughput: throughput
    maxThroughput: maxThroughput
    graphs: gremlinDatabase.?graphs ?? []
  }
}]


// Resource Locking
resource lock 'Microsoft.Authorization/locks@2020-05-01' = if (enableDeleteLock) {
  scope: databaseAccount

  name: '${databaseAccount.name}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}

// Hook up Diagnostics
resource storage_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: 'storage-diagnostics'
  scope: databaseAccount
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
    logAnalyticsDestinationType: 'AzureDiagnostics'
  }
  dependsOn: [
    databaseAccount
  ]
}

// Role Assignments
module databaseaccount_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${deployment().name}-rbac-${index}'
  params: {
    description: roleAssignment.?description ?? ''
    principals: roleAssignment.principals
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    principalType: roleAssignment.?principalType ?? ''
    resourceId: databaseAccount.id
    crossTenant: crossTenant
  }
}]


@description('The name of the database account.')
output name string = databaseAccount.name

@description('The resource ID of the database account.')
output id string = databaseAccount.id

@description('The name of the resource group the database account was created in.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(databaseAccount.identity, 'principalId') ? databaseAccount.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = databaseAccount.location


////////////////
// Private Link
////////////////

@description('Settings Required to Enable Private Link')
param privateLinkSettings object = {
  subnetId: '1' // Specify the Subnet for Private Endpoint
  vnetId: '1'  // Specify the Virtual Network for Virtual Network Link
}

var enablePrivateLink = privateLinkSettings.vnetId != '1' && privateLinkSettings.subnetId != '1'

@description('Specifies the name of the private link to the Azure Container Registry.')
var privateEndpointName = '${name}-PrivateEndpoint'

var privateDNSZoneName = 'privatelink.documents.azure.com'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = if (enablePrivateLink) {
  name: privateEndpointName
  location: resourceLocation
  properties: {
    subnet: {
      id: privateLinkSettings.subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: databaseAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
    customDnsConfigs: [
      {
        fqdn: privateDNSZoneName
      }
    ]
  }
  dependsOn: [
    databaseAccount
  ]
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (enablePrivateLink) {
  parent: privateDNSZone
  name: '${privateDNSZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: privateLinkSettings.vnetId
    }
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (enablePrivateLink) {
  name: privateDNSZoneName
  location: 'global'
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-07-01' = if (enablePrivateLink) {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
}


////////////////
// Secrets
////////////////

@description('Optional: Key Vault Name to store secrets into')
param keyVaultName string = ''

@description('Optional: To save storage account name into vault set the secret hame.')
param databaseEndpointSecretName string = ''

@description('Optional: To save storage account key into vault set the secret hame.')
param databasePrimaryKeySecretName string = ''

@description('Optional: To save storage account connectionstring into vault set the secret hame.')
param databaseConnectionStringSecretName string = ''

@description('Optional: Enable as System Partition.')
param isSystemPartition bool = false

module systemSecretDatabaseEndpoint  '.bicep/keyvault_secrets.bicep' = if (isSystemPartition) {
  name: '${deployment().name}-system-secret-name'
  params: {
    keyVaultName: keyVaultName
    name: 'system-cosmos-endpoint'
    value: databaseAccount.properties.documentEndpoint
  }
}

module systemSecretDatabasePrimaryKey '.bicep/keyvault_secrets.bicep' =  if (isSystemPartition) {
  name: '${deployment().name}-system-secret-key'
  params: {
    keyVaultName: keyVaultName
    name: 'system-cosmos-primary-key'
    value: databaseAccount.listKeys().primaryMasterKey
  }
}

module systemSecretDatabaseConnectionString '.bicep/keyvault_secrets.bicep' =  if (isSystemPartition) {
  name: '${deployment().name}-system-secret-connection'
  params: {
    keyVaultName: keyVaultName
    name: 'system-cosmos-connection'
    value: databaseAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}

module secretDatabaseEndpoint  '.bicep/keyvault_secrets.bicep' = if (!empty(keyVaultName) && !empty(databaseEndpointSecretName)) {
  name: '${deployment().name}-secret-name'
  params: {
    keyVaultName: keyVaultName
    name: databaseEndpointSecretName
    value: databaseAccount.properties.documentEndpoint
  }
}

module secretDatabasePrimaryKey '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(databasePrimaryKeySecretName)) {
  name: '${deployment().name}-secret-key'
  params: {
    keyVaultName: keyVaultName
    name: databasePrimaryKeySecretName
    value: databaseAccount.listKeys().primaryMasterKey
  }
}

module secretDatabaseConnectionString '.bicep/keyvault_secrets.bicep' =  if (!empty(keyVaultName) && !empty(databaseConnectionStringSecretName)) {
  name: '${deployment().name}-secret-connection'
  params: {
    keyVaultName: keyVaultName
    name: databaseConnectionStringSecretName
    value: databaseAccount.listConnectionStrings().connectionStrings[0].connectionString
  }
}


type networkRestrictionsType = {
  @description('Required. A single IPv4 address or a single IPv4 address range in CIDR format. Provided IPs must be well-formatted and cannot be contained in one of the following ranges: 10.0.0.0/8, 100.64.0.0/10, 172.16.0.0/12, 192.168.0.0/16, since these are not enforceable by the IP address filter. Example of valid inputs: "23.40.210.245" or "23.40.210.0/8".')
  ipRules: string[]

  @description('Optional. Default to AzureServices. Specifies the network ACL bypass for Azure services.')
  networkAclBypass: ('AzureServices' | 'None')?

  @description('Optional. Default to Enabled. Whether requests from Public Network are allowed.')
  publicNetworkAccess: ('Enabled' | 'Disabled')?

  @description('Required. List of Virtual Network ACL rules configured for the Cosmos DB account..')
  virtualNetworkRules: {
    @description('Required. Resource ID of a subnet.')
    subnetResourceId: string
  }[]
}
