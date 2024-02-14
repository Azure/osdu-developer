targetScope = 'resourceGroup'


@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false


/////////////////////////////////
//  Configuration 
/////////////////////////////////

var configuration = {
  name: 'main'
  displayName: 'Main Resources'
  secrets: {
    tenantId: 'tenant-id'
    subscriptionId: 'subscription-id'
    registryName: 'container-registry'
    applicationId: 'aad-client-id'
    clientId: 'app-dev-sp-username'
    clientSecret: 'app-dev-sp-password'
    applicationPrincipalId: 'app-dev-sp-id'
    stampIdentity: 'osdu-identity-id'
    storageAccountName: 'common-storage'
    storageAccountKey: 'common-storage-key'
    cosmosConnectionString: 'graph-db-connection'
    cosmosEndpoint: 'graph-db-endpoint'
    cosmosPrimaryKey: 'graph-db-primary-key'
    logAnalyticsId: 'log-workspace-id'
    logAnalyticsKey: 'log-workspace-key'
  }
  logs: {
    sku: 'PerGB2018'
    retention: 30
  }
}


//*****************************************************************//
//  Identity Resources                                             //
//*****************************************************************//

module stampIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.0' = {
  name: '${configuration.name}-user-managed-identity'
  params: {
    // Required parameters
    name: 'id-${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
    }
  }
}


//*****************************************************************//
//  Monitoring Resources                                           //
//*****************************************************************//

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.2.1' = {
  name: '${configuration.name}-log-analytics'
  params: {
    name: 'log-${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
    }

    skuName: configuration.logs.sku
  }
}


//*****************************************************************//
//  Network Blade                                                  //
//*****************************************************************//

type bladeSettings = {
  @description('The name of the section name')
  sectionName: string
  @description('The display name of the section')
  displayName: string
}

type subnetSettings = {
  @description('The name of the subnet')
  name: string
  @description('The address range to use for the subnet')
  prefix: string
}

type vnetSettings = {
  @description('The name of the resource group that contains the Virtual Network')
  group: string
  @description('The name of the Virtual Network')
  name: string
  @description('The address range to use for the Virtual Network')
  prefix: string
  @description('The Managed Identity ')
  identityId: string
  @description('The cluster subnet')
  aksSubnet: subnetSettings
  @description('The pod subnet')
  podSubnet: subnetSettings
  @description('The machine subnet')
  vmSubnet: subnetSettings
  @description('The bastion subnet')
  bastionSubnet: subnetSettings
}

@description('Feature Flag to Enable Bastion')
param enableBastion bool = false

@description('Feature Flag to Enable a Pod Subnet')
param enablePodSubnet bool = false

@description('Feature Flag to Enable a Pod Subnet')
param enableVnetInjection bool = false

@description('Optional. Bring your own Virtual Network.')
param vnetConfiguration vnetSettings

module networkBlade 'modules/blade_network.bicep' = {
  name: 'network-blade'
  params: {
    bladeConfig: {
      sectionName: 'networkblade'
      displayName: 'Network Resources'
    }

    location: location
    enableTelemetry: enableTelemetry

    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: stampIdentity.outputs.principalId

    enableBastion: enableBastion
    enablePodSubnet: enablePodSubnet
    enableVnetInjection: enableVnetInjection
    
    vnetConfiguration: vnetConfiguration
  }
  dependsOn: [
    stampIdentity
    logAnalytics
  ]
}


//*****************************************************************//
//  Common Blade                                                   //
//*****************************************************************//

@description('Optional. Indicates whether public access is enabled for all blobs or containers in the storage account.')
param enableBlobPublicAccess bool = false

@description('Feature Flag to Enable Private Link')
param enablePrivateLink bool = false

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

module commonBlade 'modules/blade_common.bicep' = {
  name: 'common-blade'
  params: {
    bladeConfig: {
      sectionName: 'commonblade'
      displayName: 'Common Resources'
    }

    location: location
    enableTelemetry: enableTelemetry
    deploymentScriptIdentity: stampIdentity.outputs.name

    workspaceResourceId: logAnalytics.outputs.resourceId
    workspaceName: logAnalytics.outputs.name

    subnetId: networkBlade.outputs.aksSubnetId
    cmekConfiguration: cmekConfiguration

    enablePrivateLink: enablePrivateLink
    enableBlobPublicAccess: enableBlobPublicAccess
    
    workspaceIdName: configuration.secrets.logAnalyticsId
    workspaceKeySecretName: configuration.secrets.logAnalyticsKey
    
    vaultSecrets: [ 
      {
        secretName: configuration.secrets.tenantId
        secretValue: subscription().tenantId
      }
      {
        secretName: configuration.secrets.subscriptionId
        secretValue: subscription().subscriptionId
      }
      // Azure AD Secrets
      {
        secretName: configuration.secrets.clientId
        secretValue: applicationClientId
      }
      {
        secretName: configuration.secrets.applicationPrincipalId
        secretValue: applicationClientId
      }
    ]
  }
  dependsOn: [
    networkBlade
  ]
}


//*****************************************************************//
//  Manage Blade                                                   //
//*****************************************************************//

