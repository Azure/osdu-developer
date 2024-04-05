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

resource logAnaltyics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: workspaceName
}

resource insights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: insightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
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

output name string = keyVault.name
