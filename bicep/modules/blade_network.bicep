/////////////////
// Network Blade 
/////////////////
// import * as type from 'types.bicep'

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

@description('The configuration for the blade section.')
param bladeConfig bladeSettings

@description('The location of resources to deploy')
param location string

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false

@description('The workspace resource Id for diagnostics')
param workspaceResourceId string

@description('Optional. Bring your own Virtual Network.')
param vnetConfiguration vnetSettings

@description('Feature Flag to Enable Bastion')
param enableBastion bool

@description('Feature Flag to Enable a Pod Subnet')
param enablePodSubnet bool

@description('Feature Flag to Enable a Pod Subnet')
param enableVnetInjection bool

@description('The Managed Identity Principal Id')
param identityId string

var networkConfiguration = vnetConfiguration.name == '' ? {
  prefix: '10.1.0.0/16'
  aksSubnet: {
    name: 'ClusterSubnet'
    prefix: '10.1.0.0/20'
  }
  podSubnet: {
    name: 'PodSubnet'
    prefix: '10.1.20.0/22'
  }
  vmSubnet: {
    name: 'VmSubnet'
    prefix: '10.1.18.0/24'
  }
  bastionSubnet: {
    name: 'AzureBastionSubnet'
    prefix: '10.1.16.0/24'
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

  bastion_communication: {
    name: 'AllowBastionCommunication'
    properties: {
      priority: 130
      protocol: '*'
      access: 'Allow'
      direction: 'Outbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
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

  bastion_host_communication: {
    name: 'AllowBastionHostCommunication'
    properties: {
      priority: 170
      protocol: '*'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationPortRanges: [
        '8080'
        '5701'
      ]
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
  bastion: {
    name: networkConfiguration.bastionSubnet.name
    addressPrefix: networkConfiguration.bastionSubnet.prefix
    networkSecurityGroupResourceId: enableBastion ? bastionNetworkSecurityGroup.outputs.resourceId: null
  }
  machine: {
    name: networkConfiguration.vmSubnet.name
    addressPrefix: networkConfiguration.vmSubnet.prefix
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
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroupResourceId: enableBastion ?  machineNetworkSecurityGroup.outputs.resourceId : null
  }
}

module clusterNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.3' = if (!enableVnetInjection) {
  name: '${bladeConfig.sectionName}-nsg-cluster'
  params: {
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-aks'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

    securityRules: union(
      array(nsgRules.http_inbound_rule),
      array(nsgRules.https_inbound_rule),
      array(nsgRules.ssh_outbound)
    )
  }
}

module bastionNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.3' = if (!enableVnetInjection && enableBastion) {
  name: '${bladeConfig.sectionName}-nsg-bastion'
  params: {
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-bastion'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

    securityRules: union(
      array(nsgRules.https_inbound_rule),
      array(nsgRules.load_balancer_inbound),
      array(nsgRules.bastion_host_communication),
      array(nsgRules.ssh_outbound),
      array(nsgRules.cloud_outbound),
      array(nsgRules.bastion_communication),
      array(nsgRules.allow_http_outbound)
    )
  }
}

module machineNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.3' = if (!enableVnetInjection && enableBastion) {
  name: '${bladeConfig.sectionName}-nsg-manage'
  params: {
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-vm'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

    securityRules: []
  }
}

module network 'br/public:avm/res/network/virtual-network:0.1.5' = if (!enableVnetInjection) {
  name: '${bladeConfig.sectionName}-virtual-network'
  params: {
    name: 'vnet-common${uniqueString(resourceGroup().id, 'common')}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: bladeConfig.displayName
    }

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
      enablePodSubnet ? array(subnets.pods) : [],
      enableBastion ? array(subnets.bastion) : [],
      enableBastion ? array(subnets.machine) : []
    )
  }
  dependsOn: [
    clusterNetworkSecurityGroup
    bastionNetworkSecurityGroup
    machineNetworkSecurityGroup
  ]
}

output networkConfiguration object = networkConfiguration
output vnetId string = enableVnetInjection ? resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name) : network.outputs.resourceId
output aksSubnetId string = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${networkConfiguration.aksSubnet.name}' : '${network.outputs.resourceId}/subnets/${networkConfiguration.aksSubnet.name}'
output vmSubnetId string = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${networkConfiguration.vmSubnet.name}' : '${network.outputs.resourceId}/subnets/${networkConfiguration.vmSubnet.name}'
output podSubnetId string = enableVnetInjection ? '${resourceId(networkConfiguration.group, 'Microsoft.Network/virtualNetworks', networkConfiguration.name)}/subnets/${networkConfiguration.podSubnet.name}' : '${network.outputs.resourceId}/subnets/${networkConfiguration.podSubnet.name}'
