targetScope = 'resourceGroup'

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false

/////////////////
// Network Blade 
/////////////////
@description('Feature Flag to Enable a Pod Subnet')
param enablePodSubnet bool = false

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string = 'new'

@description('Name of the Virtual Network (Optional: If exiting Network is selected)')
param virtualNetworkName string = 'osdu-network'

@description('Resource group of the VNet (Optional: If exiting Network is selected)')
param virtualNetworkResourceGroup string = 'osdu-network'

@description('VNet address prefix')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('New or Existing subnet Name')
param aksSubnetName string = 'ClusterSubnet'

@description('Subnet address prefix')
param aksSubnetAddressPrefix string = '10.1.0.0/20'

@description('New or Existing subnet Name')
param bastionSubnetName string = 'AzureBastionSubnet'

@description('Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.')
param bastionSubnetAddressPrefix string = '10.1.16.0/24'

@description('New or Existing subnet Name')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.')
param gatewaySubnetAddressPrefix string = '10.1.17.0/24'

@description('Specifies the name of the subnet which contains the virtual machine.')
param vmSubnetName string = 'VmSubnet'

@description('Specifies the address prefix of the subnet which contains the virtual machine.')
param vmSubnetAddressPrefix string = '10.1.18.0/24'

@description('New or Existing subnet Name')
param podSubnetName string = 'PodSubnet'

@description('Subnet address prefix')
param podSubnetAddressPrefix string = '10.1.19.0/20'

@description('Feature Flag to Enable VPN Gateway Functionality')
param enableVpnGateway bool = false

@description('Shared Key for VPN Gateway')
@secure()
param vpnSharedKey string = ''

@description('IP Address of the Remote VPN Gateway')
param remoteVpnPrefix string = ''

@description('IP Address Segment of the Remote Network')
param remoteNetworkPrefix string = '192.168.1.0/24'


/////////////////
// Security Blade 
/////////////////
@description('Feature Flag to Enable Private Link')
param enablePrivateLink bool = false

@description('Optional. Customer Managed Encryption Key.')
param cmekConfiguration object = {
  kvUrl: ''
  keyName: ''
  identityId: ''
}


/////////////////
// Settings Blade 
/////////////////
@description('Specify the AD Application Client Id.')
param applicationClientId string


/////////////////
// Bastion Blade
/////////////////

@description('Feature Flag to Enable Bastion')
param enableBastion bool = false

@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string = enableBastion ? 'azureUser' : newGuid()

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string = enableBastion ? '' : newGuid()

//*****************************************************************//
//  Common Section                                                 //
//*****************************************************************//

/////////////////////////////////
//  Configuration 
/////////////////////////////////
var commonLayerConfig = {
  name: 'common'
  displayName: 'Common Resources'
  network: {
    name: 'vnet-common${uniqueString(resourceGroup().id, 'common')}'
  }
  secrets: {
    tenantId: 'tenant-id'
    subscriptionId: 'subscription-id'
    registryName: 'container-registry'
    applicationId: 'aad-client-id'
    clientId: 'app-dev-sp-username'
    clientSecret: 'app-dev-sp-password'
    applicationPrincipalId: 'app-dev-sp-id'
    stampIdentity: 'osdu-identity-id'
    storageAccountName: 'tbl-storage'
    storageAccountKey: 'tbl-storage-key'
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
  registry: {
    sku: 'Premium'
  }
  storage: {
    sku: 'Standard_LRS'
    tables: [
      'PartitionInfo'
    ]
  }
  database: {
    name: 'graph-db'
    throughput: 2000
    backup: 'Continuous'
    graphs: [
      {
        name: 'Entitlements'
        automaticIndexing: true
        partitionKeyPaths: [
          '/dataPartitionId'
        ]
      }
    ]
  }
}


/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/

module stampIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.0' = {
  name: '${commonLayerConfig.name}-user-managed-identity'
  params: {
    // Required parameters
    name: 'id-${replace(commonLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, commonLayerConfig.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }
  }
}


