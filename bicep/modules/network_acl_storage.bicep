@description('The name of the Azure Storage Account')
param storageName string

@description('The location of the Azure Storage Account')
param location string

@description('The SKU name of the Azure Storage Account') 
param skuName string = 'Standard_LRS'

@description('The IP address of the NAT cluster')
param natClusterIP string = ''

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = if (storageName != '') {
  name: storageName
}

resource updateNetworkRules 'Microsoft.Storage/storageAccounts@2024-01-01' =  {
  name: storageAccount.name  // Reference the existing storage account's name
  kind: 'StorageV2'
  location: location
  sku: {
    name: skuName
  }
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
  }
}
