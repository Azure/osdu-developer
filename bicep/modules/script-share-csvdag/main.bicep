// This modules is a custom module tightly coupled to the csv-parser dag.

metadata name = 'Blob Upload'
metadata description = 'This module uploads a file to a blob storage account'
metadata owner = 'daniel-scholl'

@description('Name of the storage account')
param storageAccountName string

@description('Name of the Managed Identity resource')
param identityName string

@description('The location of the Storage Account and where to deploy the module resources to')
param location string = resourceGroup().location

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '30s'

@description('Azure RoleId that are required for the DeploymentScript resource to upload blobs')
param rbacRoleNeeded string = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb' // Storage File Data SMB Share Contributor

// Custom Parameters
@description('Whether to create a new storage account or use an existing one')
param newStorageAccount bool = true

@description('Name of the file share')
param shareName string = 'sample-share'

@description('Name of the file as it is stored in the share')
param filename string = 'sample.json'

@description('Name of the file as it is stored in the share')
param fileurl string = 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz'

@description('Keyvault url')
param keyVaultUrl string

@description('App Insights Instrumentation Key')
param insightsKey string

@description('Client Id for the service principal')
param clientId string

@secure()
@description('Client Secret for the service principal')
param clientSecret string

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: identityName
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(storageAccount.id, rbacRoleNeeded, identity.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

var findAndReplace = [ 
  {
    find: '{| DAG_NAME |}'
    replace: 'csv-parser'
  }
  {
    find: '{| DOCKER_IMAGE |}'
    replace: 'community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/csv-parser-v0-27-0-azure-1:60747714ac490be0defe8f3e821497b3cce03390'
  }
  {
    find: '{| NAMESPACE |}'
    replace: 'airflow'
  }
  {
    find: '{| K8S_POD_OPERATOR_KWARGS or {} |}'
    replace: {
      labels: {
        aadpodidbinding: 'osdu-identity'
      }
      annotations: {
        'sidecar.istio.io/inject': 'false'
      }
    }
  }
  {
    find: '{| ENV_VARS or {} |}'
    replace: {
      storage_service_endpoint: 'http://storage.osdu-core.svc.cluster.local/api/storage/v2'
      schema_service_endpoint: 'http://schema.osdu-core.svc.cluster.local/api/schema-service/v1'
      search_service_endpoint: 'http://search.osdu-core.svc.cluster.local/api/search/v2'
      partition_service_endpoint: 'http://partition.osdu-core.svc.cluster.local/api/partition/v1'
      unit_service_endpoint: 'http://unit.osdu-core.svc.cluster.local/api/unit/v2/unit/symbol'
      file_service_endpoint: 'http://file.osdu-core.svc.cluster.local/api/file/v2'
      KEYVAULT_URI: keyVaultUrl
      appinsights_key: insightsKey
      azure_paas_podidentity_isEnabled: 'false'
      AZURE_TENANT_ID: subscription().tenantId
      AZURE_CLIENT_ID: clientId
      AZURE_CLIENT_SECRET: clientSecret
      aad_client_id: clientId
    }
  }
]

module deploymentScript 'br/public:avm/res/resources/deployment-script:0.5.1' = {
  name: 'script-${storageAccount.name}-${replace(replace(filename, ':', ''), '/', '-')}'
  params: {
    name: 'script-${storageAccount.name}-${replace(replace(filename, ':', ''), '/', '-')}'
    location: location
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    runOnce: true

    managedIdentities: {
      userAssignedResourceIds: [
        identity.id
      ]
    }
    
    storageAccountResourceId: newStorageAccount ? '' : storageAccount.id

    kind: 'AzureCLI'
    azCliVersion: '2.73.0'

    environmentVariables: [
      { name: 'AZURE_STORAGE_ACCOUNT', value: storageAccount.name }
      { name: 'FILE', value: filename }
      { name: 'URL', value: fileurl }
      { name: 'SHARE', value: shareName }
      { name: 'initialDelay', value: initialScriptDelay }
      { name: 'SEARCH_AND_REPLACE', value: string(findAndReplace) }
    ]

    scriptContent: loadTextContent('script.sh')
  }
}
