// Role Assignments Created:
// 1. Key Vault Secrets User (4633458b-17de-408a-b874-0445c86b69e6) on Key Vault
// 2. Storage File Data SMB Share Reader (aba4ae5f-2193-4029-9191-0cb91df5e314) on Storage Account  
// 3. Storage Blob Data Contributor (ba92f5b4-2d11-453d-a403-e96b0029c9fe) on Storage Account
// 4. Storage Table Data Contributor (0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3) on Storage Account
// 5. Contributor (b24988ac-6180-42a0-ab88-20f7382dd24c) on Cosmos DB

@description('The principal ID of the identity to assign the roles to')
param identityprincipalId string

@description('The name of the Azure Key Vault')
param kvName string = ''

@description('The name of the Azure Storage Account')
param storageName string = ''

@description('The name of the Azure Comos DB Account')
param databaseName string = ''

/////////////////////////////////
// Existing Resources
/////////////////////////////////

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageName
}

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: databaseName
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


var databaseContributor = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
resource databaseRole 'Microsoft.Authorization/roleAssignments@2022-04-01' =  if (databaseName != '') {
  scope: databaseAccount
  name: guid(identityprincipalId, storageAccount.id, databaseContributor)
  properties: {
    roleDefinitionId: databaseContributor
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}
