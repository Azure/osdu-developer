# App Configuration

This module deploys an App Configuration.

## Details

{{Add detailed information about the module}}

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string` | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `lock`                                  | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                           |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `sku`                                   | `string` | No       | Optional. Pricing tier of App Configuration.                                                                                                                                                                                                                                  |
| `createMode`                            | `string` | No       | Optional. Indicates whether the configuration store need to be recovered.                                                                                                                                                                                                     |
| `disableLocalAuth`                      | `bool`   | No       | Optional. Disables all authentication methods other than AAD authentication.                                                                                                                                                                                                  |
| `systemAssignedIdentity`                | `bool`   | No       | Optional. Enables system assigned managed identity on the resource.                                                                                                                                                                                                           |
| `userAssignedIdentities`                | `object` | No       | Optional. The ID(s) to assign to the resource.                                                                                                                                                                                                                                |
| `keyValues`                             | `array`  | No       | Optional. All Key / Values to create.                                                                                                                                                                                                                                         |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `cmekConfiguration`                     | `object` | No       | Optional. Customer Managed Encryption Key.                                                                                                                                                                                                                                    |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |

## Outputs

| Name       | Type     | Description                                            |
| :--------- | :------: | :----------------------------------------------------- |
| `name`     | `string` | The name of the azure app configuration service.       |
| `id`       | `string` | The resourceId of the azure app configuration service. |
| `endpoint` | `string` | The endpoint of the azure app configuration service.   |

## Examples

### Example 1

```bicep
module configStore 'br:osdubicep.azurecr.io/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
  }
}
```

### Example 2

```bicep
// Feature Flag Sample
var featureFlagKey = 'AFeatureFlag'
var featureFlagDescription = 'This is a sample feature flag'
var featureFlagLabel = 'development'

// Key Vault Secret
@description('Format should be https://{vault-name}.{vault-DNS-suffix}/secrets/{secret-name}/{secret-version}. Secret version is optional.')
var kvSecret = 'https://akeyvault.vault.azure.net/secrets/asecret'
var keyVaultRef = {
  uri: kvSecret
}

//  Module --> Create Resource
module app_config 'br:osdubicep.azurecr.io/public/app-configuration:1.0.2' = {
  name: 'azure_app_config'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    
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
      // Key Vault Secret Reference
      {
        name: 'ASecret'
        value: string(keyVaultRef)
        contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        label: 'development'
        tags: {
          service: 'worker'
        }
      }
      // Feature Flag Sample
      {
        name: '.appconfig.featureflag~2F${featureFlagKey}$${featureFlagLabel}'
        value: string({
        id: featureFlagKey
        description: featureFlagDescription
        enabled: true
      })
        contentType: 'application/vnd.microsoft.appconfig.ff+json;charset=utf-8'
        tags: {
          service: 'worker'
        }
      }
    ]

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'App Configuration Data Reader'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Enable Diagnostics
    diagnosticWorkspaceId: logs.outputs.id

    // Hook up the identity to the database
    systemAssignedIdentity: false
    userAssignedIdentities: {
      '${identity.outputs.id}': { }
      '/subscriptions/222222-2222-2222-2222-2222222222/resourcegroups/keep/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aidentity': {}
    }

    // Enable Private Link
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }

    // Enable Customer Managed Encryption Key
    cmekConfiguration: {
      kvUrl: 'https://akeyvault.vault.azure.net'
      keyName: 'akey'
      identityId: '222222-2222-2222-2222-2222222222'
    }
  }
}
```

### Example 3

```bicep
module ac 'br:osdubicep.azurecr.io/bicep/modules/public/app-configuration:1.0.2' = {
  name: 'azure_app_configuration'
  params: {
    resourceName: 'ac${unique(resourceGroup().name)}'
    location: 'southcentralus'
    enableDeleteLock: true
    configObjects: {
      configs: [
        {
          key: 'myKey'
          value: 'myValue'
        }
        {
          key: 'keyVaultref'
          value: string(
            {
              uri: 'keyVaultSecretURL'
            }
          )
          contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
        }
      ]
    }
  }
}
```