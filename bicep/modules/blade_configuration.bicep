/////////////////
// Configuration Blade
/////////////////

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('The tags to apply to the resources')
param tags object = {}

@description('The unique identifier for the deployment')
param dnsName string

@description('The name of the Key Vault where the secret exists')
param kvName string

@description('The Uri of the Key Vault where the secret exists')
param kvUri string

@description('The name of the cluster.')
param clusterName string

@description('The OIDC Issuer URL for the cluster.')
param oidcIssuerUrl string

@description('Specify the User Email.')
param emailAddress string

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Specify the AD Application Principal Id.')
param applicationClientPrincipalOid string = ''

@description('Specify the Application Insights Key.')
param appInsightsKey string

@description('Software GIT Repository URL')
param softwareRepository string

@description('Software GIT Repository Branch')
param softwareBranch string

@description('Software GIT Repository Tag')
param softwareTag string = ''

@allowed([
  'Internal'
  'External'
  'Both'
  ''
])
@description('The Cluster Ingress Mode')
param clusterIngress string = 'External'

@description('Feature Flag to Load Software.')
param enableSoftwareLoad bool = true

@description('Feature Flag to Load Experimental Software.')
param enableExperimental bool = true

@description('Feature Flag to Load OSDU Core.')
param enableOsduCore bool = true

@description('Feature Flag to Load OSDU Reference.')
param enableOsdureference bool = true

@description('Feature Flag to Load Admin UI.')
param enableAdminUI bool = true

@allowed([
  'release-0-24'
  'release-0-25'
  'release-0-26'
  'release-0-27'
  'master'
])
@description('Specify the OSDU version.')
param osduVersion string = 'master'

@description('The managed identity name for deployment scripts')
param managedIdentityName string

@description('The name of the system storage account')
param storageAccountName string

@description('The name of the partition storage accounts')
param partitionStorageNames string[]

@description('The name of the partition service bus namespaces')
param partitionServiceBusNames string[]

@allowed([
  'azureBlob'
  'gitRepository'
])
@description('Flux source location for software definition.')
param sourceHost string = 'azureBlob'

@description('App Configuration Settings.')
param appSettings appConfigItem[]

@description('Date Stamp for sentinel value.')
param dateStamp string = utcNow()


/////////////////////////////////
// Existing Resources
/////////////////////////////////

resource appIdentity  'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

resource keySecretSpUsername 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'app-dev-sp-username'
  parent: keyVault

  properties: {
    value: appIdentity.properties.clientId
  }
}

resource keySecretSpPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'app-dev-sp-password'
  parent: keyVault

  properties: {
    value: 'dummy'
  }
}


//--------------Federated Identity---------------
// These are namespaces for federated identities.
var federatedIdentityCredentials = [
  {
    name: 'federated-ns_default'
    subject: 'system:serviceaccount:default:workload-identity-sa'
  }
  {
    name: 'federated-ns_osdu-core'
    subject: 'system:serviceaccount:osdu-core:workload-identity-sa'
  }
  {
    name: 'federated-ns_airflow'
    subject: 'system:serviceaccount:airflow:workload-identity-sa'
  }
  {
    name: 'federated-ns_postgresql'
    subject: 'system:serviceaccount:postgresql:workload-identity-sa'
  }
  {
    name: 'federated-ns_azappconfig-system'
    subject: 'system:serviceaccount:azappconfig-system:az-appconfig-k8s-provider'
  }
  {
    name: 'federated-ns_osdu-system'
    subject: 'system:serviceaccount:osdu-system:workload-identity-sa'
  }
  {
    name: 'federated-ns_elastic-search'
    subject: 'system:serviceaccount:elastic-search:workload-identity-sa'
  }
  {
    name: 'federated-ns_osdu-auth'
    subject: 'system:serviceaccount:osdu-auth:workload-identity-sa'
  }
  {
    name: 'federated-ns_osdu-reference'
    subject: 'system:serviceaccount:osdu-reference:workload-identity-sa'
  }
  {
    name: 'federated-ns_osdu-experimental'
    subject: 'system:serviceaccount:osdu-experimental:workload-identity-sa'
  }
]

/*
 _______  _______  _______   _______ .______          ___   .___________. __    ______   .__   __.
|   ____||   ____||       \ |   ____||   _  \        /   \  |           ||  |  /  __  \  |  \ |  |
|  |__   |  |__   |  .--.  ||  |__   |  |_)  |      /  ^  \ `---|  |----`|  | |  |  |  | |   \|  |
|   __|  |   __|  |  |  |  ||   __|  |      /      /  /_\  \    |  |     |  | |  |  |  | |  . `  |
|  |     |  |____ |  '--'  ||  |____ |  |\  \----./  _____  \   |  |     |  | |  `--'  | |  |\   |
|__|     |_______||_______/ |_______|| _| `._____/__/     \__\  |__|     |__|  \______/  |__| \__|
*/
@batchSize(1)
module federatedCredentials './federated_identity.bicep' = [for (cred, index) in federatedIdentityCredentials: {
  name: '${bladeConfig.sectionName}-${cred.name}'
  params: {
    name: cred.name
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: oidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: cred.subject
  }
}]