/*
.___  ___.   ______   .__   __.  __  .___________.  ______   .______       __  .__   __.   _______ 
|   \/   |  /  __  \  |  \ |  | |  | |           | /  __  \  |   _  \     |  | |  \ |  |  /  _____|
|  \  /  | |  |  |  | |   \|  | |  | `---|  |----`|  |  |  | |  |_)  |    |  | |   \|  | |  |  __  
|  |\/|  | |  |  |  | |  . `  | |  |     |  |     |  |  |  | |      /     |  | |  . `  | |  | |_ | 
|  |  |  | |  `--'  | |  |\   | |  |     |  |     |  `--'  | |  |\  \----.|  | |  |\   | |  |__| | 
|__|  |__|  \______/  |__| \__| |__|     |__|      \______/  | _| `._____||__| |__| \__|  \______|                                                                                                    
*/

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.2.1' = {
  name: '${commonLayerConfig.name}-log-analytics'
  params: {
    name: 'log-${replace(commonLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, commonLayerConfig.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    skuName: commonLayerConfig.logs.sku
  }
  dependsOn: [
    stampIdentity
  ]
}


/*
.__   __.  _______ .___________.____    __    ____  ______   .______       __  ___ 
|  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  / 
|   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /  
|  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <   
|  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \  
|__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\ 
*/

var vnetId = {
  new: virtualNetworkNewOrExisting == 'new' ? network.outputs.resourceId : null
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
}

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

  gateway_manager_inbound: {
    name: 'AllowGatewayManagerInbound'
    properties: {
      priority: 150
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'GatewayManager'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
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
    name: aksSubnetName
    addressPrefix: aksSubnetAddressPrefix
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
    networkSecurityGroupResourceId: clusterNetworkSecurityGroup.outputs.resourceId
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Network Contributor'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
  pods: {
    name: podSubnetName
    addressPrefix: podSubnetAddressPrefix
    networkSecurityGroupResourceId: clusterNetworkSecurityGroup.outputs.resourceId
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Network Contributor'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]
  }
  bastion: {
    name: bastionSubnetName
    addressPrefix: bastionSubnetAddressPrefix
    networkSecurityGroupResourceId: enableBastion ? bastionNetworkSecurityGroup.outputs.resourceId: null
  }
  gateway: {
    name: gatewaySubnetName
    addressPrefix: gatewaySubnetAddressPrefix
  }
  machine: {
    name: vmSubnetName
    addressPrefix: vmSubnetAddressPrefix
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

module clusterNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.0' = {
  name: '${commonLayerConfig.name}-network-security-group-cluster'
  params: {
    name: '${commonLayerConfig.network.name}-nsg-cluster'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    securityRules: union(
      array(nsgRules.http_inbound_rule),
      array(nsgRules.https_inbound_rule),
      array(nsgRules.ssh_outbound)
    )
  }
}

module bastionNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.0' = if (enableBastion) {
  name: '${commonLayerConfig.name}-network-security-group-bastion'
  params: {
    name: '${commonLayerConfig.network.name}-nsg-bastion'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    securityRules: union(
      array(nsgRules.https_inbound_rule),
      array(nsgRules.gateway_manager_inbound),
      array(nsgRules.load_balancer_inbound),
      array(nsgRules.bastion_host_communication),
      array(nsgRules.ssh_outbound),
      array(nsgRules.cloud_outbound),
      array(nsgRules.bastion_communication),
      array(nsgRules.allow_http_outbound)
    )
  }
}

module machineNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.0' = if (enableBastion) {
  name: '${commonLayerConfig.name}-network-security-group-manage'
  params: {
    name: '${commonLayerConfig.network.name}-nsg-machine'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    securityRules: []
  }
}

