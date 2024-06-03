@description('Conditional. The name of the parent key vault. Required if the template is used in a standalone deployment.')
param keyVaultName string

@description('Conditional. The name of the Analytics Workspace. Required if the template is used in a standalone deployment.')
param workspaceName string

@description('Required. The name of the secret.')
param workspaceIdName string

@description('Required. The name of the secret.')
param workspaceKeySecretName string

@description('Conditional. The name of the Analytics Workspace. Required if the template is used in a standalone deployment.')
param insightsName string

@description('Required. The name of the cache.')
param cacheName string

resource logAnaltyics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource insights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: insightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource redis 'Microsoft.Cache/redis@2022-06-01' existing = {
  name: cacheName
}

resource cachePassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'redis-password'
  parent: keyVault

  properties: {
    value: redis.listKeys().primaryKey
  }
}

resource cacheHost 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'redis-hostname'
  parent: keyVault

  properties: {
    value: redis.properties.hostName
    // value: 'redis-master.redis-cluster.svc.cluster.local'
  }
}

resource vaultUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'keyvault-uri'
  parent: keyVault

  properties: {
    value: keyVault.properties.vaultUri
  }
}

resource keySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: workspaceKeySecretName
  parent: keyVault

  properties: {
    value: logAnaltyics.listKeys().primarySharedKey
  }
}

resource idSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: workspaceIdName
  parent: keyVault

  properties: {
    value: logAnaltyics.id
  }
}

resource insightsSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'insights-key'
  parent: keyVault

  properties: {
    value: insights.properties.InstrumentationKey
  }
}

resource insightsConnection 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'insights-connection'
  parent: keyVault

  properties: {
    value: insights.properties.ConnectionString
  }
}

output name string = keyVault.name
