@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Conditional. The name of the parent SQL Database. Required if the template is used in a standalone deployment.')
param sqlDatabaseName string

@description('Required. Name of the container.')
param name string

@description('Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.')
param throughput int = -1

@description('Optional. Tags of the SQL Database resource.')
param tags object = {}

@description('Optional. List of paths using which data within the container can be partitioned.')
param paths array = []

@description('Optional. List of unique key paths using which data within the container can be partitioned.')
param uniqueKeyPaths array = []

@description('Optional. Indicates the kind of algorithm used for partitioning.')
@allowed([
  'Hash'
  'MultiHash'
  'Range'
])
param kind string = 'Hash'

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: databaseAccountName

  resource sqlDatabase 'sqlDatabases@2022-08-15' existing = {
    name: sqlDatabaseName
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: name
  parent: databaseAccount::sqlDatabase
  tags: tags
  properties: {
    resource: {
      id: name
      partitionKey: {
        paths: paths
        kind: kind
      }
      uniqueKeyPolicy: empty(uniqueKeyPaths) ? null : {
        uniqueKeys: [
          {
            paths: uniqueKeyPaths
          }
        ]
      }
    }
    options: contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' }) || throughput == -1 ? null : {
      throughput: throughput
    }
  }
}

@description('The name of the container.')
output name string = container.name

@description('The resource ID of the container.')
output resourceId string = container.id

@description('The name of the resource group the container was created in.')
output resourceGroupName string = resourceGroup().name
