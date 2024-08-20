/////////////////
// Service Blade 
/////////////////
// import * as type from 'types.bicep'

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

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('The tags to apply to the resources')
param tags object = {}

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

param networkPlugin string

param clusterSize string

@description('The name of the Key Vault where the secret exists')
param kvName string 

@description('The Uri of the Key Vault where the secret exists')
param kvUri string 

@description('The name of the Storage Account')
param storageName string 

@description('Specify the User Email.')
param emailAddress string

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Specify the AD Application Principal Id.')
param applicationClientPrincipalOid string = ''

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
])
@description('The Cluster Ingress Mode')
param clusterIngress string = 'External'

@description('Feature Flag to Load Software.')
param enableSoftwareLoad bool

@description('Feature Flag to Load OSDU Core.')
param enableOsduCore bool = true

@description('Feature Flag to Load OSDU Reference.')
param enableOsdureference bool = true

@allowed([
  'release-0-24'
  'release-0-25'
  'release-0-26'
  'release-0-27'
  'master'
])
@description('Specify the OSDU version.')
param osduVersion string = 'release-0-27'

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string


@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string


param aksSubnetId string

param podSubnetId string = ''

@description('The managed identity name for deployment scripts')
param managedIdentityName string

@description('The user managed identity for the cluster.')
param identityId string

@description('The name of the partition storage accounts')
param partitionStorageNames string[]

@description('The name of the partition service bus namespaces')
param partitionServiceBusNames string[]



@description('Feature Flag to Enable Managed Observability.')
param enableMonitoring bool = false

param appSettings appConfigItem[]

param dateStamp string = utcNow()

/////////////////////////////////
// Configuration 
/////////////////////////////////

var version = loadJsonContent('../../version.json')

var serviceLayerConfig = {
  registry: {
    sku: 'Basic'
  }
  cluster: {
    aksVersion: '1.30'
    meshVersion: 'asm-1-22'
    networkPlugin: networkPlugin
  }
  gitops: {
    name: 'flux-system'
    url: softwareRepository == '' ? 'https://github.com/azure/osdu-developer' : softwareRepository
    branch: softwareBranch == '' ? '' : softwareBranch
    tag: softwareTag == '' && softwareBranch == '' ? version.release : softwareTag
    components: './stamp/components'
    applications: './stamp/applications'
  }
}

/////////////////////////////////
// Existing Resources
/////////////////////////////////

resource appIdentity  'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

resource keySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'app-dev-sp-username'
  parent: keyVault

  properties: {
    value: applicationClientId
  }
}

/*
.______       _______   _______  __       _______.___________..______     ____    ____ 
|   _  \     |   ____| /  _____||  |     /       |           ||   _  \    \   \  /   / 
|  |_)  |    |  |__   |  |  __  |  |    |   (----`---|  |----`|  |_)  |    \   \/   /  
|      /     |   __|  |  | |_ | |  |     \   \       |  |     |      /      \_    _/   
|  |\  \----.|  |____ |  |__| | |  | .----)   |      |  |     |  |\  \----.   |  |     
| _| `._____||_______| \______| |__| |_______/       |__|     | _| `._____|   |__|                                                                                                                              
*/



module registry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: '${bladeConfig.sectionName}-container-registry'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    enableTelemetry: enableTelemetry

    // Hook up Diagnostics
    diagnosticSettings: [
      {
        workspaceResourceId: workspaceResourceId
      }
    ]

    // Configure Service
    acrSku: serviceLayerConfig.registry.sku

    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        appIdentity.id
      ]
    }

    // Add Role Assignment
    roleAssignments: [
      {
        principalId: appIdentity.properties.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'AcrPull'
      }
    ]
  }
}


