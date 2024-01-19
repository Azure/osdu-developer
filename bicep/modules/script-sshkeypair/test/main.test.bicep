targetScope = 'resourceGroup'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param resourceName string

@description('Registry Location.')
param location string = resourceGroup().location

//Prerequisites
module identity '../../user-managed-identity/main.bicep' = {
  name: 'user-managed-identity'
  params: {
    resourceName: resourceName
    location: location
  }
}

module kv '../../azure-keyvault/main.bicep' = {
  name: 'azure_keyvault'
  params: {
    resourceName: resourceName
    location: location
    secretsObject: { secrets: [] }

    // Add Role Assignment
     roleAssignments: [
      {
        roleDefinitionIdOrName: 'Key Vault Administrator'
        principals: [
          {
            id: identity.outputs.principalId
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Test with new managed identity
module test0 '../main.bicep' = {
  name: 'test0-${uniqueString(resourceName)}'
  params: {
    kvName: kv.outputs.name
    location: location
    sshKeyName: 'first-key'
  }
}

// Test with existing managed identity
module test1 '../main.bicep' = {
  dependsOn: [
    test0
  ]
  name: 'test1-${uniqueString(resourceName)}'
  params: {
    kvName: kv.outputs.name
    location: location
    sshKeyName: 'second-key'
    existingManagedIdentityResourceGroupName: resourceGroup().name
    useExistingManagedIdentity: true
    managedIdentityName: identity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
  }
}