module network 'br/public:avm/res/network/virtual-network:0.1.0' = {
  name: '${commonLayerConfig.name}-virtual-network'
  params: {
    name: commonLayerConfig.network.name
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    addressPrefixes: [
      virtualNetworkAddressPrefix
    ]

    // Hook up Diagnostics
    diagnosticSettings: [
      {
        name: 'LogAnalytics'
        workspaceResourceId: logAnalytics.outputs.resourceId
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
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    // Setup Subnets
    subnets: union(
      array(subnets.cluster),
      enablePodSubnet ? array(subnets.pods) : [],
      enableBastion ? array(subnets.bastion) : [],
      enableBastion ? array(subnets.machine) : [],
      enableVpnGateway ? array(subnets.gateway) : []
    )
  }
  dependsOn: [
    logAnalytics
    clusterNetworkSecurityGroup
    bastionNetworkSecurityGroup
    machineNetworkSecurityGroup
  ]
}

resource virtualWan 'Microsoft.Network/virtualWans@2023-04-01' = {
  name: '${commonLayerConfig.network.name}-wan'
  location: location
}

resource virtualHub 'Microsoft.Network/virtualHubs@2022-01-01' = {
  name: '${commonLayerConfig.network.name}-hub'
  location: location
  properties: {
    virtualWan: {
      id: virtualWan.id
    }
    addressPrefix: virtualNetworkAddressPrefix
  }
}

/////////////////////////////////
// VPN Gateway
module vpnSite 'br/public:avm/res/network/vpn-site:0.1.0' = if (enableVpnGateway) {
  name: '${commonLayerConfig.name}-vpn-site'
  params: {
    // Required parameters
    name: '${commonLayerConfig.network.name}-vpn-site'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    virtualWanId: virtualWan.id
    addressPrefixes: [
      remoteNetworkPrefix
    ]
    ipAddress: remoteVpnPrefix    
  }
}

module vpnGateway 'br/public:avm/res/network/vpn-gateway:0.1.0' = if (enableVpnGateway) {
  name: '${commonLayerConfig.name}-vpn-gateway'
  params: {
    name: '${commonLayerConfig.network.name}-vpn-gw'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    virtualHubResourceId: virtualHub.id

    vpnConnections: [
      {
        name: '${commonLayerConfig.network.name}-vpn-connection'
        connectionBandwidth: 100
        enableBgp: false
        enableInternetSecurity: true
        enableRateLimiting: false
        sharedKey: vpnSharedKey
        remoteVpnSiteResourceId: enableVpnGateway ? vpnSite.outputs.resourceId : null
        routingWeight: 0
        useLocalAzureIpAddress: false
        usePolicyBasedTrafficSelectors: false
        vpnConnectionProtocolType: 'IKEv2'
      }
    ]
  }
}




/*
 __  ___  ___________    ____ ____    ____  ___      __    __   __      .___________.
|  |/  / |   ____\   \  /   / \   \  /   / /   \    |  |  |  | |  |     |           |
|  '  /  |  |__   \   \/   /   \   \/   / /  ^  \   |  |  |  | |  |     `---|  |----`
|    <   |   __|   \_    _/     \      / /  /_\  \  |  |  |  | |  |         |  |     
|  .  \  |  |____    |  |        \    / /  _____  \ |  `--'  | |  `----.    |  |     
|__|\__\ |_______|   |__|         \__/ /__/     \__\ \______/  |_______|    |__|                                                                     
*/

var vaultDNSZoneName = 'privatelink.vaultcore.azure.net'

module keyvault 'br:osdubicep.azurecr.io/public/azure-keyvault:1.0.7' = {
  name: '${commonLayerConfig.name}-azure-keyvault'
  params: {
    resourceName: commonLayerConfig.name
    location: location
    
    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Access
    accessPolicies: [
      {
        principalId: stampIdentity.outputs.principalId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
          ]
          certificates: [
            'create'
            'get'
            'list'
          ]
        }
      }
    ]

    // Configure Secrets
    secretsObject: { secrets: [
      // Misc Secrets
      {
        secretName: commonLayerConfig.secrets.tenantId
        secretValue: subscription().tenantId
      }
      {
        secretName: commonLayerConfig.secrets.subscriptionId
        secretValue: subscription().subscriptionId
      }
      // Azure AD Secrets
      {
        secretName: commonLayerConfig.secrets.clientId
        secretValue: applicationClientId
      }
      {
        secretName: commonLayerConfig.secrets.applicationPrincipalId
        secretValue: applicationClientId
      }
      // Managed Identity
      {
        secretName: commonLayerConfig.secrets.stampIdentity
        secretValue: stampIdentity.outputs.principalId
      }
    ]}

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Reader'
        principals: [
          {
            id: stampIdentity.outputs.principalId
            resourceId: stampIdentity.outputs.resourceId
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module keyvaultSecrets './modules/keyvault_secrets.bicep' = {
  name: '${commonLayerConfig.name}-log-analytics-secrets'
  params: {
    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    workspaceName: logAnalytics.outputs.name
    workspaceIdName: commonLayerConfig.secrets.logAnalyticsId
    workspaceKeySecretName: commonLayerConfig.secrets.logAnalyticsKey
  }
}

module sshKey 'br:osdubicep.azurecr.io/public/script-sshkeypair:1.0.3' = if (enableBastion) {
  name: '${commonLayerConfig.name}-azure-keyvault-sshkey'
  params: {
    kvName: keyvault.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: stampIdentity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    sshKeyName: 'PrivateLinkSSHKey-'
    
    cleanupPreference: 'Always'
  }
}

module certificates './modules/script-kv-certificate/main.bicep' = {
  name: '${commonLayerConfig.name}-azure-keyvault-cert'
  params: {
    kvName: keyvault.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: stampIdentity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName: resourceGroup().name

    certificateNames: [
      'https-certificate'
    ]
    initialScriptDelay: '0'
    validity: 24
  }
}

resource vaultDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: vaultDNSZoneName
  location: 'global'
  properties: {}
}

module vaultEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-azure-keyvault-endpoint'
  params: {
    resourceName: keyvault.outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'

    groupIds: [ 'vault']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [vaultDNSZone.id]
    }
    serviceResourceId: keyvault.outputs.id
  }
  dependsOn: [
    network
    vaultDNSZone
  ]
}

resource existingVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyvault.outputs.name
}


