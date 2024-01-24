// param operatorIdentityName string
param identityprincipalId string

@description('The name of the Azure Key Vault')
param kvName string

// resource userIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' existing = {
//   name: operatorIdentityName
// }

// var managedIdentityOperator = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
// resource identityOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   scope: userIdentity
//   name: guid(userIdentity.id, identityprincipalId, managedIdentityOperator)
//   properties: {
//     roleDefinitionId: managedIdentityOperator
//     principalType: 'ServicePrincipal'
//     principalId: identityprincipalId
//   }
// }

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: kvName
}

var keyVaultSecretsUser = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
resource kvRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(identityprincipalId, keyVault.id)
  properties: {
    roleDefinitionId: keyVaultSecretsUser
    principalType: 'ServicePrincipal'
    principalId: identityprincipalId
  }
}
