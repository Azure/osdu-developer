# AKS Config Map Script

An Azure CLI Deployment Script that allows you to create a configmap on a Kubernetes cluster.

## Details

AKS config map allows you to remotely create configmaps in an AKS cluster through the AKS API. This module makes use of a custom script to use this capability to create a configmap in a Bicep accessible module.
This module configures the required permissions so that you do not have to configure the identity.

## Parameters

| Name                                       | Type     | Required | Description                                                                                                   |
| :----------------------------------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------ |
| `aksName`                                  | `string` | Yes      | The name of the Azure Kubernetes Service                                                                      |
| `location`                                 | `string` | Yes      | The location to deploy the resources to                                                                       |
| `forceUpdateTag`                           | `string` | No       | How the deployment script should be forced to execute                                                         |
| `rbacRolesNeeded`                          | `array`  | No       | An array of Azure RoleIds that are required for the DeploymentScript resource                                 |
| `newOrExistingManagedIdentity`             | `string` | No       | Create "new" or use "existing" Managed Identity. Default: new                                                 |
| `managedIdentityName`                      | `string` | No       | Name of the Managed Identity resource                                                                         |
| `existingManagedIdentitySubId`             | `string` | No       | For an existing Managed Identity, the Subscription Id it is located in                                        |
| `existingManagedIdentityResourceGroupName` | `string` | No       | For an existing Managed Identity, the Resource Group it is located in                                         |
| `initialScriptDelay`                       | `string` | No       | A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate |
| `cleanupPreference`                        | `string` | No       | When the script resource is cleaned up                                                                        |
| `isCrossTenant`                            | `bool`   | No       | Set to true when deploying template across tenants                                                            |
| `name`                                     | `string` | Yes      | The name of the configmap                                                                                     |
| `namespace`                                | `string` | Yes      | The namespace for the configmap                                                                               |
| `propertyData`                             | `string` | Yes      | Property-like keys; each key maps to a simple value                                                           |
| `fileData`                                 | `string` | Yes      | File-like keys                                                                                                |

## Outputs

| Name            | Type    | Description                                                         |
| :-------------- | :-----: | :------------------------------------------------------------------ |
| `commandOutput` | `array` | Array of command output from each Deployment Script AKS run command |

## Examples

### Creating a simple configmap

```bicep
module runCmd 'br/public:deployment-scripts/aks-run-command:2.0.2' = {
  name: 'kubectlGetPods'
  params: {
    aksName: aksName
    location: location
    name: 'myConfigMap'
    namespace: 'default'
    propertyData: [
      'hello=world'
    ]
  }
}
```

### Creating a complex configmap

```bicep
module runCmd 'br/public:deployment-scripts/aks-run-command:2.0.2' = {
  name: 'kubectlGetPods'
  params: {
    aksName: aksName
    location: location
    name: 'myConfigMap'
    namespace: 'default'
    propertyData: [
      'player_initial_lives=3'
      'ui_properties_file_name=user-interface.properties'
    ]
    fileData: [
      'game.properties: |enemy.types=aliens,monsters\nplayer.maximum-lives=5'
      'user-interface.properties: |color.good=purple\ncolor.bad=yellow\nallow.textmode=true'
    ]
  }
}
```

### Using an existing managed identity

When working with an existing managed identity that has the correct RBAC, you can opt out of new RBAC assignments and set the initial delay to zero.

```bicep
module runCmd 'br/public:deployment-scripts/aks-run-command:2.0.2' = {
  name: 'kubectlGetNodes'
  params: {
    useExistingManagedIdentity: true
    initialScriptDelay: '0'
    managedIdentityName: managedIdentityName
    rbacRolesNeeded:[]
    aksName: aksName
    location: location
    name: 'myConfigMap'
    namespace: 'default'
    propertyData: [
      'hello=world'
    ]
  }
}
```
