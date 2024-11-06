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
param rbacRoleNeeded string = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' //Storage Blob Data Owner

// Custom Parameters

@description('Whether to create a new storage account or use an existing one')
param newStorageAccount bool = true

@description('Name of the container')
param containerName string = 'gitops'

@description('Name of the file as it is stored in the share')
param filename string = 'main.zip'

@description('Name of the directory to upload')
param directoryName string

@description('The source of the software to upload')
param softwareSource string = 'https://github.com/azure/osdu-developer'

@description('Name of the file as it is stored in the share')
param fileurl string = '/archive/refs/heads/main.zip'


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
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

module deploymentScript 'br/public:avm/res/resources/deployment-script:0.4.0' = {
  name: 'script-${storageAccount.name}-${directoryName}-${replace(replace(filename, ':', ''), '/', '-')}'
  params: {
    name: 'script-${storageAccount.name}-${directoryName}-${replace(replace(filename, ':', ''), '/', '-')}'
    location: location
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    runOnce: true
    
    managedIdentities: {
      userAssignedResourcesIds: [
        identity.id
      ]
    }
    
    storageAccountResourceId: newStorageAccount ? '' : storageAccount.id

    kind: 'AzureCLI'
    azCliVersion: '2.63.0'
    
    environmentVariables: [
      { name: 'AZURE_STORAGE_ACCOUNT', value: storageAccount.name }
      { name: 'AZURE_STORAGE_KEY', value: storageAccount.listKeys().keys[0].value }
      { name: 'FILE', value: filename }
      { name: 'URL', value: '${softwareSource}${fileurl}' }
      { name: 'CONTAINER', value: containerName }
      { name: 'UPLOAD_DIR', value: string(directoryName) }
      { name: 'initialDelay', value: initialScriptDelay }
    ]
    scriptContent: loadTextContent('script.sh')
  }
}

