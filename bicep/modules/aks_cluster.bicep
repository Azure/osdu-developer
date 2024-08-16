/*
  This is a custom module that configures Azure Kubernetes Service.

  ** Eventually this might move to Managed-Platform-Modules. **
*/

targetScope = 'resourceGroup'

/*______      ___      .______          ___      .___  ___.  _______ .___________. _______ .______          _______.
|   _  \    /   \     |   _  \        /   \     |   \/   | |   ____||           ||   ____||   _  \        /       |
|  |_)  |  /  ^  \    |  |_)  |      /  ^  \    |  \  /  | |  |__   `---|  |----`|  |__   |  |_)  |      |   (----`
|   ___/  /  /_\  \   |      /      /  /_\  \   |  |\/|  | |   __|      |  |     |   __|  |      /        \   \    
|  |     /  _____  \  |  |\  \----./  _____  \  |  |  |  | |  |____     |  |     |  |____ |  |\  \----.----)   |   
| _|    /__/     \__\ | _| `._____/__/     \__\ |__|  |__| |_______|    |__|     |_______|| _| `._____|_______/    
*/
                                                                                                                   
////////////////////
// Basic Details
////////////////////
@minLength(1)
@maxLength(63)
@description('Used to name all resources')
param resourceName string

@description('Specify the location of the AKS cluster.')
param location string = resourceGroup().location

@description('Tags.')
param tags object = {}

@description('The ID of the Azure AD tenant')
param aad_tenant_id string = ''

@description('The ID of the Azure AD tenant')
param admin_ids array = []

@description('Use the paid sku for SLA rather than SLO')
param skuTierPaid bool = false

@description('Kubernetes Version')
param aksVersion string = '1.28'

@allowed([
  'none'
  'patch'
  'stable'
  'rapid'
  'node-image'
])
@description('AKS upgrade channel')
param upgradeChannel string = 'stable'

@maxLength(80)
@description('The name of the NEW resource group to create the AKS cluster managed resources in')
param managedNodeResourceGroup string = ''


////////////////////
// Compute Configuration
////////////////////
@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
  'Custom'
])
@description('The System Pool Preset sizing')
param clusterSize string = 'CostOptimised'

@description('The System Pool Preset sizing')
param AutoscaleProfile object = {
  'balance-similar-node-groups': 'true'
  expander: 'random'
  'max-empty-bulk-delete': '10'
  'max-graceful-termination-sec': '600'
  'max-node-provision-time': '15m'
  'max-total-unready-percentage': '45'
  'new-pod-scale-up-delay': '0s'
  'ok-total-unready-count': '3'
  'scale-down-delay-after-add': '10m'
  'scale-down-delay-after-delete': '20s'
  'scale-down-delay-after-failure': '3m'
  'scale-down-unneeded-time': '10m'
  'scale-down-unready-time': '20m'
  'scale-down-utilization-threshold': '0.5'
  'scan-interval': '10s'
  'skip-nodes-with-local-storage': 'true'
  'skip-nodes-with-system-pods': 'true'
}

@description('The number of agents for the user node pool')
param agentCount int = 3

@description('The maximum number of nodes for the user node pool')
param agentCountMax int = 0
var autoScale = agentCountMax > agentCount

@minLength(3)
@maxLength(12)
@description('Name for user node pool')
param nodePoolName string = 'internal'

@description('Only use the system node pool')
param JustUseSystemPool bool = false

////////////////////
// Required Items to link to other resources
////////////////////

@description('Specify the Log Analytics Workspace Id to use for monitoring.')
param workspaceId string

@description('Specify the User Managed Identity Resource Id.')
param identityId string


////////////////////
// Network Configuration
////////////////////

@allowed([
  'azure'
  'kubenet'
])
@description('The network plugin type')
param networkPlugin string = 'azure'

@allowed([
  ''
  'Overlay'
])
@description('The network plugin type')
param networkPluginMode string = 'Overlay'

@allowed([
  ''
  'azure'
  'calico'
  'cilium'
])
@description('The network policy to use.')
param networkPolicy string = 'cilium'

@allowed([
  ''
  'cilium'
])
@description('Use Cilium dataplane (requires azure networkPlugin)')
param ebpfDataplane string = ''

