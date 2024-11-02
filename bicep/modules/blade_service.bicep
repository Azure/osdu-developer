/////////////////
// Service Blade 
/////////////////

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

@description('A Custom VM Size for Internal Pool')
param vmSize string

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

@allowed([
  'Intel'
  'ARM'
])
@description('Specify the server type.')
param serverType string = 'ARM'

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string


@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string

@description('The id of the subnet to deploy the AKS nodes')
param aksSubnetId string

@description('The id of the subnet to deploy AKS pods')
param podSubnetId string = ''

@description('The managed identity name for deployment scripts')
param managedIdentityName string

@description('The user managed identity for the cluster.')
param identityId string

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
    tier: 'Standard'
    aksVersion: '1.30'
    meshVersion: 'asm-1-22'

    // D2pds v5 with 2 vCPUs and 8 GiB of memory. Available in 22 regions starting from $44.09 per month.
    // D4pds v5 with 4 vCPUs and 16 GiB of memory. Available in 22 regions starting from $88.18 per month.
    // D2s_v5 with 2 vCPUs and 8 GiB of memory. Available in 50 regions starting from $70.08 per month.
    // D4s_v5 with 4 vCPUs and 16 GiB of memory. Available in 50 regions starting from $140.16 per month.
    vmSize: serverType == 'Intel' ? 'Standard_D4s_v5' : 'Standard_D4pds_v5'  // Choose between Intel (D4s_v5 - 4 vCPUs/16GB) or ARM (D4pds_v5)
    poolSize: serverType == 'Intel' ? 'Standard_D2s_v5' : 'Standard_D2pds_v5'  // Choose between Intel (D2s_v5 - 2 vCPUs/8GB) or ARM (D2pds_v5)
  }
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

module cluster './managed-cluster/main.bicep' = {
  name: '${bladeConfig.sectionName}-aks-cluster'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    skuTier: serviceLayerConfig.cluster.tier
    kubernetesVersion: serviceLayerConfig.cluster.aksVersion

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

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Azure Kubernetes Service RBAC Cluster Admin'
        principalId: appIdentity.properties.principalId
        principalType: 'ServicePrincipal'
      }
      // Role Assignment required for different extensions.
      {
        roleDefinitionIdOrName: 'Kubernetes Agentless Operator'
        principalId: appIdentity.properties.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    aksServicePrincipalProfile: {
      clientId: 'msi'
    }
    managedIdentities: {
      systemAssigned: false  
      userAssignedResourcesIds: [
        identityId
      ]
    }

    // Network Settings
    networkPlugin: 'azure'
    networkPluginMode: empty(podSubnetId) ? 'overlay' : null
    networkDataplane: 'cilium'
    publicNetworkAccess: 'Enabled'
    outboundType: empty(aksSubnetId) ? 'managedNATGateway' : 'loadBalancer'
    enablePrivateCluster: false

    // Access Settings
    disableLocalAccounts: true
    enableRBAC: true
    aadProfileManaged: true
    nodeResourceGroupLockDown: true

    // Observability Settings
    enableAzureDefender: true
    enableContainerInsights: true
    monitoringWorkspaceId: workspaceResourceId
    enableAzureMonitorProfileMetrics: true
    costAnalysisEnabled: true

    // Ingress Settings
    webApplicationRoutingEnabled: false
    openServiceMeshEnabled: false

    // Configure VNET Injection
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP

    // Plugin Software
    enableStorageProfileDiskCSIDriver: true
    enableStorageProfileFileCSIDriver: true
    enableStorageProfileSnapshotController: true
    enableStorageProfileBlobCSIDriver: true    
    enableKeyvaultSecretsProvider: true
    enableSecretRotation: true
    enableImageCleaner: true
    imageCleanerIntervalHours: 168
    enableOidcIssuerProfile: true
    enableWorkloadIdentity: true
    azurePolicyEnabled: true
    omsAgentEnabled: true

    // Auto-Scaling
    vpaAddon: true
    kedaAddon: true
    enableNodeAutoProvisioning: false
    
    maintenanceConfiguration: {
      maintenanceWindow: {
        schedule: {
          daily: null
          weekly: {
            intervalWeeks: 1
            dayOfWeek: 'Sunday'
          }
          absoluteMonthly: null
          relativeMonthly: null
        }
        durationHours: 4
        utcOffset: '+00:00'
        startDate: '2024-10-01'
        startTime: '00:00'
      }
    }

    primaryAgentPoolProfile: [
      {
        name: 'system'
        mode: 'System'
        vmSize: empty(vmSize) ? serviceLayerConfig.cluster.vmSize : vmSize
        enableAutoScaling: true
        minCount: 2
        maxCount: 6
        securityProfile: {
          sshAccess: 'Disabled'
        }
        osType: 'Linux'
        osSKU: 'AzureLinux'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
        podSubnetId: !empty(podSubnetId) ? podSubnetId : null
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
    ]

    // Additional Agent Pool Configurations
    agentPools: [
      {
        name: 'default'
        mode: 'User'
        vmSize: empty(vmSize) ? serviceLayerConfig.cluster.vmSize : vmSize
        enableAutoScaling: true
        minCount: 4
        maxCount: 20
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
        podSubnetId: !empty(podSubnetId) ? podSubnetId : null
      }
      {
        name: 'poolz1'
        mode: 'User'
        vmSize: empty(vmSize) ? serviceLayerConfig.cluster.poolSize : vmSize
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '1'
        ]
        vnetSubnetID: aksSubnetId
        podSubnetId: podSubnetId
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
      {
        name: 'poolz2'
        mode: 'User'
        vmSize: empty(vmSize) ? serviceLayerConfig.cluster.poolSize : vmSize
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '2'
        ]
        vnetSubnetID: aksSubnetId
        podSubnetId: podSubnetId
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
      {
        name: 'poolz3'
        mode: 'User'
        vmSize: empty(vmSize) ? serviceLayerConfig.cluster.poolSize : vmSize
        enableAutoScaling: true
        minCount: 1
        maxCount: 3
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '3'
        ]
        vnetSubnetID: aksSubnetId
        podSubnetId: podSubnetId
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
    ]

  }
}

