/////////////////
// Network Blade 
/////////////////

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('The tags to apply to the resources')
param tags object = {}

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('Optional. Bring your own Virtual Network.')
param vnetConfiguration vnetSettings

@description('Feature Flag to Enable a Pod Subnet')
param enablePodSubnet bool

@description('Feature Flag to Enable a Pod Subnet')
param enableVnetInjection bool

@description('The Managed Identity Principal Id')
param identityId string


/////////////////////////////////
// Configuration 
/////////////////////////////////

var networkConfiguration = vnetConfiguration.name == '' ? {
  prefix: '10.1.0.0/16'
  group: resourceGroup().name
  name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
  aksSubnet: {
    name: 'ClusterSubnet'
    prefix: '10.1.0.0/20'
  }
  podSubnet: {
    name: 'PodSubnet'
    prefix: '10.1.20.0/22'
  }
} : vnetConfiguration


var nsgRules = {
  ssh_outbound: {
    name: 'AllowSshOutbound'
    properties: {
      priority: 110
      protocol: '*'
      access: 'Allow'
      direction: 'Outbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '22'
        '3389'
      ]
    }
  }

  cloud_outbound: {
    name: 'AllowAzureCloudOutbound'
    properties: {
      priority: 120
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Outbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'AzureCloud'
      destinationPortRange: '443'
    }
  }

  allow_http_outbound: {
    name: 'AllowHttpOutbound'
    properties: {
      priority: 140
      protocol: '*'
      access: 'Allow'
      direction: 'Outbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '80'
    }
  }

  load_balancer_inbound: {
    name: 'AllowAzureLoadBalancerInbound'
    properties: {
      priority: 160
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'AzureLoadBalancer'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }

  http_inbound_rule: {
    name: 'AllowHttpInbound'
    properties: {
      priority: 200
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }

  https_inbound_rule: {
    name: 'AllowHttpsInbound'
    properties: {
      priority: 210
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }

  ssh_inbound: {
    name: 'AllowSshInbound'
    properties: {
      priority: 220
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '22'
        '3389'
      ]
    }
  }
}

var subnets = {
  cluster: {
    name: networkConfiguration.aksSubnet.name
    addressPrefix: networkConfiguration.aksSubnet.prefix
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.ContainerRegistry'
      }
    ]
    networkSecurityGroupResourceId: !enableVnetInjection ? clusterNetworkSecurityGroup.outputs.resourceId :null
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Network Contributor'
        principalId: identityId
        principalType: 'ServicePrincipal'
      }
    ]
  }
  pods: {
    name: networkConfiguration.podSubnet.name
    addressPrefix: networkConfiguration.podSubnet.prefix
    networkSecurityGroupResourceId: !enableVnetInjection ? clusterNetworkSecurityGroup.outputs.resourceId :null
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Network Contributor'
        principalId: identityId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}


/*
.__   __.      _______.  _______ 
|  \ |  |     /       | /  _____|
|   \|  |    |   (----`|  |  __  
|  . `  |     \   \    |  | |_ | 
|  |\   | .----)   |   |  |__| | 
|__| \__| |_______/     \______| 
*/
module clusterNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = if (!enableVnetInjection) {
  name: '${bladeConfig.sectionName}-nsg-cluster'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}-aks'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    securityRules: union(
      array(nsgRules.http_inbound_rule),
      array(nsgRules.https_inbound_rule),
      array(nsgRules.ssh_outbound)
    )
  }
}


/*
.__   __.  _______ .___________.____    __    ____  ______   .______       __  ___ 
|  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  / 
|   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /  
|  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <   
|  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \  
|__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\ 
*/
module network 'br/public:avm/res/network/virtual-network:0.5.1' = if (!enableVnetInjection) {
  name: '${bladeConfig.sectionName}-virtual-network'
  params: {
    name: '${replace(bladeConfig.sectionName, '-', '')}${uniqueString(resourceGroup().id, bladeConfig.sectionName)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: union(
      tags,
      {
        layer: bladeConfig.displayName
      }
    )

    addressPrefixes: [
      networkConfiguration.prefix
    ]

    // Hook up Diagnostics
    diagnosticSettings: [
      {
        name: 'LogAnalytics'
        workspaceResourceId: workspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principalId: identityId
        principalType: 'ServicePrincipal'
      }
    ]

    // Setup Subnets
    subnets: union(
      array(subnets.cluster),
      enablePodSubnet ? array(subnets.pods) : []
    )
  }
  dependsOn: [
    clusterNetworkSecurityGroup
  ]
}


// =============== //
//   Outputs       //
// =============== //

output networkConfiguration object = networkConfiguration
output vnetId string = enableVnetInjection ? resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name) : network.outputs.resourceId
output aksSubnetId string = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${networkConfiguration.aksSubnet.name}' : '${network.outputs.resourceId}/subnets/${networkConfiguration.aksSubnet.name}'
output podSubnetId string = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${networkConfiguration.podSubnet.name}' : '${network.outputs.resourceId}/subnets/${networkConfiguration.podSubnet.name}'


// =============== //
//   Definitions   //
// =============== //

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
}
