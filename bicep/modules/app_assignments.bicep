// param operatorIdentityName string
param identityprincipalId string

@description('The name of the Azure Key Vault')
param kvName string = ''

@description('The name of the Azure Storage Account')
param storageName string = ''


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
}

var keyVaultSecretsUser = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (kvName != '') {
  scope: keyVault
  name: guid(identityprincipalId, keyVault.id, keyVaultSecretsUser)
  properties: {
    roleDefinitionId: keyVaultSecretsUser
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}


var storageFileDataSmbShareReader = resourceId('Microsoft.Authorization/roleDefinitions', 'aba4ae5f-2193-4029-9191-0cb91df5e314')
resource storageRoleShare 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (storageName != '') {
  scope: storageAccount
  name: guid(identityprincipalId, storageAccount.id, storageFileDataSmbShareReader)
  properties: {
    roleDefinitionId: storageFileDataSmbShareReader
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}

var storageBlobContributor = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
resource storageRoleBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (storageName != '') {
  scope: storageAccount
  name: guid(identityprincipalId, storageAccount.id, storageBlobContributor)
  properties: {
    roleDefinitionId: storageBlobContributor
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}

var storageTableContributor = resourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
resource storageRoleTable 'Microsoft.Authorization/roleAssignments@2022-04-01' =  if (storageName != '') {
  scope: storageAccount
  name: guid(identityprincipalId, storageAccount.id, storageTableContributor)
  properties: {
    roleDefinitionId: storageTableContributor
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}
