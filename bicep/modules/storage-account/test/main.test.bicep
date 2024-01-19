targetScope = 'resourceGroup'

@minLength(3)
@maxLength(22)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location


//  Module --> Create Storage Account
module storage '../main.bicep' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    location: location
    sku: 'Standard_LRS'
  }
}
