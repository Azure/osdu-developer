/////////////////
// Cluster Blade 
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

// D4pds v5 with 4 vCPUs and 16 GiB of memory. Available in 22 regions starting from $88.18 per month.
// D4s_v5 with 4 vCPUs and 16 GiB of memory. Available in 50 regions starting from $140.16 per month.
@description('A Custom VM Size for System Pool (4x8 ARM:true)')
param vmSizeSystemPool string = 'Standard_D4pds_v6'

// D2pds v5 with 2 vCPUs and 8 GiB of memory. Available in 22 regions starting from $44.09 per month.
// D2s_v5 with 2 vCPUs and 8 GiB of memory. Available in 50 regions starting from $70.08 per month.
@description('A Custom VM Size for Zone Pool (2x8 ARM:true)')
param vmSizeZonePool string = 'Standard_D2pds_v6'

// B4s_v2 with 4 vCPUs and 16 GiB of memory. Available in 49 regions starting from $16.64 per month.
// D4s_v5 with 4 vCPUs and 16 GiB of memory. Available in 50 regions starting from $140.16 per month.
@description('A Custom VM Size for User Pool (2x8 ARM:false BURST:true)')
param vmSizeUserPool string = 'Standard_B4s_v2'

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string = '10.0.0.0/16'

@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string = '10.0.0.10'

@description('The id of the subnet to deploy the AKS nodes')
param aksSubnetId string

@description('The id of the subnet to deploy AKS pods')
param podSubnetId string = ''

@description('The managed identity name for deployment scripts')
param managedIdentityName string

@description('The user managed identity for the cluster.')
param identityId string

@description('Feature Flag to Enable Node Auto Provisioning')
param enableNodeAutoProvisioning bool = true

@description('Feature Flag to Enable Private Cluster')
param enablePrivateCluster bool = true

@description('Feature Flag to Enable Node Resource Group Lock Down')
param nodeResourceGroupLockDown bool = true



/////////////////////////////////
// Configuration 
/////////////////////////////////

var serviceLayerConfig = {
  registry: {
    sku: 'Basic'
  }
  cluster: {
    tier: 'Standard'
    sku: 'Base'
    aksVersion: '1.30'

    // // D2pds v5 with 2 vCPUs and 8 GiB of memory. Available in 22 regions starting from $44.09 per month.
    // // D4pds v5 with 4 vCPUs and 16 GiB of memory. Available in 22 regions starting from $88.18 per month.
    // // D2s_v5 with 2 vCPUs and 8 GiB of memory. Available in 50 regions starting from $70.08 per month.
    // // D4s_v5 with 4 vCPUs and 16 GiB of memory. Available in 50 regions starting from $140.16 per month.
    // // D4ps_v5 with 4 vCPUs and 16 GiB of memory. Available in 23 regions, starting from $73.73 per month.
    // // B4s_v2 with 4 vCPUs and 16 GiB of memory. Available in 49 regions starting from $16.64 per month.
    // vmSize: 'Standard_D4pds_v6' 
    // poolSize: 'Standard_D2pds_v6'  
    // defaultSize: 'Standard_B4s_v2' // OSDU Java Services don't run on ARM?
  }
}

/////////////////////////////////
// Existing Resources
/////////////////////////////////

resource appIdentity  'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: managedIdentityName
}


/*
     ___       __  ___      _______.
    /   \     |  |/  /     /       |
   /  ^  \    |  '  /     |   (----`
  /  /_\  \   |    <       \   \    
 /  _____  \  |  .  \  .----)   |   
/__/     \__\ |__|\__\ |_______/    
*/
module cluster './managed-cluster/main.bicep' = {
  name: '${bladeConfig.sectionName}-aks-cluster'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    skuTier: serviceLayerConfig.cluster.tier
    skuName: serviceLayerConfig.cluster.sku
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
    enablePrivateCluster: enablePrivateCluster

    // Access Settings
    disableLocalAccounts: true
    enableRBAC: true
    aadProfileManaged: true
    nodeResourceGroupLockDown: nodeResourceGroupLockDown

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
    enableStorageProfileBlobCSIDriver: false    
    enableKeyvaultSecretsProvider: true
    enableSecretRotation: true
    enableImageCleaner: true
    imageCleanerIntervalHours: 24
    enableOidcIssuerProfile: true
    enableWorkloadIdentity: true
    azurePolicyEnabled: true
    omsAgentEnabled: true

