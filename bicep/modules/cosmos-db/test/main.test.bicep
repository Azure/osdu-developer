targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Resource Location.')
param location string = resourceGroup().location


//  Module --> Create Resource SQL
module database '../main.bicep' = {
  name: 'cosmos_db'
  params: {
    resourceName: resourceName
    resourceLocation: location

    // Configure SQL Database
    sqlDatabases: [
      { 
        name: 'db01'
        containers: [
          {
            name: 'container'
            kind: 'Hash'
            paths: [
              '/id'
            ]
            uniqueKeyPaths: [
              '/id'
            ]
          }
        ]
      }
    ]
  }
}