/*  -
 __  ___  __    __  .______    _______ .______      .__   __.  _______ .___________. _______     _______.
|  |/  / |  |  |  | |   _  \  |   ____||   _  \     |  \ |  | |   ____||           ||   ____|   /       |
|  '  /  |  |  |  | |  |_)  | |  |__   |  |_)  |    |   \|  | |  |__   `---|  |----`|  |__     |   (----`
|    <   |  |  |  | |   _  <  |   __|  |      /     |  . `  | |   __|      |  |     |   __|     \   \    
|  .  \  |  `--'  | |  |_)  | |  |____ |  |\  \----.|  |\   | |  |____     |  |     |  |____.----)   |   
|__|\__\  \______/  |______/  |_______|| _| `._____||__| \__| |_______|    |__|     |_______|_______/    
*/

// This is used to help determine what the default subnet should be for the Pods if vnet injected is enabled
// var defaultPodSubnetId = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${podSubnetName}' : '${network.outputs.resourceId}/subnets/${podSubnetName}'

module cluster './aks_cluster.bicep' = {
  name: '${bladeConfig.sectionName}-aks-cluster'
  params: {
    // Basic Details
    resourceName: bladeConfig.sectionName
    location: location
    aksVersion: serviceLayerConfig.cluster.aksVersion
    aad_tenant_id: subscription().tenantId
    clusterSize: clusterSize
    networkPlugin: serviceLayerConfig.cluster.networkPlugin

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    // Configure Linking Items
    aksSubnetId: aksSubnetId
    aksPodSubnetId: podSubnetId == '' ? null : podSubnetId
    identityId: identityId
    workspaceId: workspaceResourceId

    // Configure VNET Injection
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP

    // Configure Istio
    serviceMeshProfile: enableMonitoring ? 'Istio' : null
    istioRevision: enableMonitoring ? serviceLayerConfig.cluster.meshVersion : null
    istioIngressGatewayMode: enableMonitoring ? clusterIngress : null

    // Configure Add Ons
    enable_aad: empty(clusterAdminIds) == true ? false : true
    admin_ids: clusterAdminIds
    workloadIdentityEnabled: true
    oidcIssuer: true
    keyvaultEnabled: true
    fluxGitOpsAddon: true
    enableImageCleaner: true
    fileCSIDriver: true
    blobCSIDriver: true
    azurepolicy: 'audit'
  }
}



/////////////////
// Elastic Configuration 
/////////////////
var elasticPoolPresets = {
  // 4 vCPU, 15 GiB RAM, 28 GiB SSD, (12800) IOPS, Ephemeral OS Disk
  CostOptimised : {
    vmSize: 'Standard_DS3_v2'
  }
  // 8 vCPU, 28 GiB RAM, 56 GiB SSD, (32000) IOPS, Ephemeral OS Disk
  Standard : {
    vmSize: 'Standard_DS4_v2'
  }
  // 16 vCPU, 56 GiB RAM, 112 GiB SSD, (64000) IOPS, Ephemeral OS Disk
  HighSpec : {
    vmSize: 'Standard_DS5_v2'
  }
}

module pool1 './aks_agent_pool.bicep' = {
  name: '${bladeConfig.sectionName}-pool1'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'poolz1'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 1
    agentCountMax: 3
    availabilityZones: [
      '1'
    ]
    subnetId: aksSubnetId
    podSubnetId: podSubnetId
    nodeTaints: ['app=cluster:NoSchedule']
    nodeLabels: {
      app: 'cluster'
    }
  }
}

module pool2 './aks_agent_pool.bicep' = {
  name: '${bladeConfig.sectionName}-pool2'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'poolz2'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 1
    agentCountMax: 3
    availabilityZones: [
      '2'
    ]
    subnetId: aksSubnetId
    podSubnetId: podSubnetId
    nodeTaints: ['app=cluster:NoSchedule']
    nodeLabels: {
      app: 'cluster'
    }
  }
}

module pool3 './aks_agent_pool.bicep' = {
  name: '${bladeConfig.sectionName}-pool3'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'poolz3'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 1
    agentCountMax: 3
    availabilityZones: [
      '3'
    ]
    subnetId: aksSubnetId
    podSubnetId: podSubnetId
    nodeTaints: ['app=cluster:NoSchedule']
    nodeLabels: {
      app: 'cluster'
    }
  }
}



