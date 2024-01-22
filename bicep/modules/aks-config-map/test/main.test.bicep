/*

Forcing a RBAC refresh
Azure Resource Manager sometimes caches configurations and data to improve performance.
When you assign roles or remove role assignments, it can take up to 30 minutes for changes to take effect.
If you are using ...Azure CLI, you can force a refresh of your role assignment changes by signing out and signing in.
*/

param location string = resourceGroup().location
param aksName string =  'crtest${uniqueString(newGuid())}'

//RBAC RoleId vars
var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

//Prerequisites
module prereq 'prereq.test.bicep' = {
  name: 'test-prereqs'
  params: {
    location: location
    aksName: aksName
  }
}

//Test 1. Simple Config Map
module test1 '../main.bicep' = {
  name: 'configmap'
  params: {
    aksName: prereq.outputs.aksName
    location: location
    name: 'test1'
    namespace: 'default'
    propertyData: [
      'hello=world'
      'hola=mundo'
    ]
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
  }
}

//Test 2. Complex Config Map
module test2 '../main.bicep' = {
  name: 'configmap2'
  params: {
    aksName: prereq.outputs.aksName
    location: location
    name: 'test2'
    namespace: 'default'
    propertyData: [
      'azure=enabled'
    ]
    fileData: [
      'azureWorkloadIdentity: |tenantId=${subscription().tenantId}\nsubscriptionId=${subscription().subscriptionId}'
      'serviceAccount: |create: true\nname: ""'
    ]
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
  }
}

var configMapTemplate = '''
values.yaml: |
  azure:
    enabled: false
  azureWorkloadIdentity:
    tenantId: "{0}"
    clientId: "{1}"
  serviceAccount:
    create: true
    name: ""
'''

//Test 3. Config Map to use as helm values
module test3 '../main.bicep' = {
  name: 'configmap3'
  params: {
    aksName: prereq.outputs.aksName
    location: location
    name: 'test3'
    namespace: 'default'  
    fileData: [
      format(configMapTemplate, subscription().tenantId, guid('guid'))
    ]
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
  }
}
