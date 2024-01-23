param operatorIdentityName string
param identityclientId string

resource userIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' existing = {
  name: operatorIdentityName
}

var managedIdentityOperator = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
resource identityOperatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: userIdentity
  name: guid(userIdentity.id, identityclientId, managedIdentityOperator)
  properties: {
    roleDefinitionId: managedIdentityOperator
    principalType: 'ServicePrincipal'
    principalId: identityclientId
  }
}