// Federated Credentials have to be sequentially added.  Ensure depends on to do sequentially.
module federatedCredsDefaultNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_default'
  params: {
    name: 'federated-ns_default'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:default:workload-identity-sa'
  }
  dependsOn: [
    cluster
  ]
}

module federatedCredsOsduCoreNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-core'
  params: {
    name: 'federated-ns_osdu-core'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:osdu-core:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsDefaultNamespace
  ]
}

module federatedCredsOduInitNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-init'
  params: {
    name: 'federated-ns_osdu-init'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:osdu-init:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsOsduCoreNamespace
  ]
}

module federatedCredsDevSampleNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_dev-sample'
  params: {
    name: 'federated-ns_dev-sample'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:dev-sample:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsOduInitNamespace
  ]
}

module federatedCredsConfigMapsNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_config-maps'
  params: {
    name: 'federated-ns_azappconfig-system'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:azappconfig-system:az-appconfig-k8s-provider'
  }
  dependsOn: [
    federatedCredsDevSampleNamespace
  ]
}

module federatedCredsOsduSystem './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-system'
  params: {
    name: 'federated-ns_osdu-system'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:osdu-system:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsConfigMapsNamespace
  ]
}

module federatedCredsElasticNamespace './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_elastic-search'
  params: {
    name: 'federated-ns_elastic-search'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:elastic-search:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsOsduSystem
  ]
}

module federatedCredsOsduAuth './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-auth'
  params: {
    name: 'federated-ns_osdu-auth'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:osdu-auth:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsElasticNamespace
  ]
}

module federatedCredsOsduReference './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-reference'
  params: {
    name: 'federated-ns_osdu-reference'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: 'system:serviceaccount:osdu-reference:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsOsduAuth
  ]
}



module appRoleAssignments './app_assignments.bicep' = {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac'
  params: {
    identityprincipalId: appIdentity.properties.principalId
    kvName: kvName
    storageName: storageName
  }
  dependsOn: [
    federatedCredsDefaultNamespace
    federatedCredsOsduCoreNamespace
    federatedCredsOduInitNamespace
    federatedCredsDevSampleNamespace
    federatedCredsConfigMapsNamespace
    federatedCredsElasticNamespace
    federatedCredsOsduSystem
    federatedCredsOsduAuth
    federatedCredsOsduReference
  ]
}

module appRoleAssignments2 './app_assignments.bicep' = [for (name, index) in partitionStorageNames: {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac-${name}'
  params: {
    identityprincipalId: appIdentity.properties.principalId
    storageName: name
  }
  dependsOn: [
    federatedCredsDefaultNamespace
    federatedCredsOsduCoreNamespace
    federatedCredsOsduReference
    federatedCredsDevSampleNamespace
    federatedCredsConfigMapsNamespace
  ]
}]

/////////////////
// Helm Charts 
/////////////////
module helmAppConfigProvider './aks-run-command/main.bicep' = {
  name: '${bladeConfig.sectionName}-helm-appconfig-provider'
  params: {
    aksName: cluster.outputs.aksClusterName
    location: location

    newOrExistingManagedIdentity: 'existing'
    managedIdentityName: managedIdentityName
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    commands: [
      'helm install azureappconfiguration.kubernetesprovider oci://mcr.microsoft.com/azure-app-configuration/helmchart/kubernetes-provider --namespace azappconfig-system --create-namespace'
    ]
  }
}



/*
     ___      .______   .______     ______   ______   .__   __.  _______  __    _______
    /   \     |   _  \  |   _  \   /      | /  __  \  |  \ |  | |   ____||  |  /  _____|
   /  ^  \    |  |_)  | |  |_)  | |  ,----'|  |  |  | |   \|  | |  |__   |  | |  |  __
  /  /_\  \   |   ___/  |   ___/  |  |     |  |  |  | |  . `  | |   __|  |  | |  | |_ |
 /  _____  \  |  |      |  |      |  `----.|  `--'  | |  |\   | |  |     |  | |  |__| |
/__/     \__\ | _|      | _|       \______| \______/  |__| \__| |__|     |__|  \______|
*/

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
    value: string(enableOsduCore)
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
  {
    name: 'osduReferenceEnabled'
    value: string(enableOsdureference)
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
  {
    name: 'osduVersion'
    value: string(osduVersion)
    contentType: 'text/plain'
    label: 'configmap-osdu-applications'
  }
]