@minLength(9)
@maxLength(18)
@description('The address range to use for pods')
param podCidr string = '192.168.0.0/16'

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string = '172.16.0.0/16'

@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string = '172.16.0.10'

@allowed([
  'loadBalancer'
  'natGateway'
  'userDefinedRouting'
])
@description('Outbound traffic type for the egress traffic of your cluster')
param aksOutboundTrafficType string = 'loadBalancer'

@description('DNS prefix. Defaults to {resourceName}-dns')
param dnsPrefix string = 'aks-${resourceGroup().name}'

@minValue(1)
@maxValue(16)
@description('The effective outbound IP resources of the cluster NAT gateway')
param natGwIpCount int = 2

@minValue(4)
@maxValue(120)
@description('Outbound flow idle timeout in minutes for NatGw')
param natGwIdleTimeout int = 30

@description('Allocate pod ips dynamically')
param cniDynamicIpAllocation bool = false


////////////////////
// BYO Network Configuration
////////////////////

@description('Are you providing a custom VNET')
param custom_vnet bool = false

@description('Full resource id path of an existing subnet to use for AKS')
param aksSubnetId string = ''

@description('Full resource id path of an existing pod subnet to use for AKS')
param aksPodSubnetId string = ''


////////////////////
// Security Settings
////////////////////

@description('Enable private cluster')
param enablePrivateCluster bool = false

@allowed([
  'system'
  'none'
  'privateDnsZone'
])
@description('Private cluster dns advertisment method, leverages the dnsApiPrivateZoneId parameter')
param privateClusterDnsMethod string = 'system'

@description('The full Azure resource ID of the privatelink DNS zone to use for the AKS cluster API Server')
param dnsApiPrivateZoneId string = ''

@description('The IP addresses that are allowed to access the API server')
param authorizedIPRanges array = []

@allowed([
  ''
  'audit'
  'deny'
])
@description('Enable the Azure Policy addon')
param azurepolicy string = ''

@allowed([
  'Baseline'
  'Restricted'
])
param azurePolicyInitiative string = 'Baseline'


////////////////////
// Add Ons
////////////////////

@description('Enables Kubernetes Event-driven Autoscaling (KEDA)')
param kedaEnabled bool = false

@description('Enables Open Service Mesh')
param openServiceMeshEnabled bool = false

@description('Installs Azure Workload Identity into the cluster')
param workloadIdentityEnabled bool = false

@description('Enable Microsoft Defender for Containers (preview)')
param defenderEnabled bool = false

@description('Installs the AKS KV CSI provider')
param keyvaultEnabled bool = false

@description('Rotation poll interval for the AKS KV CSI provider')
param keyVaultAksCSIPollInterval string = '2m'

@description('Enable Azure AD integration on AKS')
param enable_aad bool = false

@description('Enable RBAC using AAD')
param enableAzureRBAC bool = false

@description('Enables SGX Confidential Compute plugin')
param sgxPlugin bool = false

@description('Enables the Blob CSI driver')
param blobCSIDriver bool = false

@description('Enables the File CSI driver')
param fileCSIDriver bool = true

@description('Enables the Disk CSI driver')
param diskCSIDriver bool = true

@description('Disable local K8S accounts for AAD enabled clusters')
param AksDisableLocalAccounts bool = false

@description('Configures the cluster as an OIDC issuer for use with Workload Identity')
param oidcIssuer bool = false

@description('Enable Web App Routing')
param warIngressNginx bool = false

@description('Specifies whether to enable ImageCleaner on AKS cluster. The default value is false.')
param enableImageCleaner bool = false

@description('Specifies whether ImageCleaner scanning interval in hours.')
param imageCleanerIntervalHours int = 24

// Preview feature requires: az feature register --namespace "Microsoft.ContainerService" --name "NRGLockdownPreview"
@allowed([
  'ReadOnly'
  'Unrestricted'
])
@description('The restriction level applied to the cluster node resource group')
param restrictionLevelNodeResourceGroup string = 'Unrestricted'

// Preview feature requires: az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
@allowed(['', 'Istio'])
@description('The service mesh profile to use')
param serviceMeshProfile string = ''

@allowed([
  ''
  'External'
  'Internal'
  'Both'
])
@description('The ingress gateway to use for the Istio service mesh')
param istioIngressGatewayMode string = ''
param istioRevision string = 'asm-1-18'