    // Auto-Scaling
    vpaAddon: true
    kedaAddon: true
    enableNodeAutoProvisioning: enableNodeAutoProvisioning
    
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
        vmSize: vmSizeSystemPool
        enableAutoScaling: !enableNodeAutoProvisioning
        count: enableNodeAutoProvisioning ? 2 : null
        minCount: enableNodeAutoProvisioning ? null : 2
        maxCount: enableNodeAutoProvisioning ? null : 6
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
        vmSize: vmSizeUserPool
        enableAutoScaling: !enableNodeAutoProvisioning
        count: enableNodeAutoProvisioning ? 4 : null
        minCount: enableNodeAutoProvisioning ? null : 4
        maxCount: enableNodeAutoProvisioning ? null : 20
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
        vmSize: vmSizeZonePool
        enableAutoScaling: !enableNodeAutoProvisioning
        minCount: enableNodeAutoProvisioning ? null : 1
        maxCount: enableNodeAutoProvisioning ? null : 3
        count: enableNodeAutoProvisioning ? 1 : null
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '1'
        ]
        vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
        podSubnetId: !empty(podSubnetId) ? podSubnetId : null
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
      {
        name: 'poolz2'
        mode: 'User'
        vmSize: vmSizeZonePool
        enableAutoScaling: !enableNodeAutoProvisioning
        minCount: enableNodeAutoProvisioning ? null : 1
        maxCount: enableNodeAutoProvisioning ? null : 3
        count: enableNodeAutoProvisioning ? 1 : null
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '2'
        ]
        vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
        podSubnetId: !empty(podSubnetId) ? podSubnetId : null
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
      {
        name: 'poolz3'
        mode: 'User'
        vmSize: vmSizeZonePool
        enableAutoScaling: !enableNodeAutoProvisioning
        minCount: enableNodeAutoProvisioning ? null : 1
        maxCount: enableNodeAutoProvisioning ? null : 3
        count: enableNodeAutoProvisioning ? 1 : null
        sshAccess: 'Disabled'
        osType: 'Linux'
        osSku: 'AzureLinux'
        availabilityZones: [
          '3'
        ]
        vnetSubnetID: !empty(aksSubnetId) ? aksSubnetId : null
        podSubnetId: !empty(podSubnetId) ? podSubnetId : null
        nodeTaints: ['app=cluster:NoSchedule']
        nodeLabels: {
          app: 'cluster'
        }
      }
    ]
  }
}


/*
     _______.  ______ .______       __  .______   .___________.
    /       | /      ||   _  \     |  | |   _  \  |           |
   |   (----`|  ,----'|  |_)  |    |  | |  |_)  | `---|  |----`
    \   \    |  |     |      /     |  | |   ___/      |  |     
.----)   |   |  `----.|  |\  \----.|  | |  |          |  |     
|_______/     \______|| _| `._____||__| | _|          |__|     
*/
module natClusterIP './managed-cluster/nat_public_ip.bicep' = {
  name: '${bladeConfig.sectionName}-nat-public-ip'
  params: {
    publicIpResourceId: cluster.outputs.outboundIpResourceId
  }
  dependsOn: [
    cluster
  ]
}


/*
.______     ______    __       __    ______ ____    ____ 
|   _  \   /  __  \  |  |     |  |  /      |\   \  /   / 
|  |_)  | |  |  |  | |  |     |  | |  ,----' \   \/   /  
|   ___/  |  |  |  | |  |     |  | |  |       \_    _/   
|  |      |  `--'  | |  `----.|  | |  `----.    |  |     
| _|       \______/  |_______||__|  \______|    |__|     
*/
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


/*
 __________   ___ .___________. _______ .__   __.      _______. __    ______   .__   __. 
|   ____\  \ /  / |           ||   ____||  \ |  |     /       ||  |  /  __  \  |  \ |  | 
|  |__   \  V  /  `---|  |----`|  |__   |   \|  |    |   (----`|  | |  |  |  | |   \|  | 
|   __|   >   <       |  |     |   __|  |  . `  |     \   \    |  | |  |  |  | |  . `  | 
|  |____ /  .  \      |  |     |  |____ |  |\   | .----)   |   |  | |  `--'  | |  |\   | 
|_______/__/ \__\     |__|     |_______||__| \__| |_______/    |__|  \______/  |__| \__| 
*/
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



// =============== //
//   Outputs       //
// =============== //

@description('The name of the cluster.')
output clusterName string = cluster.outputs.name

@description('The IP address of the NAT cluster.')
output natClusterIP string = natClusterIP.outputs.ipAddress

@description('The OIDC Issuer URL for the cluster.')
output oidcIssuerUrl string = cluster.outputs.oidcIssuerUrl

@description('The Object ID of the Kubelet Identity.') 
output kubeletIdentityId string = cluster.outputs.kubeletIdentityObjectId

// =============== //
//   Definitions   //
// =============== //

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}