var settings = [
  {
    name: 'refresh'
    value: dateStamp
    contentType: 'text/plain'
    label: 'configmap'
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
    keyValues: concat(union(appSettings, settings, partitionStorageSettings, partitionBusSettings, osdu_applications, common_helm_values))
  }
  dependsOn: [
    appRoleAssignments
    appRoleAssignments2
  ]
}

@description('The name of the azure keyvault.')
output ENV_CONFIG_ENDPOINT string = app_config.outputs.endpoint

//--------------Config Map---------------
// SecretProviderClass --> tenantId, clientId, keyvaultName
// ServiceAccount --> tenantId, clientId
// AzureAppConfigurationProvider --> tenantId, clientId, configEndpoint, keyvaultUri
var configMaps = {
  appConfigTemplate: '''
values.yaml: |
  serviceAccount:
    create: false
    name: "workload-identity-sa"
  azure:
    tenantId: {0}
    clientId: {1}
    configEndpoint: {2}
    keyvaultUri: {3}
    keyvaultName: {4}
    appId: {5}
    appOid: {6}
  ingress:
    internalGateway:
      enabled: {7}
    externalGateway:
      enabled: {8}
  '''
}

module appConfigMap './aks-config-map/main.bicep' = {
  name: '${bladeConfig.sectionName}-cluster-appconfig-configmap'
  params: {
    aksName: cluster.outputs.aksClusterName
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
             applicationClientId,
             applicationClientPrincipalOid,
             clusterIngress == 'Internal' || clusterIngress == 'Both' ? 'true' : 'false',
             clusterIngress == 'External' || clusterIngress == 'Both' ? 'true' : 'false')
    ]
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
    namespace: cluster.outputs.fluxReleaseNamespace
    clusterName: cluster.outputs.aksClusterName
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
    kustomizations: {
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
    pool1
    pool2
    pool3
  ]
}


/*
.___  ___.   ______   .__   __.  __  .___________.  ______   .______      
|   \/   |  /  __  \  |  \ |  | |  | |           | /  __  \  |   _  \     
|  \  /  | |  |  |  | |   \|  | |  | `---|  |----`|  |  |  | |  |_)  |    
|  |\/|  | |  |  |  | |  . `  | |  |     |  |     |  |  |  | |      /     
|  |  |  | |  `--'  | |  |\   | |  |     |  |     |  `--'  | |  |\  \----.
|__|  |__|  \______/  |__| \__| |__|     |__|      \______/  | _| `._____|
*/

var name = 'amw${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'

module prometheus 'aks_prometheus.bicep' = if(enableMonitoring) {
  name: '${bladeConfig.sectionName}-managed-prometheus'
  params: {
    // Basic Details
    name: length(name) > 23 ? substring(name, 0, 23) : name
    location: location
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    publicNetworkAccess: 'Enabled'    
    clusterName: cluster.outputs.aksClusterName
    actionGroupId: ''
  }
}

module grafana 'aks_grafana.bicep' = if(enableMonitoring){
  name: '${bladeConfig.sectionName}-managed-grafana'
  params: {
    // Basic Details
    name: length(name) > 23 ? substring(name, 0, 23) : name
    location: location
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    skuName: 'Standard'
    apiKey: 'Enabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    deterministicOutboundIP: 'Disabled'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    prometheusName: prometheus.outputs.name
  }
}

@description('The name of the container registry.')
output registryName string = registry.outputs.name

@description('The name of the container registry.')
output appConfigName string = app_config.outputs.name

@description('The name of the cluster.')
output clusterName string = cluster.outputs.aksClusterName