/*__    ____  ___      .______       __       ___      .______    __       _______     _______.
\   \  /   / /   \     |   _  \     |  |     /   \     |   _  \  |  |     |   ____|   /       |
 \   \/   / /  ^  \    |  |_)  |    |  |    /  ^  \    |  |_)  | |  |     |  |__     |   (----`
  \      / /  /_\  \   |      /     |  |   /  /_\  \   |   _  <  |  |     |   __|     \   \    
   \    / /  _____  \  |  |\  \----.|  |  /  _____  \  |  |_)  | |  `----.|  |____.----)   |   
    \__/ /__/     \__\ | _| `._____||__| /__/     \__\ |______/  |_______||_______|_______/    
*/
                                                                                               
@description('The name of the AKS cluster.')
var name = '${replace(resourceName, '-', '')}${uniqueString(resourceGroup().id, resourceName)}'

var serviceMeshProfileObj = {
  istio: {
    components: {
      ingressGateways: empty(istioIngressGatewayMode) ? null : union(
        istioIngressGatewayMode == 'Internal' ? array(ingressModes.internal) : [],
        istioIngressGatewayMode == 'External' ? array(ingressModes.external) : [],
        istioIngressGatewayMode == 'Both' ? array(ingressModes.internal) : [],
        istioIngressGatewayMode == 'Both' ? array(ingressModes.external) : []           
      )
    }
    revisions: [
      istioRevision
    ]
  }
  mode: 'Istio'
}

@description('This resolves the friendly natGateway to the actual outbound traffic type value used by AKS')
var outboundTrafficType = aksOutboundTrafficType=='natGateway' ? ( custom_vnet ? 'userAssignedNATGateway' : 'managedNATGateway' )  : aksOutboundTrafficType

