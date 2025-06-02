@description('The name of the parent key vault.')
param keyVaultName string

@description('The name of the partition.')
param partitionName string

@description('The name of the service bus.')
param serviceBusName string

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2024-01-01' existing = if (serviceBusName != 'null') {
  name: serviceBusName
}

// Conditional variable for connection string
var serviceBusEndpoint = '${serviceBus.id}/AuthorizationRules/RootManageSharedAccessKey'

resource serviceBusConnection 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (serviceBusName != 'null') {
  name: '${partitionName}-sb-connection'
  parent: keyVault

  properties: {
    value: listKeys(serviceBusEndpoint, serviceBus.apiVersion).primaryConnectionString
  }
}

resource serviceBusNamespace 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = if (serviceBusName != 'null') {
  name: '${partitionName}-sb-namespace'
  parent: keyVault

  properties: {
    value: serviceBus.name
  }
}

resource elasticEndpoint 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: '${partitionName}-elastic-endpoint'
  parent: keyVault

  properties: {
    value: 'http://elasticsearch-es-http.elastic-search:9200'
  }
}

resource elasticUserName 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: '${partitionName}-elastic-username'
  parent: keyVault

  properties: {
    value: 'elastic-user'
  }
}

resource elasticUserPassword 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: '${partitionName}-elastic-password'
  parent: keyVault

  properties: {
    value: substring(uniqueString(keyVault.id, partitionName, resourceGroup().id), 0, 8)
  }
}

resource elasticKey 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: '${partitionName}-elastic-key'
  parent: keyVault

  properties: {
    value: uniqueString(keyVault.id, partitionName, subscription().id, resourceGroup().id)
  }
}

output keyVaultName string = keyVault.name
