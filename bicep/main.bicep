targetScope = 'resourceGroup'


@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Specify the User Email.')
param emailAddress string

@description('Specify the Application Client Id. (This is the unique application ID of this application.)')
param applicationClientId string

@description('Specify the Application Client Secret. (A valid secret for the application client ID.)')
@secure()
param applicationClientSecret string

@description('Specify the Enterprise Application Object Id. (This is the unique ID of the service principal object associated with the application.)')
param applicationClientPrincipalOid string

@description('The size of the VM to use for the cluster.')
param customVMSize string = ''

@allowed([
  'External'
  'Internal'
  'Both'
  ''
])
@description('Specify the Ingress type for the cluster.')
param ingressType string = 'External'

@description('Feature Flag: Enable Storage accounts public access.')
param enableBlobPublicAccess bool = false

@description('(Optional) Software Load Override - {enable/osduCore/osduReference} --> true/false, {repository} --> https://github.com/azure/osdu-devloper  {branch} --> branch:main')
param clusterSoftware object = {
  enable: true
  osduCore: true
  osduReference: true
  osduVersion: ''
  repository: ''
  branch: ''
  tag: ''
}

@description('(Optional) Experimental Software Override - {enable/adminUI} --> true/false')
param experimentalSoftware object = {
  enable: false
  adminUI: false
}

@description('Optional: Cluster Configuration Overrides')
param clusterConfiguration object = {
  enableNodeAutoProvisioning: true
  enablePrivateCluster: false
}

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
    insightsKey: 'insights-key'
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

var rg_unique_id = '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'

//*****************************************************************//
//  Identity Resources                                             //
//*****************************************************************//
module stampIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: '${configuration.name}-user-managed-identity'
  params: {
    // Required parameters
    name: rg_unique_id
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }
  }
}


//*****************************************************************//
//  Monitoring Resources                                           //
//*****************************************************************//
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.3.4' = {
  name: '${configuration.name}-log-analytics'
  params: {
    name: rg_unique_id
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }

    skuName: configuration.logs.sku
  }
}


//*****************************************************************//
//  Network Resources                                              //
//*****************************************************************//
module networkBlade 'modules/blade_network.bicep' = if (enableVnetInjection) {
  name: 'network-blade'
  params: {
    bladeConfig: {
      sectionName: 'networkblade'
      displayName: 'Network Resources'
    }

    tags: {
      id: rg_unique_id
    }

    location: location
    enableTelemetry: enableTelemetry

    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: stampIdentity.outputs.principalId

    enablePodSubnet: vnetConfiguration.podSubnet.name != '' && vnetConfiguration.podSubnet.prefix != '' ? true: false
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

    tags: {
      id: rg_unique_id
    }

    location: location
    enableTelemetry: enableTelemetry
    deploymentScriptIdentity: stampIdentity.outputs.name

    userAssignedIdentityName: stampIdentity.outputs.name

    workspaceResourceId: logAnalytics.outputs.resourceId
    workspaceName: logAnalytics.outputs.name

    subnetId: enableVnetInjection ? networkBlade.outputs.aksSubnetId : ''
    cmekConfiguration: cmekConfiguration

    enablePrivateLink: enablePrivateLink
    enableBlobPublicAccess: enableBlobPublicAccess

    applicationClientId: applicationClientId
    applicationClientSecret: applicationClientSecret
    applicationClientPrincipalOid: applicationClientPrincipalOid
  }
  dependsOn: enableVnetInjection ? [
    networkBlade
  ] :[]
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

    tags: {
      id: rg_unique_id
    }

    location: location
    workspaceResourceId: logAnalytics.outputs.resourceId

    kvName: commonBlade.outputs.keyvaultName
    subnetId: enableVnetInjection ? networkBlade.outputs.aksSubnetId : ''

    enableBlobPublicAccess: enableBlobPublicAccess
    enablePrivateLink: enablePrivateLink

    storageDNSZoneId: commonBlade.outputs.storageDNSZoneId
    cosmosDNSZoneId: commonBlade.outputs.cosmosDNSZoneId

    partitions: configuration.partitions
    managedIdentityName: stampIdentity.outputs.name
  }
  dependsOn: enableVnetInjection ? [
    networkBlade
    commonBlade
  ] :[
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

    tags: {
      id: rg_unique_id
    }

    location: location
    enableTelemetry: enableTelemetry

    enableNodeAutoProvisioning: clusterConfiguration.enableNodeAutoProvisioning == 'false' ? false : true
    enablePrivateCluster: clusterConfiguration.enablePrivateCluster == 'false' ? false : true

    osduVersion: clusterSoftware.osduVersion == '' ? 'master' : clusterSoftware.osduVersion
    enableSoftwareLoad: clusterSoftware.enable == 'false' ? false : true
    enableOsduCore: clusterSoftware.osduCore == 'false' ? false : true
    enableOsdureference: clusterSoftware.osduReference == 'false' ? false : true
    enableExperimental: experimentalSoftware.enable == 'true' ? true : false
    enableAdminUI: experimentalSoftware.adminUI == 'true' ? true : false

    emailAddress: emailAddress
    applicationClientId: applicationClientId
    applicationClientPrincipalOid: applicationClientPrincipalOid
    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: enableVnetInjection ? networkBlade.outputs.networkConfiguration.identityId : stampIdentity.outputs.resourceId
    managedIdentityName: stampIdentity.outputs.name
    kvName: commonBlade.outputs.keyvaultName
    kvUri: commonBlade.outputs.keyvaultUri
    storageName: commonBlade.outputs.storageAccountName
    partitionStorageNames: partitionBlade.outputs.partitionStorageNames
    partitionServiceBusNames: partitionBlade.outputs.partitionServiceBusNames
    
    aksSubnetId: enableVnetInjection ? networkBlade.outputs.aksSubnetId : ''
    podSubnetId: enableVnetInjection ? networkBlade.outputs.podSubnetId : ''
    vmSize: customVMSize

    clusterIngress: ingressType == '' ? 'External' : ingressType

    softwareBranch: clusterSoftware.branch
    softwareRepository: clusterSoftware.repository
    softwareTag: clusterSoftware.tag

    appSettings: [
      {
        name: 'Settings:StorageAccountName'
        value: partitionBlade.outputs.partitionStorageNames[0]
        contentType: 'text/plain'
        label: 'configmap-devsample'
      }
      {
        name: 'client_id'
        value: applicationClientId
        contentType: 'text/plain'
        label: 'configmap-services'
      }
    ]
  }
  dependsOn: [
    commonBlade
    partitionBlade
  ]
}

output ACR_NAME string = serviceBlade.outputs.registryName
output AKS_NAME string = serviceBlade.outputs.clusterName
output INSTRUMENTATION_KEY string = commonBlade.outputs.instrumentationKey
output COMMON_NAME string = commonBlade.outputs.storageAccountName
output DATA_NAME string = partitionBlade.outputs.partitionStorageNames[0]

//ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
