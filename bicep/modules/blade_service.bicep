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
param clusterIngress string

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string

@minLength(9)
@maxLength(18)
@description('The address range to use for the docker bridge')
param dockerBridgeCidr string

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

@description('Feature Flag to Load Software.')
param enableSoftwareLoad bool

@description('Feature Flag to Enable Managed Observability.')
param enableMonitoring bool = false

param appSettings appConfigItem[]

/////////////////////////////////
// Configuration 
/////////////////////////////////

var serviceLayerConfig = {
  // name: 'service'
  // displayName: 'Service Resources'
  cluster: {
    aksVersion: '1.28'
    meshVersion: 'asm-1-19'
    networkPlugin: networkPlugin
  }
  gitops: {
    name: 'flux-system'
    url: softwareRepository == '' ? 'https://github.com/azure/osdu-developer' : softwareRepository
    branch: softwareBranch == '' ? '' : softwareBranch
    tag: softwareTag == '' && softwareBranch == '' ? 'v0.7.0' : softwareTag
    components: './stamp/components'
    applications: './stamp/applications'
  }
  imageList: {
    None: []
    M22: [
      'community.opengroup.org:5555/osdu/platform/system/partition/partition-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/security-and-compliance/entitlements/entitlements-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/legal-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/system/schema-service/schema-service-release-0-24:latest'
      'community.opengroup.org:5555/osdu/platform/system/storage/storage-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/system/file/file-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/system/indexer-service/indexer-service-v0-24-0:latest'
      'community.opengroup.org:5555/osdu/platform/system/search-service/search-service-v0-24-0:latest'
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
    tags: {
      layer: bladeConfig.displayName
    }

    // Configure Linking Items
    aksSubnetId: aksSubnetId
    aksPodSubnetId: podSubnetId == '' ? null : podSubnetId
    identityId: identityId
    workspaceId: workspaceResourceId

    // Configure VNET Injection
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP
    dockerBridgeCidr: dockerBridgeCidr

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
    agentCount: 2
    agentCountMax: 4
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
    agentCount: 2
    agentCountMax: 4
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
    agentCount: 2
    agentCountMax: 4
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


/////////////////
// Workload Identity Federated Credentials 
/////////////////
module appIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.0' = {
  name: '${bladeConfig.sectionName}-user-managed-identity'
  params: {
    // Required parameters
    name: 'id-${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    enableTelemetry: enableTelemetry

    // Only support 1.  https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-considerations#concurrent-updates-arent-supported-user-assigned-managed-identities
    federatedIdentityCredentials: [{
      audiences: [
        'api://AzureADTokenExchange'
      ]
      issuer: cluster.outputs.aksOidcIssuerUrl
      name: 'federated-ns_default'
      subject: 'system:serviceaccount:default:workload-identity-sa'
    }]

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

resource keySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'app-dev-sp-username'
  parent: keyVault

  properties: {
    value: appIdentity.outputs.clientId
  }
}

module federatedCredsOsduAzure './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_osdu-core'
  params: {
    name: 'federated-ns_osdu-core'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.outputs.name
    subject: 'system:serviceaccount:osdu-core:workload-identity-sa'
  }
  dependsOn: [
    appIdentity
  ]
}

// Federated Credentials have to be sequentially added.  Ensure depends on.
module federatedCredsDevSample './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_dev-sample'
  params: {
    name: 'federated-ns_dev-sample'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.outputs.name
    subject: 'system:serviceaccount:dev-sample:workload-identity-sa'
  }
  dependsOn: [
    federatedCredsOsduAzure
  ]
}

module federatedCredsConfigMaps './federated_identity.bicep' = {
  name: '${bladeConfig.sectionName}-federated-cred-ns_config-maps'
  params: {
    name: 'federated-ns_azappconfig-system'
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.aksOidcIssuerUrl
    userAssignedIdentityName: appIdentity.outputs.name
    subject: 'system:serviceaccount:azappconfig-system:az-appconfig-k8s-provider'
  }
  dependsOn: [
    federatedCredsDevSample
  ]
}

module appRoleAssignments './app_assignments.bicep' = {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac'
  params: {
    identityprincipalId: appIdentity.outputs.principalId
    kvName: kvName
    storageName: storageName
  }
  dependsOn: [
    federatedCredsConfigMaps
  ]
}

module appRoleAssignments2 './app_assignments.bicep' = [for (name, index) in partitionStorageNames: {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac-${name}'
  params: {
    identityprincipalId: appIdentity.outputs.principalId
    storageName: name
  }
  dependsOn: [
    federatedCredsDevSample
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

var settings = [
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
    value: appIdentity.outputs.clientId
    contentType: 'text/plain'
    label: 'configmap-services'
  }
  {
    name: 'keyvault_uri'
    value: keyVault.properties.vaultUri
    contentType: 'text/plain'
    label: 'configmap-services'
  }
]

module app_config './app-configuration/main.bicep' = {
  name: '${bladeConfig.sectionName}-appconfig'
  params: {
    resourceName: bladeConfig.sectionName
    location: location
    tags: {
      layer: bladeConfig.displayName
    }

    // Add Role Assignment
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'App Configuration Data Reader'
        principalIds: [
          appIdentity.outputs.principalId
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Add Configuration
    keyValues: concat(union(appSettings, settings))
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
  '''
}

module appConfigMap './aks-config-map/main.bicep' = {
  name: '${bladeConfig.sectionName}-cluster-appconfig-configmap'
  params: {
    aksName: cluster.outputs.aksClusterName
    location: location
    name: 'config-map-values'
    namespace: 'default'
    
    // newOrExistingManagedIdentity: 'existing'
    // managedIdentityName: managedIdentityName
    // existingManagedIdentitySubId: subscription().subscriptionId
    // existingManagedIdentityResourceGroupName:resourceGroup().name

    // Order of items matters here.
    fileData: [
      format(configMaps.appConfigTemplate, 
             subscription().tenantId, 
             appIdentity.outputs.clientId,
             app_config.outputs.endpoint,
             kvUri,
             kvName)
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
module fluxConfiguration 'br/public:avm/res/kubernetes-configuration/flux-configuration:0.3.1' = if(enableSoftwareLoad) {
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
    tags: {
      layer: bladeConfig.displayName
    }

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
    tags: {
      layer: bladeConfig.displayName
    }

    skuName: 'Standard'
    apiKey: 'Enabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    deterministicOutboundIP: 'Disabled'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    prometheusName: prometheus.outputs.name
    // userId: userId

  }
}
