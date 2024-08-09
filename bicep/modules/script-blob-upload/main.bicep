metadata name = 'Blob Upload'
metadata description = 'This module uploads a file to a blob storage account'
metadata owner = 'azure-global-energy'

@description('Desired name of the storage account')
param storageAccountName string = uniqueString(resourceGroup().id, deployment().name, 'blob')

@description('Name of the blob container')
param containerName string = 'legal-service-azure-configuration'

@description('Name of the blob as it is stored in the blob container')
param filename string = 'Legal_COO.json'

@description('The location of the Storage Account and where to deploy the module resources to')
param location string = resourceGroup().location

@description('How the deployment script should be forced to execute')
param forceUpdateTag string = utcNow()

@description('Azure RoleId that are required for the DeploymentScript resource to upload blobs')
param rbacRoleNeeded string = '' //Storage Blob Contributor is needed to upload secrets into Storage Account

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-storage-blob-${location}'

@description('For an existing Managed Identity, the Subscription Id it is located in')
param existingManagedIdentitySubId string = subscription().subscriptionId

@description('For an existing Managed Identity, the Resource Group it is located in')
param existingManagedIdentityResourceGroupName string = resourceGroup().name

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '30s'

@allowed([ 'OnSuccess', 'OnExpiration', 'Always' ])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'


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

resource uploadFile 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
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
    azCliVersion: '2.62.0'
    timeout: 'PT15M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      { name: 'AZURE_STORAGE_ACCOUNT', value: storageAccount.name }
      { name: 'AZURE_STORAGE_KEY', value: storageAccount.listKeys().keys[0].value }
      { name: 'CONTENT', value: loadTextContent('./Legal_COO.json') }
      { name: 'FILE_NAME', value: filename }
      { name: 'CONTAINER', value: containerName }
      { name: 'initialDelay', value: initialScriptDelay }
    ]
    scriptContent: loadTextContent('script.sh')
    // scriptContent: 'echo "$CONTENT" > ${filename} && az storage blob upload -f ${filename} -c ${containerName} -n ${filename}'
    cleanupPreference: cleanupPreference
  }
}

