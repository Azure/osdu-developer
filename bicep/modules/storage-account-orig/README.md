# Azure Storage Module

This module deploys an Azure Storage Account.

## Description

This module supports the following features.

- Containers
- Tables
- Shares
- Role Assignments
- Diagnostics
- Private Link (Secure network)
- Customer Managed Encryption Keys
- Point in Time Restore
- SAS Secrets

## Parameters

| Name                                    | Type     | Required | Description                                                                                                                                                                                                                                                                   |
| :-------------------------------------- | :------: | :------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `resourceName`                          | `string` | Yes      | Used to name all resources                                                                                                                                                                                                                                                    |
| `location`                              | `string` | No       | Resource Location.                                                                                                                                                                                                                                                            |
| `tags`                                  | `object` | No       | Tags.                                                                                                                                                                                                                                                                         |
| `lock`                                  | `string` | No       | Optional. Specify the type of lock.                                                                                                                                                                                                                                           |
| `sku`                                   | `string` | No       | Specifies the storage account sku type.                                                                                                                                                                                                                                       |
| `accessTier`                            | `string` | No       | Specifies the storage account access tier.                                                                                                                                                                                                                                    |
| `containers`                            | `array`  | No       | Optional. Array of Storage Containers to be created.                                                                                                                                                                                                                          |
| `tables`                                | `array`  | No       | Optional. Array of Storage Tables to be created.                                                                                                                                                                                                                              |
| `shares`                                | `array`  | No       | Optional. Array of Storage Shares to be created.                                                                                                                                                                                                                              |
| `shareQuota`                            | `int`    | No       | Optional. The maximum size of the share, in gigabytes. Must be greater than 0, and less than or equal to 5120 (5TB). For Large File Shares, the maximum size is 102400 (100TB).                                                                                               |
| `enabledProtocols`                      | `string` | No       | Optional. The authentication protocol that is used for the file share. Can only be specified when creating a share.                                                                                                                                                           |
| `rootSquash`                            | `string` | No       | Optional. Permissions for NFS file shares are enforced by the client OS rather than the Azure Files service. Toggling the root squash behavior reduces the rights of the root user for NFS shares.                                                                            |
| `crossTenant`                           | `bool`   | No       | Optional. Indicates if the module is used in a cross tenant scenario. If true, a resourceId must be provided in the role assignment's principal object.                                                                                                                       |
| `roleAssignments`                       | `array`  | No       | Optional. Array of objects that describe RBAC permissions, format { roleDefinitionResourceId (string), principalId (string), principalType (enum), enabled (bool) }. Ref: https://docs.microsoft.com/en-us/azure/templates/microsoft.authorization/roleassignments?tabs=bicep |
| `diagnosticWorkspaceId`                 | `string` | No       | Optional. Resource ID of the diagnostic log analytics workspace.                                                                                                                                                                                                              |
| `diagnosticStorageAccountId`            | `string` | No       | Optional. Resource ID of the diagnostic storage account.                                                                                                                                                                                                                      |
| `diagnosticEventHubAuthorizationRuleId` | `string` | No       | Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.                                                                                                                    |
| `diagnosticEventHubName`                | `string` | No       | Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.                                                                                                                      |
| `diagnosticLogsRetentionInDays`         | `int`    | No       | Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.                                                                                                                                                                |
| `logsToEnable`                          | `array`  | No       | Optional. The name of logs that will be streamed.                                                                                                                                                                                                                             |
| `metricsToEnable`                       | `array`  | No       | Optional. The name of metrics that will be streamed.                                                                                                                                                                                                                          |
| `cmekConfiguration`                     | `object` | No       | Optional. Customer Managed Encryption Key.                                                                                                                                                                                                                                    |
| `deleteRetention`                       | `int`    | No       | Amount of days the soft deleted data is stored and available for recovery. 0 is off.                                                                                                                                                                                          |
| `privateLinkSettings`                   | `object` | No       | Settings Required to Enable Private Link                                                                                                                                                                                                                                      |
| `keyVaultName`                          | `string` | No       | Optional: Key Vault Name to store secrets into                                                                                                                                                                                                                                |
| `storageAccountSecretName`              | `string` | No       | Optional: To save storage account name into vault set the secret name.                                                                                                                                                                                                        |
| `storageAccountKeySecretName`           | `string` | No       | Optional: To save storage account key into vault set the secret name.                                                                                                                                                                                                         |
| `storageAccountConnectionString`        | `string` | No       | Optional: To save storage account connectionstring into vault set the secret name.                                                                                                                                                                                            |
| `basetime`                              | `string` | No       | Optional: Current Date Time                                                                                                                                                                                                                                                   |
| `sasProperties`                         | `object` | No       | Optional: Default SAS TOken Properties to download Blob.                                                                                                                                                                                                                      |
| `saveToken`                             | `bool`   | No       | Optional: To save storage account sas token into vault set the properties.                                                                                                                                                                                                    |

## Outputs

| Name | Type   | Description               |
| :--- | :----: | :------------------------ |
| id   | string | The resource ID.          |
| name | string | The name of the resource. |

## Examples

### Example 1

```bicep
module storage 'br:osdubicep.azurecr.io/public/storage-account:1.0.8' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    location: location
    sku: 'Standard_LRS'
  }
}
```

### Example 2

```bicep
module storage 'br:osdubicep.azurecr.io/public/storage-account:1.0.8' = {
  name: 'storage_account'
  params: {
    resourceName: resourceName
    location: location
    sku: 'Standard_LRS'

    containers: [
      'container1'
      'another'
    ]

    tables: [
      'table1'
      'another'
    ]

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalIds: [
          identity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Enable Diagnostics
    diagnosticWorkspaceId: logs.outputs.id

    // Enable Private Link
    privateLinkSettings:{
      vnetId: network.outputs.id
      subnetId: network.outputs.subnetIds[0]
    }

    // Enable Customer Managed Encryption Key
    cmekConfiguration: {
      kvUrl: 'https://akeyvault.vault.azure.net'
      keyName: 'akey'
      identityId: '/subscriptions/222222-2222-2222-2222-2222222222/resourcegroups/agroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/aidentity'
    }

    // Enable Point in Time Restore
    deleteRetention: 7
  }
}
```