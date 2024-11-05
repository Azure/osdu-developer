@description('The name of the Azure Key Vault')
param keyVaultName string

@description('The location of the Azure Key Vault')
param location string

@description('The IP address of the NAT cluster')
param natClusterIP string = ''

@description('Enable RBAC authorization')
param enableRbacAuthorization bool

@description('Enable soft delete')
param enableSoftDelete bool

@description('Soft delete retention in days')
param softDeleteRetentionInDays int

@description('SKU family for the Key Vault')
param skuFamily string

@description('SKU name for the Key Vault')
param skuName string

resource updateNetworkRules 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: natClusterIP != '' ? [
        {
          value: natClusterIP
        }
      ] : []
    }
    enableRbacAuthorization: enableRbacAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    tenantId: subscription().tenantId
    sku: {
      family: skuFamily
      name: skuName
    }
  }
}