/*   _______.___________.  ______   .______          ___       _______  _______ 
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__   
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|  
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____ 
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|                                                                 
*/

var storageDNSZoneForwarder = 'blob.${environment().suffixes.storage}'
var storageDnsZoneName = 'privatelink.${storageDNSZoneForwarder}'

module configStorage 'br:osdubicep.azurecr.io/public/storage-account:1.0.7' = {
  name: '${commonLayerConfig.name}-azure-storage'
  params: {
    resourceName: commonLayerConfig.name
    location: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sku: commonLayerConfig.storage.sku
    tables: commonLayerConfig.storage.tables

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principals: [
          {
            id: stampIdentity.outputs.principalId
            resourceId: stampIdentity.outputs.resourceId
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Hookup Customer Managed Encryption Key
    cmekConfiguration: cmekConfiguration

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    storageAccountSecretName: commonLayerConfig.secrets.storageAccountName
    storageAccountKeySecretName: commonLayerConfig.secrets.storageAccountKey
  }
}

resource storageDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: storageDnsZoneName
  location: 'global'
  properties: {}
}

module storageEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-azure-storage-endpoint'
  params: {
    resourceName: configStorage.outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'
    serviceResourceId: configStorage.outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZone.id]
    }
  }
  dependsOn: [
    network
    storageDNSZone
  ]
}


/*
  _______ .______          ___      .______    __    __  
 /  _____||   _  \        /   \     |   _  \  |  |  |  | 
|  |  __  |  |_)  |      /  ^  \    |  |_)  | |  |__|  | 
|  | |_ | |      /      /  /_\  \   |   ___/  |   __   | 
|  |__| | |  |\  \----./  _____  \  |  |      |  |  |  | 
 \______| | _| `._____/__/     \__\ | _|      |__|  |__| 
*/

var cosmosDnsZoneName = 'privatelink.documents.azure.com'

