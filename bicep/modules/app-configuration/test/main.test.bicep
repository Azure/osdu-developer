targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location

//  Module --> Create Resource
module app_config '../main.bicep' = {
  name: 'azure_app_config'
  params: {
    resourceName: resourceName
    location: location
    
    keyValues: [
      // Simple Key Value Pair
      {
        name: 'AValue'
        value: 'Hello World'
        contentType: 'text/plain'
        label: 'development'
        tags: {
          service: 'worker'
        }
      }

    ]
  }
}
