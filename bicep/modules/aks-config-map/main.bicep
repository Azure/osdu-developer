metadata name = 'AKS Config Map'
metadata description = 'An Azure CLI Deployment Script that allows you to create a helm char on a Kubernetes cluster.'
metadata owner = 'Daniel Scholl'

@description('The name of the Azure Kubernetes Service')
param aksName string

@description('The location to deploy the resources to')
param location string

@description('How the deployment script should be forced to execute')
param forceUpdateTag  string = utcNow()

@description('An array of Azure RoleIds that are required for the DeploymentScript resource')
param rbacRolesNeeded array = [
  'b24988ac-6180-42a0-ab88-20f7382dd24c' //Contributor
  '7f6c6a51-bcf8-42ba-9220-52d62157d7db' //Azure Kubernetes Service RBAC Reader
]

@description('Create "new" or use "existing" Managed Identity. Default: new')
@allowed([ 'new', 'existing' ])
param newOrExistingManagedIdentity string = 'new'

@description('Name of the Managed Identity resource')
param managedIdentityName string = 'id-AksConfigMap-${location}'

@description('For an existing Managed Identity, the Subscription Id it is located in')
param existingManagedIdentitySubId string = subscription().subscriptionId

@description('For an existing Managed Identity, the Resource Group it is located in')
param existingManagedIdentityResourceGroupName string = resourceGroup().name

@description('Specify the config map name.')
param name string = 'configuration'

@description('Specify the namespace for the config mapl')
param namespace string = 'default'

@description('Specify the config map single property data. (e.g. "player_initial_lives=3")')
param propertyData array = [
  // 'player_initial_lives=3'
  // 'ui_properties_file_name=user-interface.properties'
]

@description('Specify the config map file data. (e.g. "game.properties: |enemy.types=aliens,monsters\nplayer.maximum-lives=5")')
param fileData array = [
  // 'game.properties: |enemy.types=aliens,monsters\nplayer.maximum-lives=5'
  // 'user-interface.properties: |color.good=purple\ncolor.bad=yellow\nallow.textmode=true'
]

@description('A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate')
param initialScriptDelay string = '120s'

@allowed([ 'OnSuccess', 'OnExpiration', 'Always' ])
@description('When the script resource is cleaned up')
param cleanupPreference string = 'OnSuccess'

@description('Set to true when deploying template across tenants') 
param isCrossTenant bool = false

var useExistingManagedIdentity = newOrExistingManagedIdentity == 'existing'

resource aks 'Microsoft.ContainerService/managedClusters@2022-11-01' existing = {
  name: aksName
}

resource newDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (!useExistingManagedIdentity) {
  name: managedIdentityName
  location: location
}

resource existingDepScriptId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (useExistingManagedIdentity) {
  name: managedIdentityName
  scope: resourceGroup(existingManagedIdentitySubId, existingManagedIdentityResourceGroupName)
}

var delegatedManagedIdentityResourceId = useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id

resource rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefId in rbacRolesNeeded: {
  name: guid(aks.id, roleDefId, useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id)
  scope: aks
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefId)
    principalId: useExistingManagedIdentity ? existingDepScriptId.properties.principalId : newDepScriptId.properties.principalId
    principalType: 'ServicePrincipal'
    delegatedManagedIdentityResourceId: isCrossTenant ? delegatedManagedIdentityResourceId : null
  }
}]


resource runAksCommand 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'script-${aks.name}-${deployment().name}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${useExistingManagedIdentity ? existingDepScriptId.id : newDepScriptId.id}': {}
    }
  }
  kind: 'AzureCLI'
  dependsOn: [
    rbac
  ]
  properties: {
    forceUpdateTag: forceUpdateTag
    azCliVersion: '2.63.0'
    timeout: 'PT30M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      { name: 'RG', value: resourceGroup().name }
      { name: 'aksName', value: aksName }
      { name: 'configMap', value: name }
      { name: 'namespace', value: namespace}
      { name: 'dataPropertyLike', value: join(propertyData, ';') }
      { name: 'dataFileLike', value: join(fileData, ';') }
      { name: 'initialDelay', value: initialScriptDelay}
    ]
    scriptContent: loadTextContent('aks-configmap-command.sh')
    cleanupPreference: cleanupPreference
  }
}

@description('Array of command output from each Deployment Script AKS run command')
output commandOutput object = {
  Name: runAksCommand.name
  CommandOutput: runAksCommand.properties.outputs
}