module database 'br:osdubicep.azurecr.io/public/cosmos-db:1.0.17' = {
  name: '${commonLayerConfig.name}-cosmos-db'
  params: {
    resourceName: commonLayerConfig.name
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    capabilitiesToAdd: [
      'EnableGremlin'
    ]
    gremlinDatabases: [
      {
        name: commonLayerConfig.database.name
        graphs: commonLayerConfig.database.graphs
      }
    ]
    throughput: commonLayerConfig.database.throughput
    backupPolicyType: commonLayerConfig.database.backup

    // Assign RBAC
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principals: [
          {
            id: stampIdentity.outputs.principalId
            resourceId: stampIdentity.outputs.resourceId
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${stampIdentity.outputs.resourceId}': {}
      '${cmekConfiguration.identityId}': {}
    } : {
      '${stampIdentity.outputs.resourceId}': {}
    }
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: commonLayerConfig.secrets.cosmosEndpoint
    databasePrimaryKeySecretName: commonLayerConfig.secrets.cosmosPrimaryKey
    databaseConnectionStringSecretName: commonLayerConfig.secrets.cosmosConnectionString
  }
}

resource cosmosDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateLink) {
  name: cosmosDnsZoneName
  location: 'global'
  properties: {}
}
module graphEndpoint 'br:osdubicep.azurecr.io/public/private-endpoint:1.0.1' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-cosmos-db-endpoint'
  params: {
    resourceName: database.outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'
    serviceResourceId: database.outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZone.id]
    }
  }
  dependsOn: [
    network
    cosmosDNSZone
  ]
}



//*****************************************************************//
//  Manage Section                                                 //
//*****************************************************************//

/////////////////////////////////
// Configuration 
/////////////////////////////////
var manageLayerConfig = {
  name: 'manage'
  displayName: 'Manage Resources'
  machine: {
    vmSize: 'Standard_DS3_v2'
    imagePublisher: 'Canonical'
    imageOffer: 'UbuntuServer'
    imageSku: '18.04-LTS'
    authenticationType: 'password'
  }
}

/*.______        ___           _______.___________. __    ______   .__   __. 
|   _  \      /   \         /       |           ||  |  /  __  \  |  \ |  | 
|  |_)  |    /  ^  \       |   (----`---|  |----`|  | |  |  |  | |   \|  | 
|   _  <    /  /_\  \       \   \       |  |     |  | |  |  |  | |  . `  | 
|  |_)  |  /  _____  \  .----)   |      |  |     |  | |  `--'  | |  |\   | 
|______/  /__/     \__\ |_______/       |__|     |__|  \______/  |__| \__| 
*/

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.0' = if (enableBastion) {
  name: '${manageLayerConfig.name}-bastion'
  params: {
    name: 'bh-${replace(manageLayerConfig.name, '-', '')}${uniqueString(deployment().name, manageLayerConfig.name)}'
    vNetId: network.outputs.resourceId
    location: location
    enableTelemetry: enableTelemetry
  }  
}

/*
.___  ___.      ___       ______  __    __   __  .__   __.  _______ 
|   \/   |     /   \     /      ||  |  |  | |  | |  \ |  | |   ____|
|  \  /  |    /  ^  \   |  ,----'|  |__|  | |  | |   \|  | |  |__   
|  |\/|  |   /  /_\  \  |  |     |   __   | |  | |  . `  | |   __|  
|  |  |  |  /  _____  \ |  `----.|  |  |  | |  | |  |\   | |  |____ 
|__|  |__| /__/     \__\ \______||__|  |__| |__| |__| \__| |_______|
                                                                    
*/

module virtualMachine './modules/virtual_machine.bicep' = if (enableBastion) {
  name: 'virtualMachine'
  params: {
    vmName: '${manageLayerConfig.name}-vm'
    vmSize: manageLayerConfig.machine.vmSize

    // Assign Tags
    tags: {
      layer: manageLayerConfig.displayName
    }

    vmSubnetId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${vmSubnetName}'
    vmAdminPasswordOrKey: empty(vmAdminPasswordOrKey) ? existingVault.getSecret('PrivateLinkSSHKey-public') : vmAdminPasswordOrKey
    vmAdminUsername: vmAdminUsername
    workspaceName: logAnalytics.outputs.name
    authenticationType: empty(vmAdminPasswordOrKey) ? 'sshPublicKey' : 'password'
  }
  dependsOn: [
    logAnalytics
    bastionHost
    sshKey
  ]
}
