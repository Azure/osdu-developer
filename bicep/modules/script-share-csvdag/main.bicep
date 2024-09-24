// This modules is a custom module tightly coupled to the csv-parser dag.

metadata name = 'Blob Upload'
metadata description = 'This module uploads a file to a blob storage account'
metadata owner = 'azure-global-energy'

@description('Desired name of the storage account')
param storageAccountName string = uniqueString(resourceGroup().id, deployment().name, 'blob')

@description('Name of the file share')
param shareName string = 'sample-share'

@description('Name of the file as it is stored in the share')
param filename string = 'sample.json'

@description('Name of the file as it is stored in the share')
param fileurl string = 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz'

@description('The location of the Storage Account and where to deploy the module resources to')
param location string = resourceGroup().location

@description('How the deployment script should be forced to execute')
param forceUpdateTag string = utcNow()

@description('Azure RoleId that are required for the DeploymentScript resource to upload blobs')
param rbacRoleNeeded string = '' //Storage File Contributor is needed to upload

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-storage-share-${location}'

@description('For an existing Managed Identity, the Subscription Id it is located in')
param existingManagedIdentitySubId string = subscription().subscriptionId

@description('For an existing Managed Identity, the Resource Group it is located in')
param existingManagedIdentityResourceGroupName string = resourceGroup().name

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '30s'

@allowed([ 'OnSuccess', 'OnExpiration', 'Always' ])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'

@description('Keyvault url')
param keyVaultUrl string

@description('App Insights Instrumentation Key')
param insightsKey string

@description('Client Id for the service principal')
param clientId string

@description('Client Secret for the service principal')
param clientSecret string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  name: storageAccountName
}

resource newDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (!useExistingManagedIdentity) {
  name: managedIdentityName
  location: location
}

resource existingDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (useExistingManagedIdentity) {
  name: managedIdentityName
  scope: resourceGroup(existingManagedIdentitySubId, existingManagedIdentityResourceGroupName)
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(storageAccount.id, rbacRoleNeeded, useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: useExistingManagedIdentity ? existingDepScriptId.properties.principalId : newDepScriptId.properties.principalId
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

resource uploadFile 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'script-${storageAccount.name}-${replace(replace(filename, ':', ''), '/', '-')}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id}': {} }
  }
  kind: 'AzureCLI'
  dependsOn: [ rbac ]
  properties: {
    forceUpdateTag: forceUpdateTag
    azCliVersion: '2.63.0'
    timeout: 'PT30M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      { name: 'AZURE_STORAGE_ACCOUNT', value: storageAccount.name }
      { name: 'AZURE_STORAGE_KEY', value: storageAccount.listKeys().keys[0].value }
      { name: 'FILE', value: filename }
      { name: 'URL', value: fileurl }
      { name: 'SHARE', value: shareName }
      { name: 'initialDelay', value: initialScriptDelay }
      { name: 'SEARCH_AND_REPLACE', value: string(findAndReplace) }
    ]
    scriptContent: loadTextContent('script.sh')
    cleanupPreference: cleanupPreference
  }
}