// Policy Assignments custom module to apply the policies to the cluster.
module policy './managed-cluster/aks_policy.bicep' = {
  name: '${bladeConfig.sectionName}-aks-policy'
  params: {
    clusterName: cluster.outputs.name
  }
  dependsOn: [
    cluster
  ]
}

// AKS Extensions custom module to apply the app config provider extension to the cluster.
module appConfigExtension './managed-cluster/aks_appconfig_extension.bicep' = {
  name: '${bladeConfig.sectionName}-aks-extension-appconfig'
  params: {
    clusterName: cluster.outputs.name
  }
  dependsOn: [
    cluster
  ]
}

// AVM doesn't support output of the principalId from the extension module so we have to use a deployment script to get it.
module fluxExtension './flux-extension/main.bicep' = {
  name: '${bladeConfig.sectionName}-flux-extension'
  params: {
    clusterName: cluster.outputs.name
    location: location
    extensionType: 'microsoft.flux'
    name: 'flux'    
    releaseNamespace: 'flux-system'
    releaseTrain: 'Stable'

    configurationSettings: {
      'multiTenancy.enforce': 'false'
      'helm-controller.enabled': 'true'
      'source-controller.enabled': 'true'
      'kustomize-controller.enabled': 'true'
      'notification-controller.enabled': 'true'
      'image-automation-controller.enabled': 'false'
      'image-reflector-controller.enabled': 'false'
    }
  }
}

module extensionClientId 'br/public:avm/res/resources/deployment-script:0.4.0' = if (serviceLayerConfig.gitops.enablePrivateSoftware) {
  name: '${bladeConfig.sectionName}-script-clientId'
  
  params: {
    kind: 'AzureCLI'
    name: 'aksExtensionClientId'
    azCliVersion: '2.63.0'
    location: location
    managedIdentities: {
      userAssignedResourcesIds: [
        appIdentity.id
      ]
    }

    environmentVariables: [
      {
        name: 'rgName'
        value: '${resourceGroup().name}_aks_${cluster.outputs.name}_nodes'
      }
      {
        name: 'principalId'
        value: fluxExtension.outputs.principalId
      }
    ]
    
    timeout: 'PT30M'
    retentionInterval: 'PT1H'

    scriptContent: '''
      az login --identity

      echo "Looking up client ID for $principalId in ResourceGroup $rgName"
      clientId=$(az identity list --resource-group $rgName --query "[?principalId=='$principalId'] | [0].clientId" -otsv)
      
      echo "Found ClientId: $clientId"
      echo "{\"clientId\":\"$clientId\"}" | jq -c '.' > $AZ_SCRIPTS_OUTPUT_PATH
    '''
  }
  dependsOn: [
    fluxExtension
  ]
}

/////////////////
// Federated
/////////////////
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

@batchSize(1)
module federatedCredentials './federated_identity.bicep' = [for (cred, index) in federatedIdentityCredentials: {
  name: '${bladeConfig.sectionName}-${cred.name}'
  params: {
    name: cred.name
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: cluster.outputs.oidcIssuerUrl
    userAssignedIdentityName: appIdentity.name
    subject: cred.subject
  }
  dependsOn: [
    cluster
  ]
}]

module appRoleAssignments './app_assignments.bicep' = {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac'
  params: {
    identityprincipalId: appIdentity.properties.principalId
    kvName: kvName
    storageName: storageName
  }
  dependsOn: [
    federatedCredentials
  ]
}

module appRoleAssignments2 './app_assignments.bicep' = [for (name, index) in partitionStorageNames: {
  name: '${bladeConfig.sectionName}-user-managed-identity-rbac-${name}'
  params: {
    identityprincipalId: appIdentity.properties.principalId
    storageName: name
  }
  dependsOn: [
    federatedCredentials
  ]
}]


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
    aksName: cluster.outputs.name
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
    namespace: 'flux-system'
    clusterName: cluster.outputs.name
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


@description('The name of the container registry.')
output registryName string = registry.outputs.name

@description('The name of the container registry.')
output appConfigName string = app_config.outputs.name

@description('The name of the cluster.')
output clusterName string = cluster.outputs.name



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
