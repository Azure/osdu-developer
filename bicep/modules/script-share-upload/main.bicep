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
param fileurl string = 'https://raw.githubusercontent.com/Azure/osdu-developer/main/README.md'

@description('If the file is a tar.gz, should the contents be zipped when uploaded')
param compress bool = false


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' existing = {
  name: identityName
}

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(rbacRoleNeeded)) {
  name: guid(storageAccount.id, rbacRoleNeeded, identity.id )
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', rbacRoleNeeded)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

module deploymentScript 'br/public:avm/res/resources/deployment-script:0.4.0' = {
  name: 'script-${storageAccount.name}-${replace(replace(filename, ':', ''), '/', '-')}'
  params: {
    name: 'script-${storageAccount.name}-${replace(replace(filename, ':', ''), '/', '-')}'
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
      { name: 'URL', value: fileurl }
      { name: 'SHARE', value: shareName }
      { name: 'initialDelay', value: initialScriptDelay }
      { name: 'compress', value: string(compress) }
    ]
    scriptContent: loadTextContent('script.sh')
  }
}