@description('System Pool presets are derived from the recommended system pool specs')
var systemPoolPresets = {
  // 4 vCPU, 16 GiB RAM, 32 GiB Temp Disk, (3600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_B4ms'
    minCount: 1
    maxCount: 3
    availabilityZones: []
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 2 vCPU, 7 GiB RAM, 14 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_DS2_v2'
    minCount: 3
    maxCount: 5
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 4 vCPU, 16 GiB RAM, 32 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  HighSpec : {
    vmSize: 'Standard_D4s_v3'
    minCount: 3
    maxCount: 10
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
}

var systemPoolProfile = {
  name: 'default'
  mode: 'System'
  osType: 'Linux'
  osSKU: 'AzureLinux'
  type: 'VirtualMachineScaleSets'
  osDiskType: systemPoolPresets[clusterSize].osDiskType
  osDiskSizeGB: systemPoolPresets[clusterSize].osDiskSize
  vmSize: systemPoolPresets[clusterSize].vmSize
  count: systemPoolPresets[clusterSize].minCount
  minCount: systemPoolPresets[clusterSize].minCount
  maxCount: systemPoolPresets[clusterSize].maxCount
  availabilityZones: systemPoolPresets[clusterSize].availabilityZones
  enableAutoScaling: true
  maxPods: systemPoolPresets[clusterSize].maxPods
  vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
  podSubnetID: !empty(aksPodSubnetId) ? aksPodSubnetId : null
  upgradeSettings: {
    maxSurge: '33%'
  }
  nodeTaints: [
    JustUseSystemPool ? '' : 'CriticalAddonsOnly=true:NoSchedule'
  ]
}

@description('First User Pool presets')
var userPoolPresets = {
  // 4 vCPU, 16 GiB RAM, 32 GiB Temp Disk, (3600) IOPS, 128 GB Managed OS Disk
  CostOptimised : {
    vmSize: 'Standard_B4ms'
    minCount: 3
    maxCount: 8
    availabilityZones: []
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 4 vCPU, 32 GiB RAM, 64 GiB SSD, (8000) IOPS, 128 GB Managed OS Disk
  Standard : {
    vmSize: 'Standard_E4s_v3'
    minCount: 3
    maxCount: 15
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Managed'
    osDiskSize: 128
    maxPods: 30
  }
  // 8 vCPU, 32 GiB RAM, 300 GiB Temp Disk, (77000) IOPS, Ephermial Disk
  HighSpec : {
    vmSize: 'Standard_D8ds_v4'
    minCount: 4
    maxCount: 20
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
    osDiskType: 'Ephemeral'
    osDiskSize: 0
    maxPods: 30
  }
}

var userPoolProfile = {
  name: nodePoolName
  mode: 'User'
  osType: 'Linux'
  osSKU: 'AzureLinux'
  type: 'VirtualMachineScaleSets'
  osDiskType: userPoolPresets[clusterSize].osDiskType
  osDiskSizeGB: userPoolPresets[clusterSize].osDiskSize
  vmSize: userPoolPresets[clusterSize].vmSize
  count: userPoolPresets[clusterSize].minCount
  minCount: userPoolPresets[clusterSize].minCount
  maxCount: userPoolPresets[clusterSize].maxCount
  availabilityZones: userPoolPresets[clusterSize].availabilityZones
  enableAutoScaling: true
  maxPods: userPoolPresets[clusterSize].maxPods
  vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
  podSubnetID: !empty(aksPodSubnetId) ? aksPodSubnetId : null
  upgradeSettings: {
    maxSurge: '33%'
  }
}

var agentPoolProfiles = JustUseSystemPool ? array(systemPoolProfile) : concat(array(systemPoolProfile), array(userPoolProfile))


var akssku = skuTierPaid ? 'Standard' : 'Free'

var aks_addons = union({
  azurepolicy: {
    config: {
      version: !empty(azurepolicy) ? 'v2' : null
    }
    enabled: !empty(azurepolicy)
  }
  azureKeyvaultSecretsProvider: {
    config: {
      enableSecretRotation: 'true'
      rotationPollInterval: keyVaultAksCSIPollInterval
    }
    enabled: keyvaultEnabled
  }
  openServiceMesh: {
    enabled: openServiceMeshEnabled
    config: {}
  }
  ACCSGXDevicePlugin: {
    enabled: sgxPlugin
    config: {}
  }
}, !(empty(workspaceId)) ? {
  omsagent: {
    enabled: !(empty(workspaceId))
    config: {
      logAnalyticsWorkspaceResourceID: !(empty(workspaceId)) ? workspaceId : null
    }
  }} : {})


@description('Sets the private dns zone id if provided')
var aksPrivateDnsZone = privateClusterDnsMethod=='privateDnsZone' ? (!empty(dnsApiPrivateZoneId) ? dnsApiPrivateZoneId : 'system') : privateClusterDnsMethod

@description('Needing to seperately declare and union this because of https://github.com/Azure/AKS-Construction/issues/344')
var managedNATGatewayProfile =  {
  natGatewayProfile : {
    managedOutboundIPProfile: {
      count: natGwIpCount
    }
    idleTimeoutInMinutes: natGwIdleTimeout
  }
}

@description('Needing to seperately declare and union this because of https://github.com/Azure/AKS/issues/2774')
var azureDefenderSecurityProfile = {
  securityProfile : {
    defender: {
      logAnalyticsWorkspaceResourceId: workspaceId
      securityMonitoring: {
        enabled: defenderEnabled
      }
    }
  }
}


var aksProperties = union({
  kubernetesVersion: aksVersion
  enableRBAC: true
  dnsPrefix: dnsPrefix
  aadProfile: enable_aad ? {
    managed: true
    enableAzureRBAC: enableAzureRBAC
    tenantID: aad_tenant_id
    adminGroupObjectIDs: empty(admin_ids) ? null : admin_ids
  } : null
  apiServerAccessProfile: !empty(authorizedIPRanges)  ? {
    authorizedIPRanges: authorizedIPRanges
  } : {
    enablePrivateCluster: enablePrivateCluster
    privateDNSZone: enablePrivateCluster ? aksPrivateDnsZone : ''
    enablePrivateClusterPublicFQDN: enablePrivateCluster && privateClusterDnsMethod=='none'
  }
  agentPoolProfiles: agentPoolProfiles
  workloadAutoScalerProfile: {
    keda: {
        enabled: kedaEnabled
    }
  }
  networkProfile: {
    loadBalancerSku: 'standard'
    networkPlugin: networkPlugin
    #disable-next-line BCP036 //Disabling validation of this parameter to cope with empty string to indicate no Network Policy required.
    networkPolicy: networkPolicy
    networkPluginMode: networkPlugin=='azure' ? networkPluginMode : ''
    networkDataplane: networkPolicy=='cilium' ? networkPolicy : ''
    podCidr: networkPlugin=='kubenet' || networkPluginMode=='Overlay' || cniDynamicIpAllocation ? podCidr : null
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP
    outboundType: outboundTrafficType
    ebpfDataplane: networkPlugin=='azure' ? ebpfDataplane : ''
  }
  disableLocalAccounts: AksDisableLocalAccounts && enable_aad
  autoUpgradeProfile: {upgradeChannel: upgradeChannel}
  addonProfiles: aks_addons
  autoScalerProfile: autoScale ? AutoscaleProfile : {}
  oidcIssuerProfile: {
    enabled: oidcIssuer
  }
  securityProfile: {
    workloadIdentity: {
      enabled: workloadIdentityEnabled
    }
    defender: {
      logAnalyticsWorkspaceResourceId: defenderEnabled ? workspaceId : null
      securityMonitoring: {
        enabled: defenderEnabled
      }
    }
    imageCleaner: {
      enabled: enableImageCleaner
      intervalHours: imageCleanerIntervalHours
    }
  }
  ingressProfile: {
    webAppRouting: {
      enabled: warIngressNginx
    }
  }
  storageProfile: {
    blobCSIDriver: {
      enabled: blobCSIDriver
    }
    diskCSIDriver: {
      enabled: diskCSIDriver
    }
    fileCSIDriver: {
      enabled: fileCSIDriver
    }
  }
  nodeResourceGroupProfile: {
    restrictionLevel: restrictionLevelNodeResourceGroup
  }
},
outboundTrafficType == 'managedNATGateway' ? managedNATGatewayProfile : {},
defenderEnabled ? azureDefenderSecurityProfile : {},
!empty(managedNodeResourceGroup) ? {  nodeResourceGroup: managedNodeResourceGroup} : {},
!empty(serviceMeshProfile) ? { serviceMeshProfile: serviceMeshProfileObj } : {}
)

var ingressModes = {
  external: {
    enabled: true
    mode: 'External'
  }
  internal: {
    enabled: true
    mode: 'Internal'
  }
}


/*
.______       _______     _______.  ______    __    __  .______        ______  _______     _______.
|   _  \     |   ____|   /       | /  __  \  |  |  |  | |   _  \      /      ||   ____|   /       |
|  |_)  |    |  |__     |   (----`|  |  |  | |  |  |  | |  |_)  |    |  ,----'|  |__     |   (----`
|      /     |   __|     \   \    |  |  |  | |  |  |  | |      /     |  |     |   __|     \   \    
|  |\  \----.|  |____.----)   |   |  `--'  | |  `--'  | |  |\  \----.|  `----.|  |____.----)   |   
| _| `._____||_______|_______/     \______/   \______/  | _| `._____| \______||_______|_______/    
*/

resource aks 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: length(name) > 63 ? substring(name, 0, 63) : name
  location: location
  tags: tags

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }

  properties: aksProperties

  sku: {
    name: 'Base'
    tier: akssku
  }
}

