# CosmosDB and Child Resources

This module deploys cosmos database accounts and child resources.

## Description

{{ Add detailed description for the module. }}

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `resourceLocation`                      | `string` | No       | Optional: Resource Location.                                                                                                                                                                                                                                                  |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `enableDeleteLock`                      | `bool`   | No       | Enable lock to prevent accidental deletion                                                                                                                                                                                                                                    |
| `multiwriteRegions`                     | `array`  | No       | Optional. Locations enabled for the Cosmos DB account.                                                                                                                                                                                                                        |
| `maxThroughput`                         | `int`    | No       | Optional. Represents maximum throughput, the resource can scale up to. Cannot be set together with `throughput`. If `throughput` is set to something else than -1, this autoscale setting is ignored.                                                                         |
| `throughput`                            | `int`    | No       | Optional. Request Units per second (for example 10000). Cannot be set together with `maxThroughput`.                                                                                                                                                                          |
| `systemAssignedIdentity`                | `bool`   | No       | Optional. Enables system assigned managed identity on the resource.                                                                                                                                                                                                           |
| `userAssignedIdentities`                | `object` | No       | Optional. The ID(s) to assign to the resource.                                                                                                                                                                                                                                |
| `defaultIdentity`                       | `string` | No       | Optional. The default identity to be used.                                                                                                                                                                                                                                    |
| `databaseAccountOfferType`              | `string` | No       | Optional. The offer type for the Cosmos DB database account.                                                                                                                                                                                                                  |
| `defaultConsistencyLevel`               | `string` | No       | Optional. The default consistency level of the Cosmos DB account.                                                                                                                                                                                                             |
| `automaticFailover`                     | `bool`   | No       | Optional. Enable automatic failover for regions.                                                                                                                                                                                                                              |
| `maxStalenessPrefix`                    | `int`    | No       | Optional. Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.                                                                                                                                     |
| `maxIntervalInSeconds`                  | `int`    | No       | Optional. Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.                                                                                                                                         |
| `serverVersion`                         | `string` | No       | Optional. Specifies the MongoDB server version to use.                                                                                                                                                                                                                        |
| `sqlDatabases`                          | `array`  | No       | Optional. SQL Databases configurations.                                                                                                                                                                                                                                       |
| `gremlinDatabases`                      | `array`  | No       | Optional. Gremlin Databases configurations.                                                                                                                                                                                                                                   |
| `mongodbDatabases`                      | `array`  | No       | Optional. MongoDB Databases configurations.                                                                                                                                                                                                                                   |
| `capabilitiesToAdd`                     | `array`  | No       | Optional. List of Cosmos DB capabilities for the account.                                                                                                                                                                                                                     |
| `backupPolicyType`                      | `string` | No       | Optional. Describes the mode of backups.                                                                                                                                                                                                                                      |
| `backupPolicyContinuousTier`            | `string` | No       | Optional. Configuration values for continuous mode backup.                                                                                                                                                                                                                    |
| `backupIntervalInMinutes`               | `int`    | No       | Optional. An integer representing the interval in minutes between two backups. Only applies to periodic backup type.                                                                                                                                                          |
| `backupRetentionIntervalInHours`        | `int`    | No       | Optional. An integer representing the time (in hours) that each backup is retained. Only applies to periodic backup type.                                                                                                                                                     |
| `backupStorageRedundancy`               | `string` | No       | Optional. Enum to indicate type of backup residency. Only applies to periodic backup type.                                                                                                                                                                                    |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `kvKeyUri`                              | `string` | No       | Optional. Customer Managed Encryption Key.                                                                                                                                                                                                                                    |
| `crossTenant`                           | `bool`   | No       | Optional. Indicates if the module is used in a cross tenant scenario. If true, a resourceId must be provided in the role assignment's principal object.                                                                                                                       |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |
| `keyVaultName`                          | `string` | No       | Optional: Key Vault Name to store secrets into                                                                                                                                                                                                                                |
| `databaseEndpointSecretName`            | `string` | No       | Optional: To save storage account name into vault set the secret hame.                                                                                                                                                                                                        |
| `databasePrimaryKeySecretName`          | `string` | No       | Optional: To save storage account key into vault set the secret hame.                                                                                                                                                                                                         |
| `databaseConnectionStringSecretName`    | `string` | No       | Optional: To save storage account connectionstring into vault set the secret hame.                                                                                                                                                                                            |

## Outputs

| Name                      | Type   | Description                                                         |
| :------------------------ | :----: | :------------------------------------------------------------------ |
| name                      | string | The name of the database account.                                   |
| id                        | string | The resource ID of the database account.                            |
| resourceGroupName         | string | The name of the resource group the database account was created in. |
| systemAssignedPrincipalId | string | The principal ID of the system assigned identity.                   |
| location                  | string | The location the resource was deployed into.                        |

## Examples

### Example 1

```bicep
module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.1' = {
  name: 'cosmos_db'
  params: {
    resourceName: resourceName
    resourceLocation: location

    // Configure NoSQL Database
    sqlDatabases: [
      {
        name: 'db01'
        containers: []
      }
    ]
  }
}
```

### Example 2

```bicep
module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.1' = {
  name: 'cosmos_db'
  params: {
    resourceName: resourceName
    resourceLocation: location

    // Configure Gremlin Database -- Used for Graphs
    capabilitiesToAdd: [
      'EnableGremlin'
    ]
    gremlinDatabases: [
      {
        graphs: [
          {
            automaticIndexing: true
            name: 'collection1'
            partitionKeyPaths: [
              '/col1_id'
            ]
          }
          {
            automaticIndexing: true
            name: 'collection2'
            partitionKeyPaths: [
              '/col2_id'
            ]
          }
        ]
        name: 'graph-001'
      }
    ]

    // Hook up Multiple Region Write (can't be used with Continous Backup)
    backupPolicyType: 'Periodic'
    multiwriteRegions: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: 'South Central US'
      }
      {
        failoverPriority: 1
        isZoneRedundant: false
        locationName: 'Central US'
      }
    ]

    // Hook up the identity to the database
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${identity.outputs.id}': { }
      '/subscriptions/222222-2222-2222-2222-2222222222/resourcegroups/agroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aidentity': {}
    }
    defaultIdentity: '/subscriptions/222222-2222-2222-2222-2222222222/resourcegroups/agroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aidentity'

    // Enable Customer Managed Encryption Key (Provision Time only)
    kvKeyUri: 'https://akeyvault.vault.azure.net/keys/akey'
    
    // Hook up Diagnostics
    diagnosticWorkspaceId: logs.outputs.id

    // Hook up Private Link
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    } 

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Cosmos DB Account Reader Role'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}
```