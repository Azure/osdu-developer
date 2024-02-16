targetScope = 'resourceGroup'


@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Specify the AD Application Client Id.')
param applicationClientId string

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
])
@description('The size of the solution')
param tier string = 'CostOptimised'

@description('Feature Flag: Enable Storage accounts public access.')
param enableBlobPublicAccess bool = false

@description('Feature Flag: Enable management with a virtual machine and bastion host.')
param enableManage bool = false

@description('(Optional) If manage then the ssh user name for the virtual machine.')
param vmAdminUsername string = 'azureUser'

@description('Feature Flag: Enable AKS Enhanced Subnet Support (Azure CNI)')
param enablePodSubnet bool = false

// This would be a type but bugs exist for ARM Templates so is object instead.
@description('Optional. Bring your own Virtual Network.')
param vnetConfiguration object = {
  group: ''
  name: ''
  prefix: ''
  identityId: ''
  aksSubnet: {
    name: ''
    prefix: ''
  }
  podSubnet: {
    name: ''
    prefix: ''
  }
  vmSubnet: {
    name: ''
    prefix: ''
  }
  bastionSubnet: {
    name: ''
    prefix: ''
  }
}

@description('(Optional) Software Load Override - {enable} --> true/false, {repository} --> https://github.com/azure/osdu-devloper  {branch} --> branch:main')
param clusterSoftware object = {
  enable: true
  repository: ''
  branch: ''
}

// This would be a type but bugs exist for ARM Templates so is object instead.
@description('Cluster Network Overrides - {ingress} (Both/Internal/External), {serviceCidr}, {dockerBridgeCidr}, {dnsServiceIP}')
param clusterNetwork object = {
  ingress: ''
  serviceCidr: ''
  dockerBridgeCidr: ''
  dnsServiceIP: ''
}

@allowed([
  'kubenet'
  'azure'
])
@description('The network plugin to use for the Kubernetes cluster.')
param clusterNetworkPlugin string = 'kubenet'

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array = []

/////////////////////////////////
//  Configuration 
/////////////////////////////////

// Internal Feature Flags Start ->

@description('Feature Flag: Enable Telemetry')
var enableTelemetry = false

@description('Feature Flag: Enable Vnet Injection')
var enableVnetInjection = vnetConfiguration.group != '' && vnetConfiguration.name != '' && vnetConfiguration.prefix != ''

// This feature is not ready yet.
@description('Feature Flag to Enable Private Link')
var enablePrivateLink = false

// This feature is not ready yet.
@description('Optional. Customer Managed Encryption Key.')
var cmekConfiguration = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}

// <- Internal Feature Flags End


@description('Internal Configuration Object')
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
  partitions: [
    {
      name: 'opendes'
    }
  ]
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
//  Network Resources                                              //
//*****************************************************************//
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

    enableBastion: enableManage
    enablePodSubnet: enablePodSubnet
    enableVnetInjection: enableVnetInjection
    
    vnetConfiguration: {
      group: vnetConfiguration.group
      name: vnetConfiguration.name
      prefix: vnetConfiguration.prefix
      identityId: vnetConfiguration.identityId
      aksSubnet: {
        name: vnetConfiguration.aksSubnet.name
        prefix: vnetConfiguration.aksSubnet.prefix
      }
      podSubnet: {
        name: vnetConfiguration.podSubnet.name
        prefix: vnetConfiguration.podSubnet.prefix
      }
      bastionSubnet: {
        name: vnetConfiguration.bastionSubnet.name
        prefix: vnetConfiguration.bastionSubnet.prefix
      }
      vmSubnet: {
        name: vnetConfiguration.vmSubnet.name
        prefix: vnetConfiguration.vmSubnet.prefix
      }
    }
  }
  dependsOn: [
    stampIdentity
    logAnalytics
  ]
}


//*****************************************************************//
//  Common Resources                                               //
//*****************************************************************//
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
//  Manage Resources                                               //
//*****************************************************************//
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
    enableBastion: enableManage
    
    vmAdminUsername: vmAdminUsername
    vnetId: networkBlade.outputs.vnetId
    vmSubnetId: networkBlade.outputs.vmSubnetId
  }
  dependsOn: [
    networkBlade
    commonBlade
  ]
}


//*****************************************************************//
//  Partition Resources                                            //
//*****************************************************************//
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

    partitionSize: tier
    partitions: configuration.partitions
  }
  dependsOn: [
    networkBlade
    commonBlade
  ]
}


//*****************************************************************//
//  Service Resources                                              //
//*****************************************************************//
module serviceBlade 'modules/blade_service.bicep' = {
  name: 'service-blade'
  params: {
    bladeConfig: {
      sectionName: 'serviceblade'
      displayName: 'Service Resources'
    }

    location: location
    enableTelemetry: enableTelemetry

    enableSoftwareLoad: clusterSoftware.enable

    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: enableVnetInjection ? networkBlade.outputs.networkConfiguration.identityId : stampIdentity.outputs.resourceId
    managedIdentityName: stampIdentity.outputs.name
    kvName: commonBlade.outputs.keyvaultName
    kvUri: commonBlade.outputs.keyvaultUri
    storageName: commonBlade.outputs.storageAccountName
    partitionStorageNames: partitionBlade.outputs.partitionStorageNames
    
    aksSubnetId: networkBlade.outputs.aksSubnetId
    podSubnetId: enablePodSubnet ? networkBlade.outputs.podSubnetId : ''
    clusterSize: tier
    clusterAdminIds: clusterAdminIds

    clusterIngress: clusterNetwork.ingress == '' ? 'Both' : clusterNetwork.ingress
    serviceCidr: clusterNetwork.serviceCidr == '' ? '172.16.0.0/16' : clusterNetwork.serviceCidr
    dnsServiceIP: clusterNetwork.dnsServiceIP == '' ? '172.16.0.10' : clusterNetwork.v
    dockerBridgeCidr: clusterNetwork.dockerBridgeCidr == '' ? '172.17.0.1/16' : clusterNetwork.dockerBridgeCidr
    networkPlugin: enablePodSubnet ? 'azure' : clusterNetworkPlugin

    softwareBranch: clusterSoftware.branch
    softwareRepository: clusterSoftware.repository
  }
  dependsOn: [
    networkBlade
    commonBlade
    partitionBlade
  ]
}

//ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