/*
  ______    __    __  .___________..______    __    __  .___________.
 /  __  \  |  |  |  | |           ||   _  \  |  |  |  | |           |
|  |  |  | |  |  |  | `---|  |----`|  |_)  | |  |  |  | `---|  |----`
|  |  |  | |  |  |  |     |  |     |   ___/  |  |  |  |     |  |     
|  `--'  | |  `--'  |     |  |     |  |      |  `--'  |     |  |     
 \______/   \______/      |__|     | _|       \______/      |__|     
*/
output aksClusterName string = aks.name
output aksOidcIssuerUrl string = oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
output userNodePoolName string = nodePoolName
output systemNodePoolName string = JustUseSystemPool ? nodePoolName : 'npsystem'

output aksPrivateDnsZone string = aksPrivateDnsZone
output privateFQDN string = enablePrivateCluster && privateClusterDnsMethod != 'none' ? aks.properties.privateFQDN : ''
// Dropping cluster name at start of privateFQDN to get private dns zone name.
output aksPrivateDnsZoneName string =  enablePrivateCluster && privateClusterDnsMethod != 'none' ? join(skip(split(aks.properties.privateFQDN, '.'),1),'.') : ''



@description('This output can be directly leveraged when creating a ManagedId Federated Identity')
output aksOidcFedIdentityProperties object = {
  issuer: oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
  audiences: ['api://AzureADTokenExchange']
  subject: 'system:serviceaccount:ns:svcaccount'
}

