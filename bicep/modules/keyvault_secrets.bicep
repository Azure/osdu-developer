@description('The name of the parent key vault.')
param keyVaultName string

@description('The name of the Analytics Workspace.')
@minLength(4)
param workspaceName string

@description('he name of the Application Insights component.')
@minLength(0)
param insightsName string

@description('The name of the cache.')
@minLength(0)
param cacheName string


resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource insights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: insightsName
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
  name: 'log-workspace-key'
  parent: keyVault

  properties: {
    value: logAnalytics.listKeys().primarySharedKey
  }
}

resource idSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'log-workspace-id'
  parent: keyVault

  properties: {
    value: logAnalytics.id
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

resource keyvaultUrl 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'keyvault-url'
  parent: keyVault

  properties: {
    value: keyVault.properties.vaultUri
  }
}

output keyVaultName string = keyVault.name