//--------------Config Map---------------
// These are common service helm chart values.
var common_helm_values = [
  {
    name: 'AZURE_ISTIOAUTH_ENABLED'
    value: 'true'
    contentType: 'text/plain'
    label: 'configmap-common-values'
  }
  {
    name: 'AZURE_PAAS_PODIDENTITY_ISENABLED'
    value: 'false'
    contentType: 'text/plain'
    label: 'configmap-common-values'
  }
  {
    name: 'AZURE_PAAS_WORKLOADIDENTITY_ISENABLED'
    value: 'true'
    contentType: 'text/plain'
    label: 'configmap-common-values'
  }
  {
    name: 'ACCEPT_HTTP'
    value: 'true'
    contentType: 'text/plain'
    label: 'configmap-common-values'
  }
  {
    name: 'SERVER_PORT'
    value: '80'
    contentType: 'text/plain'
    label: 'configmap-common-values'
  }
]

var osdu_applications = [
  {
    name: 'osduCoreEnabled'
    value: toLower(string(enableOsduCore))
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
  {
    name: 'osduReferenceEnabled'
    value: toLower(string(enableOsdureference))
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
  {
    name: 'adminUIEnabled'
    value: toLower(string(enableAdminUI))
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
  {
    name: 'osduVersion'
    value: toLower(string(osduVersion))
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
]

var airflow_values = [
  // Insights Key and Client Secret come from secrets.
  {
    name: 'tenantId'
    value: subscription().tenantId
    contentType: 'text/plain'
    label: 'configmap-airflow-values'
  }
  {
    name: 'clientId'
    value: applicationClientId
    contentType: 'text/plain'
    label: 'configmap-airflow-values'
  }
  {
    name: 'keyvaultUri'
    value: keyVault.properties.vaultUri
    contentType: 'text/plain'
    label: 'configmap-airflow-values'
  }
]

var settings = [
  {
    name: 'osdu_sentinel'
    value: dateStamp
    label: 'common'
  }
  {
    name: 'Settings:Message'
    value: 'Hello from App Configuration'
    contentType: 'text/plain'
    label: 'configmap-devsample'
  }
  {
    name: 'tenant_id'
    value: subscription().tenantId
    contentType: 'text/plain'
    label: 'configmap-services'
  }
  {
    name: 'azure_msi_client_id'
    value: appIdentity.properties.clientId
    contentType: 'text/plain'
    label: 'configmap-services'
  }
  {
    name: 'keyvault_uri'
    value: keyVault.properties.vaultUri
    contentType: 'text/plain'
    label: 'configmap-services'
  }
  {
    name: 'first_user_id'
    value: emailAddress
    contentType: 'text/plain'
    label: 'configmap-services'
  }
]

var partitionBusSettings = [for (name, i) in partitionServiceBusNames: {
  name: 'partition_servicebus_name_${i}'
  value: name
  contentType: 'text/plain'
  label: 'configmap-services'
}]

var partitionStorageSettings = [for (name, i) in partitionStorageNames: {
  name: 'partition_storage_name_${i}'
  value: name
  contentType: 'text/plain'
  label: 'configmap-services'
}]

/*
     ___      .______   .______     ______   ______   .__   __.  _______  __    _______
    /   \     |   _  \  |   _  \   /      | /  __  \  |  \ |  | |   ____||  |  /  _____|
   /  ^  \    |  |_)  | |  |_)  | |  ,----'|  |  |  | |   \|  | |  |__   |  | |  |  __
  /  /_\  \   |   ___/  |   ___/  |  |     |  |  |  | |  . `  | |   __|  |  | |  | |_ |
 /  _____  \  |  |      |  |      |  `----.|  `--'  | |  |\   | |  |     |  | |  |__| |
/__/     \__\ | _|      | _|       \______| \______/  |__| \__| |__|     |__|  \______|
*/
// AVM Module Customized due for east of settings.
module app_config './app-configuration/main.bicep' = {
  name: '${bladeConfig.sectionName}-appconfig'
  params: {
    resourceName: bladeConfig.sectionName
    location: location
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'App Configuration Data Owner'
        principalIds: [
          appIdentity.properties.principalId
        ]
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: 'Contributor'
        principalIds: [
          appIdentity.properties.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Add Configuration
    keyValues: concat(union(appSettings, settings, partitionStorageSettings, partitionBusSettings, osdu_applications, common_helm_values, airflow_values))
  }
}



//--------------Config Map---------------
// SecretProviderClass --> tenantId, clientId, keyvaultName
// ServiceAccount --> tenantId, clientId
// AzureAppConfigurationProvider --> tenantId, clientId, configEndpoint, keyvaultUri
var configMaps = {
  appConfigTemplate: '''
values.yaml: |
  serviceAccount:
    create: false
    name: workload-identity-sa
  azure:
    tenantId: {0}
    clientId: {1}
    configEndpoint: {2}
    keyvaultUri: {3}
    keyvaultName: {4}
    appInsightsKey: {5}
    appId: {6}
    appOid: {7}
    resourceGroup: {8}
    storageAccountName: {11}
    region: {12}
    dnsName: {13}
  ingress:
    internalGateway:
      enabled: {9}
    externalGateway:
      enabled: {10}
  workloadIdentity:
    clientID: {1}
'''
}

/*
  ______   ______   .__   __.  _______  __    _______ .___  ___.      ___      .______
 /      | /  __  \  |  \ |  | |   ____||  |  /  _____||   \/   |     /   \     |   _  \
|  ,----'|  |  |  | |   \|  | |  |__   |  | |  |  __  |  \  /  |    /  ^  \    |  |_)  |
|  |     |  |  |  | |  . `  | |   __|  |  | |  | |_ | |  |\/|  |   /  /_\  \   |   ___/
|  `----.|  `--'  | |  |\   | |  |     |  | |  |__| | |  |  |  |  /  _____  \  |  |
 \______| \______/  |__| \__| |__|     |__|  \______| |__|  |__| /__/     \__\ | _|
*/
module appConfigMap './aks-config-map/main.bicep' = {
  name: '${bladeConfig.sectionName}-cluster-appconfig-configmap'
  params: {
    aksName: clusterName
    location: location
    name: 'config-map-values'
    namespace: 'default'

    newOrExistingManagedIdentity: 'existing'
    managedIdentityName: managedIdentityName
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    // Order of items matters here.
    fileData: [
      format(configMaps.appConfigTemplate,
             subscription().tenantId,
             appIdentity.properties.clientId,
             app_config.outputs.endpoint,
             kvUri,
             kvName,
             appInsightsKey,
             applicationClientId,
             applicationClientPrincipalOid,
             resourceGroup().name,
             clusterIngress == 'Internal' || clusterIngress == 'Both' ? 'true' : 'false',
             clusterIngress == 'External' || clusterIngress == 'Both' ? 'true' : 'false',
             storageAccountName,
             location,
             dnsName)
    ]
  }
}




//--------------Software Configuration---------------
// These are settings for the software configuration.
var version = loadJsonContent('../../version.json')
var serviceLayerConfig = {
  gitops: {
    name: 'flux-system'
    url: softwareRepository == '' ? 'https://github.com/azure/osdu-developer' : softwareRepository
    branch: softwareBranch == '' ? '' : softwareBranch
    tag: softwareTag == '' && softwareBranch == '' ? version.release : softwareTag
    components: './stamp/components'
    applications: './stamp/applications'
    experimental: './stamp/experimental'
    enablePrivateSoftware: sourceHost == 'azureBlob'
  }
}

/* _______  __  .___________.  ______   .______     _______.
 /  _____||  | |           | /  __  \  |   _  \   /       |
|  |  __  |  | `---|  |----`|  |  |  | |  |_)  | |   (----`
|  | |_ | |  |     |  |     |  |  |  | |   ___/   \   \
|  |__| | |  |     |  |     |  `--'  | |  |   .----)   |
 \______| |__|     |__|      \______/  | _|   |_______/
*/
//--------------Flux Config---------------
module fluxConfiguration 'br/public:avm/res/kubernetes-configuration/flux-configuration:0.3.3' = if(enableSoftwareLoad) {
  name: '${bladeConfig.sectionName}-cluster-gitops'
  params: {
    name: serviceLayerConfig.gitops.name
    location: location
    namespace: 'flux-system'
    clusterName: clusterName
    scope: 'cluster'
    sourceKind: 'GitRepository'
    gitRepository: {
      url: serviceLayerConfig.gitops.url
      timeoutInSeconds: 180
      syncIntervalInSeconds: 300
      repositoryRef: {
        branch: serviceLayerConfig.gitops.branch
        tag: serviceLayerConfig.gitops.tag
      }
    }
    kustomizations: enableExperimental ? {
      components: {
        path: serviceLayerConfig.gitops.components
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
      applications: {
        path: serviceLayerConfig.gitops.applications
        dependsOn: [
          'components'
        ]
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
      experimental: {
        path: serviceLayerConfig.gitops.experimental
        dependsOn: [
          'applications'
        ]
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
    } : {
      components: {
        path: serviceLayerConfig.gitops.components
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
      applications: {
        path: serviceLayerConfig.gitops.applications
        dependsOn: [
          'components'
        ]
        timeoutInSeconds: 300
        syncIntervalInSeconds: 300
        retryIntervalInSeconds: 300
        prune: true
      }
    }
  }
  dependsOn: [
    app_config
    appConfigMap
  ]
}


// =============== //
//   Outputs       //
// =============== //

@description('The name of the azure keyvault.')
output ENV_CONFIG_ENDPOINT string = app_config.outputs.endpoint

@description('The name of the container registry.')
output appConfigName string = app_config.outputs.name


// =============== //
//   Definitions   //
// =============== //

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}

type appConfigItem = {
  @description('The App Configuration Key')
  name: string
  @description('The App Configuration Value')
  value: string
  @description('The App Configuration Content Type')
  contentType: string
  @description('The App Configuration Label')
  label: string
}