@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string = enableBastion ? 'azureUser' : newGuid()

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string = enableBastion ? '' : newGuid()

module manageBlade 'modules/blade_manage.bicep' = {
  name: 'manage-blade'
  params: {
    bladeConfig: {
      sectionName: 'manageblade'
      displayName: 'Manage Resources'
    }

    manageLayerConfig: {
      machine: {
        vmSize: 'Standard_DS3_v2'
        imagePublisher: 'Canonical'
        imageOffer: 'UbuntuServer'
        imageSku: '18.04-LTS'
        authenticationType: 'password'
      }
      bastion: {
        skuName: 'Basic'
      }
    }

    location: location
    enableTelemetry: enableTelemetry

    workspaceName: logAnalytics.outputs.name
    kvName: commonBlade.outputs.keyvaultName

    // Feature Flags
    enableBastion: enableBastion
    
    vmAdminUsername: vmAdminUsername
    vmAdminPasswordOrKey: vmAdminPasswordOrKey
    vnetId: networkBlade.outputs.vnetId
    vmSubnetId: networkBlade.outputs.vmSubnetId
  }
  dependsOn: [
    networkBlade
    commonBlade
  ]
}


//*****************************************************************//
//  Partition Blade                                                //
//*****************************************************************//

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
])
@description('The size of the solution')
param solutionTier string = 'CostOptimised'

@description('List of Data Partitions')
param partitions array = [
  {
    name: 'opendes'
  }
]

module partitionBlade 'modules/blade_partition.bicep' = {
  name: 'partition-blade'
  params: {
    bladeConfig: {
      sectionName: 'partitionblade'
      displayName: 'Partition Resources'
    }

    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId

    kvName: commonBlade.outputs.keyvaultName
    subnetId: networkBlade.outputs.aksSubnetId

    enableBlobPublicAccess: enableBlobPublicAccess
    enablePrivateLink: enablePrivateLink

    storageDNSZoneId: commonBlade.outputs.storageDNSZoneId
    cosmosDNSZoneId: commonBlade.outputs.cosmosDNSZoneId

    partitionSize: solutionTier
    partitions: partitions
  }
  dependsOn: [
    networkBlade
    commonBlade
  ]
}


//*****************************************************************//
//  Service Blade                                                  //
//*****************************************************************//
type ingressType = 'Internal' | 'External' | 'Both'
type networkPluginType = 'azure' | 'kubenet'
type clusterNetworkType = {
  @description('The type of network plugin to use for the cluster')
  networkPlugin: networkPluginType

  @description('The type of ingress to use for the cluster')
  ingress: ingressType

  @minLength(9)
  @maxLength(18)
  @description('The address range to use for services')
  serviceCidr: string

  @minLength(9)
  @maxLength(18)
  @description('The address range to use for the docker bridge')
  dockerBridgeCidr: string

  @minLength(7)
  @maxLength(15)
  @description('The IP address to reserve for DNS')
  dnsServiceIP: string
}
type softwareType = {
  @description('Feature Flag to Load Software.')
  enable: bool

  @description('The URL of the software repository')
  repository: string

  @description('The branch of the software repository')
  branch: string
}



@description('Cluster Network Properties')
param clusterNetworkProperties clusterNetworkType = {
  networkPlugin: enablePodSubnet ? 'azure' : 'kubenet'
  ingress: 'Both'
  serviceCidr: '172.16.0.0/16'
  dockerBridgeCidr: '172.17.0.1/16'
  dnsServiceIP: '172.16.0.10'
}

@description('Cluster Software Properties')
param clusterSoftwareProperties softwareType = {
  enable: true
  repository: ''
  branch: ''
}

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array = []




module serviceBlade 'modules/blade_service.bicep' = {
  name: 'service'
  params: {
    bladeConfig: {
      sectionName: 'serviceblade'
      displayName: 'Service Resources'
    }

    location: location
    enableTelemetry: enableTelemetry

    enableSoftwareLoad: clusterSoftwareProperties.enable

    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: enableVnetInjection ? networkBlade.outputs.networkConfiguration.identityId : stampIdentity.outputs.resourceId
    managedIdentityName: stampIdentity.outputs.name
    kvName: commonBlade.outputs.keyvaultName
    kvUri: commonBlade.outputs.keyvaultUri
    storageName: commonBlade.outputs.storageAccountName
    partitionStorageNames: partitionBlade.outputs.partitionStorageNames
    
    aksSubnetId: networkBlade.outputs.aksSubnetId
    podSubnetId: enablePodSubnet ? networkBlade.outputs.podSubnetId : ''
    clusterSize: solutionTier
    clusterIngress: clusterNetworkProperties.ingress
    clusterAdminIds: clusterAdminIds
    serviceCidr: clusterNetworkProperties.serviceCidr
    dnsServiceIP: clusterNetworkProperties.dnsServiceIP
    dockerBridgeCidr: clusterNetworkProperties.dockerBridgeCidr
    networkPlugin: clusterNetworkProperties.networkPlugin

    softwareBranch: clusterSoftwareProperties.branch
    softwareRepository: clusterSoftwareProperties.repository
  }
}

// //ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
