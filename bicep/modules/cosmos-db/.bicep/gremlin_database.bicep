@description('Required. Name of the Gremlin database.')
param name string

@description('Optional. Tags of the Gremlin database resource.')
param tags object = {}

@description('Conditional. The name of the parent Gremlin database. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Optional. Array of graphs to deploy in the Gremlin database.')
param graphs array = []

@description('Optional. Represents maximum throughput, the resource can scale up to. Cannot be set together with `throughput`. If `throughput` is set to something else than -1, this autoscale setting is ignored.')
param maxThroughput int = 400

@description('Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.')
param throughput int = -1

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: databaseAccountName
}

var databaseOptions = contains(databaseAccount.properties.capabilities, { name: 'EnableServerless' }) ? {} : {
  autoscaleSettings: throughput == -1 ? {
    maxThroughput: maxThroughput
  } : null
  throughput: throughput != -1 ? throughput : null
}

resource gremlinDatabase 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2022-08-15' = {
  name: name
  tags: tags
  parent: databaseAccount
  properties: {
    options: databaseOptions
    resource: {
      id: name
    }
  }
}

module gremlinDatabase_gremlinGraphs 'gremlin_graph.bicep' = [for graph in graphs: {
  name: '${deployment().name}-${gremlinDatabase.name}-graph-${graph.name}'
  params: {
    name: graph.name
    gremlinDatabaseName: name
    databaseAccountName: databaseAccountName
    automaticIndexing: graph.?automaticIndexing ?? true
    partitionKeyPaths: !empty(graph.partitionKeyPaths) ? graph.partitionKeyPaths : []
  }
}]

@description('The name of the Gremlin database.')
output name string = gremlinDatabase.name

@description('The resource ID of the Gremlin database.')
output resourceId string = gremlinDatabase.id

@description('The name of the resource group the Gremlin database was created in.')
output resourceGroupName string = resourceGroup().name
