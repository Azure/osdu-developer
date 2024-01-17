@description('Conditional. The name of the parent key vault. Required if the template is used in a standalone deployment.')
param keyVaultName string

@description('Conditional. The name of the Analytics Workspace. Required if the template is used in a standalone deployment.')
param workspaceName string

@description('Required. The name of the secret.')
param workspaceIdName string

@description('Required. The name of the secret.')
param workspaceKeySecretName string

resource logAnaltyics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: workspaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: workspaceKeySecretName
  parent: keyVault

  properties: {
    value: logAnaltyics.listKeys().primarySharedKey
  }
}

resource idSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: workspaceIdName
  parent: keyVault

  properties: {
    value: logAnaltyics.id
  }
}

