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

//Test 1. Just a single certificate
module kvCertSingle '../main.bicep' = {
  name: 'kvCertSingle'
  params: {
    kvName: kv.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: identity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    certificateNames: [ 'mysingleapp' ]
    certificateCommonNames: [ 'mysingleapp.mydomain.local' ]
    validity: 11
    disabled: true
  }
}
output singleSecretId string = kvCertSingle.outputs.certificateSecretIds[0][0]
output singleThumbprint string = kvCertSingle.outputs.certificateThumbprintHexs[0][0]

//Test 2. Array of certificates
var certificateNames = [
  'myapp'
  'myotherapp'
]

module kvCertMultiple '../main.bicep' = {
  name: 'kvCertMultiple-${uniqueString(kv.name)}'
  params: {
    kvName: kv.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: identity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    certificateNames: certificateNames
    initialScriptDelay: '0'
    validity: 24
  }
}

// Test 3. Test a signed cert
// module akvCertSigned '../main.bicep' = {
//   name: 'akvCertSigned'
//   params: {
//     akvName: akv.name
//     location: location
//     certificateName: 'mysignedcert'
//     certificateCommonName: 'sample-cert.gaming.azure.com'
//     issuerName: 'Signed'
//     issuerProvider: 'OneCertV2-PublicCA'
//   }
// }

@description('Array of info from each Certificate')
output createdCertificates array = [for (certificateName, i) in certificateNames: {
  certificateName: certificateName
  certificateSecretId: kvCertMultiple.outputs.certificateSecretIds[i]
  certificateThumbprint: kvCertMultiple.outputs.certificateThumbprintHexs[i]
}]