@description('The name of the managed resource group AKS uses')
output aksNodeResourceGroup string = aks.properties.nodeResourceGroup

@description('The Azure resource id for the AKS cluster')
output aksResourceId string = aks.id



////////////////
// Policy
////////////////

var policySetBaseline = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
var policySetRestrictive = '/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00'

resource aks_policies 'Microsoft.Authorization/policyAssignments@2023-04-01' = if (!empty(azurepolicy)) {
  name: '${aks.name}-${azurePolicyInitiative}'
  location: location
  properties: {
    policyDefinitionId: azurePolicyInitiative == 'Baseline' ? policySetBaseline : policySetRestrictive
    parameters: {
      excludedNamespaces: {
        value: [
            'kube-system'
            'gatekeeper-system'
            'azure-arc'
            'cluster-baseline-setting'
        ]
      }
      effect: {
        value: azurepolicy
      }
    }
    metadata: {
      assignedBy: 'Aks Construction'
    }
    displayName: 'Kubernetes cluster pod security ${azurePolicyInitiative} standards for Linux-based workloads'
    description: 'As per: https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/'
  }
}

@description('If automated deployment, for the 3 automated user assignments, set Principal Type on each to "ServicePrincipal" rarter than "User"')
param automatedDeployment bool = false

@description('The principal ID to assign the AKS admin role.')
param adminPrincipalId string = ''
// for AAD Integrated Cluster wusing 'enableAzureRBAC', add Cluster admin to the current user!
var buildInAKSRBACClusterAdmin = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b')
resource aks_admin_role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAzureRBAC && !empty(adminPrincipalId)) {
  scope: aks // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'aksadmin', buildInAKSRBACClusterAdmin)
  properties: {
    roleDefinitionId: buildInAKSRBACClusterAdmin
    principalType: automatedDeployment ? 'ServicePrincipal' : 'User'
    principalId: adminPrincipalId
  }
}


/*
 _______  __       __    __  ___   ___ 
|   ____||  |     |  |  |  | \  \ /  / 
|  |__   |  |     |  |  |  |  \  V  /  
|   __|  |  |     |  |  |  |   >   <   
|  |     |  `----.|  `--'  |  /  .  \  
|__|     |_______| \______/  /__/ \__\ 
*/
param fluxGitOpsAddon bool = false

resource fluxAddon 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = if(fluxGitOpsAddon) {
  name: 'flux'
  scope: aks
  properties: {
    extensionType: 'microsoft.flux'
    autoUpgradeMinorVersion: true
    // https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/conceptual-gitops-flux2#opt-out-of-multi-tenancy.
     configurationSettings: {
      'multiTenancy.enforce': 'false'
    }
    releaseTrain: 'Stable'
    scope: {
      cluster: {
        releaseNamespace: 'flux-system'
      }
    }
    configurationProtectedSettings: {}
  }
  dependsOn: [daprExtension] //Chaining dependencies because of: https://github.com/Azure/AKS-Construction/issues/385
}
output fluxReleaseNamespace string = fluxGitOpsAddon ? fluxAddon.properties.scope.cluster.releaseNamespace : ''

@description('Add the Dapr extension')
param daprAddon bool = false
@description('Enable high availability (HA) mode for the Dapr control plane')
param daprAddonHA bool = false

resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = if(daprAddon) {
    name: 'dapr'
    scope: aks
    properties: {
        extensionType: 'Microsoft.Dapr'
        autoUpgradeMinorVersion: true
        releaseTrain: 'Stable'
        configurationSettings: {
            'global.ha.enabled': '${daprAddonHA}'
        }
        scope: {
          cluster: {
            releaseNamespace: 'dapr-system'
          }
        }
        configurationProtectedSettings: {}
    }
}

output daprReleaseNamespace string = daprAddon ? daprExtension.properties.scope.cluster.releaseNamespace : ''
