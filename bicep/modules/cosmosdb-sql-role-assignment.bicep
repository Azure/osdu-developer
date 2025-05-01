@description('Name of the Cosmos DB account')
param databaseAccountName string

@description('Name of the SQL database (if scope is at database level)')
@allowed([ '', 'database' ])
param databaseName string = ''

@description('Optional custom scope. If provided, overrides databaseName logic.')
param customScope string = ''

@description('Principal (Object ID) of the identity to assign')
param principalId string

@description('Full resource ID of the Cosmos DB SQL role definition')
param roleDefinitionId string

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' existing = {
  name: databaseAccountName
}

var resolvedScope = !empty(customScope)
  ? customScope
  : !empty(databaseName)
    ? '${cosmosDbAccount.id}/sqlDatabases/${databaseName}'
    : cosmosDbAccount.id

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-11-15' = {
  name: guid(cosmosDbAccount.id, principalId, roleDefinitionId)
  parent: cosmosDbAccount
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    scope: resolvedScope
  }
}
