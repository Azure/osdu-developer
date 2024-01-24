targetScope = 'resourceGroup'

@description('Specify the Azure region to place the application definition.')
param location string = resourceGroup().location

@description('Specify the AD Application Client Id.')
param applicationClientId string

@description('Feature Flag to Enable Telemetry')
param enableTelemetry bool = false

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


//*****************************************************************//
//  Common Section                                                 //
//*****************************************************************//

/////////////////////////////////
//  Configuration 
/////////////////////////////////
var commonLayerConfig = {
  name: 'common'
  displayName: 'Common Resources'
  // network: {
  //   name: 'vnet-common${uniqueString(resourceGroup().id, 'common')}'
  // }
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

/////////////////
// Network Blade 
/////////////////
@description('Feature Flag to Enable VPN Gateway Functionality')
param enableVirtualWAN bool = false

@description('VNet address prefix')
param virtualNetworkAddressPrefix string = '10.1.0.0/16'

@description('New or Existing subnet Name')
param aksSubnetName string = 'ClusterSubnet'

@description('Subnet address prefix')
param aksSubnetAddressPrefix string = '10.1.0.0/20'

// -

@description('Feature Flag to Enable VPN Gateway Functionality')
param enableVpnGateway bool = false

@description('Shared Key for VPN Gateway')
@secure()
param vpnSharedKey string = ''

@description('IP Address of the Remote VPN Gateway')
param remoteVpnAddress string = ''

@description('IP Address Segment of the Remote Network')
param remoteNetworkPrefix string = '192.168.1.0/24'

@description('New or Existing subnet Name')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.')
param gatewaySubnetAddressPrefix string = '10.1.17.0/24'

// --

@description('Feature Flag to Enable Bastion')
param enableBastion bool = false

@description('New or Existing subnet Name')
param bastionSubnetName string = 'AzureBastionSubnet'

@description('Specifies the Bastion subnet IP prefix. This prefix must be within vnet IP prefix address space.')
param bastionSubnetAddressPrefix string = '10.1.16.0/24'

@description('Specifies the name of the subnet which contains the virtual machine.')
param vmSubnetName string = 'VmSubnet'

@description('Specifies the address prefix of the subnet which contains the virtual machine.')
param vmSubnetAddressPrefix string = '10.1.18.0/24'

// --

@description('Feature Flag to Enable a Pod Subnet')
param enablePodSubnet bool = false

@description('New or Existing subnet Name')
param podSubnetName string = 'PodSubnet'

@description('Subnet address prefix')
param podSubnetAddressPrefix string = '10.1.20.0/22'

// --

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string = 'new'

@description('Name of the Virtual Network (Optional: If exiting Network is selected)')
param virtualNetworkName string = 'osdu-network'

@description('Resource group of the VNet (Optional: If exiting Network is selected)')
param virtualNetworkResourceGroup string = 'osdu-network'

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
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-aks'
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
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-bastion'
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
    name: 'nsg-common${uniqueString(resourceGroup().id, 'common')}-vm'
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
    name: 'vnet-common${uniqueString(resourceGroup().id, 'common')}'
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
      enableBastion ? array(subnets.bastion) : [],
      enableBastion ? array(subnets.machine) : [],
      enableVpnGateway ? array(subnets.gateway) : [],
      enablePodSubnet ? array(subnets.pods) : []
    )
  }
  dependsOn: [
    logAnalytics
    clusterNetworkSecurityGroup
    bastionNetworkSecurityGroup
    machineNetworkSecurityGroup
  ]
}

resource virtualWan 'Microsoft.Network/virtualWans@2023-06-01' = if (enableVirtualWAN || enableVpnGateway) {
  name: 'wan-common${uniqueString(resourceGroup().id, 'common')}'
  location: location
}

resource virtualHub 'Microsoft.Network/virtualHubs@2023-06-01' = if (enableVirtualWAN || enableVpnGateway) {
  name: 'hub-common${uniqueString(resourceGroup().id, 'common')}'
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
    name: 'vpn-site-common${uniqueString(resourceGroup().id, 'common')}'
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
    ipAddress: remoteVpnAddress    
  }
}

module vpnGateway 'br/public:avm/res/network/vpn-gateway:0.1.0' = if (enableVpnGateway) {
  name: '${commonLayerConfig.name}-vpn-gateway'
  params: {
    name: 'vpn-gw-common${uniqueString(resourceGroup().id, 'common')}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    virtualHubResourceId: virtualHub.id

    vpnConnections: [
      {
        name: 'vpn-connect-common${uniqueString(resourceGroup().id, 'common')}'
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

var vnetId = {
  new: virtualNetworkNewOrExisting == 'new' ? network.outputs.resourceId : null
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
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

var vaultSecrets = [ 
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
]
module keyvault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: '${commonLayerConfig.name}-azure-keyvault'
  params: {
    name: 'kv-${replace(commonLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, commonLayerConfig.name)}'
    location: location
    enableTelemetry: enableTelemetry
    
    // Assign Tags
    tags: {
      layer: commonLayerConfig.displayName
    }

    enablePurgeProtection: false
    
    // Configure RBAC
    enableRbacAuthorization: true
    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Key Vault Reader'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    // Configure Secrets
    secrets: {
      secureList: [for secret in vaultSecrets: {
        name: secret.secretName
        value: secret.secretValue
      }]
    }
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
    stampIdName: commonLayerConfig.secrets.stampIdentity
    stampIdValue: stampIdentity.outputs.principalId
  }
}

// Deployment Scripts are not enabled yet for Private Link
// https://github.com/Azure/bicep/issues/6540
module sshKey './modules/script-sshkeypair/main.bicep' = {
  name: '${commonLayerConfig.name}-azure-keyvault-sshkey'
  params: {
    kvName: keyvault.outputs.name
    location: location

    useExistingManagedIdentity: true
    managedIdentityName: stampIdentity.outputs.name
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName:resourceGroup().name

    sshKeyName: 'PrivateLinkSSHKey-'
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

module vaultEndpoint './modules/private-endpoint/main.bicep' = if (enablePrivateLink) {
  name: '${commonLayerConfig.name}-azure-keyvault-pep'
  params: {
    resourceName: keyvault.outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'

    groupIds: [ 'vault']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [vaultDNSZone.id]
    }
    serviceResourceId: keyvault.outputs.resourceId
  }
  dependsOn: [
    network
    vaultDNSZone
  ]
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

module configStorage './modules/storage-account/main.bicep' = {
  name: '${commonLayerConfig.name}-azure-storage'
  params: {
    name: 'sa${replace(commonLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, commonLayerConfig.name)}'
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

module storageEndpoint './modules/private-endpoint/main.bicep' = if (enablePrivateLink) {
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

module database './modules/cosmos-db/main.bicep' = {
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

module graphEndpoint './modules/private-endpoint/main.bicep' = if (enablePrivateLink) {
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

resource existingVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyvault.outputs.name
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
    name: 'bh-${replace(manageLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, manageLayerConfig.name)}'
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

@description('Specifies the name of the administrator account of the virtual machine.')
param vmAdminUsername string = enableBastion ? 'azureUser' : newGuid()

@description('Specifies the SSH Key or password for the virtual machine. SSH key is recommended.')
@secure()
param vmAdminPasswordOrKey string = enableBastion ? '' : newGuid()

module virtualMachine './modules/virtual_machine.bicep' = if (enableBastion) {
  name: 'virtualMachine'
  params: {
    vmName: 'vm-${replace(manageLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, manageLayerConfig.name)}'
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



//*****************************************************************//
//  Partition Section                                              //
//*****************************************************************//

@allowed([
  'CostOptimised'
  'Standard'
  'HighSpec'
])
@description('The Cluster Size')
param clusterSize string = 'CostOptimised'

@description('List of Data Partitions')
param partitions array = [
  {
    name: 'opendes'
  }
]

/////////////////////////////////
// Configuration 
/////////////////////////////////
var partitionLayerConfig = {
  name: 'partition'
  displayName: 'Data Partition Resources'
  secrets: {
    storageAccountName: 'storage'
    storageAccountKey: 'key'
    cosmosConnectionString: 'cosmos-connection'
    cosmosEndpoint: 'cosmos-endpoint'
    cosmosPrimaryKey: 'cosmos-primary-key'
  }
  storage: {
    sku: 'Standard_LRS'
    containers: [
      'legal-service-azure-configuration'
      'osdu-wks-mappings'
      'wdms-osdu'
      'file-staging-area'
      'file-persistent-area'
    ]
  }
  database: {
    name: 'osdu-db'
    CostOptimised : {
      throughput: 2000
    }
    Standard: {
      throughput: 4000
    }
    HighSpec: {
      throughput: 12000
    }
    backup: 'Continuous'
    containers: [
      {
        name: 'LegalTag'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageRecord'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'StorageSchema'
        kind: 'Hash'
        paths: [
          '/kind'
        ]
      }
      {
        name: 'TenantInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'UserInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'Authority'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'EntityType'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'SchemaInfo'
        kind: 'Hash'
        paths: [
          '/partitionId'
        ]
      }
      {
        name: 'Source'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'RegisterAction'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterDdms'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'RegisterSubscription'
        kind: 'Hash'
        paths: [
          '/dataPartitionId'
        ]
      }
      {
        name: 'IngestionStrategy'
        kind: 'Hash'
        paths: [
          '/workflowType'
        ]
      }
      {
        name: 'RelationshipStatus'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'MappingInfo'
        kind: 'Hash'
        paths: [
          '/sourceSchemaKind'
        ]
      }
      {
        name: 'FileLocationInfo'
        kind: 'Hash'
        paths: [
          '/id'
        ]
      }
      {
        name: 'WorkflowCustomOperatorInfo'
        kind: 'Hash'
        paths: [
          '/operatorId'
        ]
      }
      {
        name: 'WorkflowV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowRunV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowCustomOperatorV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'WorkflowTasksSharingInfoV2'
        kind: 'Hash'
        paths: [
          '/partitionKey'
        ]
      }
      {
        name: 'Status'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
      {
        name: 'DataSetDetails'
        kind: 'Hash'
        paths: [
          '/correlationId'
        ]
      }
    ]
  }
}



/*
.______      ___      .______     .___________. __  .___________. __    ______   .__   __.      _______.
|   _  \    /   \     |   _  \    |           ||  | |           ||  |  /  __  \  |  \ |  |     /       |
|  |_)  |  /  ^  \    |  |_)  |   `---|  |----`|  | `---|  |----`|  | |  |  |  | |   \|  |    |   (----`
|   ___/  /  /_\  \   |      /        |  |     |  |     |  |     |  | |  |  |  | |  . `  |     \   \    
|  |     /  _____  \  |  |\  \----.   |  |     |  |     |  |     |  | |  `--'  | |  |\   | .----)   |   
| _|    /__/     \__\ | _| `._____|   |__|     |__|     |__|     |__|  \______/  |__| \__| |_______/                                 
*/

module partitionStorage './modules/storage-account/main.bicep' = [for (partition, index) in partitions:  {
  name: '${partitionLayerConfig.name}-azure-storage-${index}'
  params: {
    #disable-next-line BCP335 BCP332
    name: 'sa${replace('data${index}${substring(uniqueString(partition.name), 0, 6)}', '-', '')}${uniqueString(resourceGroup().id, 'data${index}${substring(uniqueString(partition.name), 0, 6)}')}'
    location: location

    // Assign Tags
    tags: {
      layer: partitionLayerConfig.displayName
      partition: partition.name
      purpose: 'data'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sku: partitionLayerConfig.storage.sku
    containers: concat(partitionLayerConfig.storage.containers, [partition.name])

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
    storageAccountSecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountName}'
    storageAccountKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.storageAccountKey}'
  }
}]

module partitionStorageEndpoint './modules/private-endpoint/main.bicep' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${partitionLayerConfig.name}-azure-storage-endpoint-${index}'
  params: {
    resourceName: partitionStorage[index].outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'
    serviceResourceId: partitionStorage[index].outputs.id
    groupIds: [ 'blob']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [storageDNSZone.id]
    }
  }
  dependsOn: [
    network
    storageDNSZone
  ]
}]

module partitionDb './modules/cosmos-db/main.bicep' = [for (partition, index) in partitions: { 
  name: '${partitionLayerConfig.name}-cosmos-db-${index}'
  params: {
    #disable-next-line BCP335
    resourceName: 'data${index}${substring(uniqueString(partition.name), 0, 6)}'
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: partitionLayerConfig.displayName
      partition: partition.name
      purpose: 'data'
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    // Configure Service
    sqlDatabases: [
      {
        name: partitionLayerConfig.database.name
        containers: partitionLayerConfig.database.containers
      }
    ]
    maxThroughput: partitionLayerConfig.database[clusterSize].throughput
    backupPolicyType: partitionLayerConfig.database.backup

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
    databaseEndpointSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosEndpoint}'
    databasePrimaryKeySecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosPrimaryKey}'
    databaseConnectionStringSecretName: '${partition.name}-${partitionLayerConfig.secrets.cosmosConnectionString}'
  }
}]

module partitionDbEndpoint './modules/private-endpoint/main.bicep' = [for (partition, index) in partitions: if (enablePrivateLink) {
  name: '${partitionLayerConfig.name}-cosmos-db-endpoint-${index}'
  params: {
    resourceName: partitionDb[index].outputs.name
    subnetResourceId: '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}'
    serviceResourceId: partitionDb[index].outputs.id
    groupIds: [ 'sql']
    privateDnsZoneGroup: {
      privateDNSResourceIds: [cosmosDNSZone.id]
    }
  }
  dependsOn: [
    network
    cosmosDNSZone
  ]
}]



//*****************************************************************//
//  Service Section                                               //
//*****************************************************************//
@description('Feature Flag to create software config map.')
var enableConfigMap = true

@description('Feature Flag to Load Software.')
var enableSoftwareLoad = true

@description('Software GIT Repository URL')
param softwareRepository string = 'https://github.com/azure/osdu-developer'

@description('Software GIT Repository Branch')
param softwareBranch string = 'main'

@allowed([
  'Internal'
  'External'
  'Both'
])
@description('The Cluster Ingress Mode')
param clusterIngress string = 'Both'

@description('Optional: Specify the AD Users and/or Groups that can manage the cluster.')
param clusterAdminIds array = []

/////////////////////////////////
// Configuration 
/////////////////////////////////

var serviceLayerConfig = {
  name: 'service'
  displayName: 'Service Resources'
  cluster: {
    aksVersion: '1.28'
    meshVersion: 'asm-1-18'
    networkPlugin: 'kubenet'
  }
  gitops: {
    name: 'flux-system'
    url: softwareRepository
    branch: softwareBranch
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

module cluster './modules/aks_cluster.bicep' = {
  name: '${serviceLayerConfig.name}-aks-cluster'
  params: {
    // Basic Details
    resourceName: serviceLayerConfig.name
    location: location
    aksVersion: serviceLayerConfig.cluster.aksVersion
    aad_tenant_id: subscription().tenantId
    clusterSize: clusterSize
    networkPlugin: serviceLayerConfig.cluster.networkPlugin

    // Assign Tags
    tags: {
      layer: serviceLayerConfig.displayName
    }

    // Configure Linking Items
    aksSubnetId: virtualNetworkNewOrExisting != 'new' ? '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}' : '${vnetId[virtualNetworkNewOrExisting]}/subnets/${aksSubnetName}' 
    aksPodSubnetId: virtualNetworkNewOrExisting != 'new' && enablePodSubnet ? '${vnetId[virtualNetworkNewOrExisting]}/subnets/${podSubnetName}' : null
    identityId: stampIdentity.outputs.resourceId
    workspaceId: logAnalytics.outputs.resourceId

    // Configure Istio
    serviceMeshProfile: 'Istio'
    istioRevision: serviceLayerConfig.cluster.meshVersion
    istioIngressGatewayMode: clusterIngress

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

module espool1 './modules/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool1'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz1'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '1'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}

module espool2 './modules/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool2'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz2'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '2'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}

module espool3 './modules/aks_agent_pool.bicep' = {
  name: '${serviceLayerConfig.name}-espool3'
  params: {
    AksName: cluster.outputs.aksClusterName
    PoolName: 'espoolz3'
    agentVMSize: elasticPoolPresets[clusterSize].vmSize
    agentCount: 2
    agentCountMax: 4
    availabilityZones: [
      '3'
    ]
    subnetId: ''
    nodeTaints: ['app=elasticsearch:NoSchedule']
    nodeLabels: {
      app: 'elasticsearch'
    }
  }
}


/////////////////
// Workload Identity Federated Credentials 
/////////////////
module appIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.1.0' = {
  name: '${serviceLayerConfig.name}-user-managed-identity'
  params: {
    // Required parameters
    name: 'id-${replace(serviceLayerConfig.name, '-', '')}${uniqueString(resourceGroup().id, serviceLayerConfig.name)}'
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

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Managed Identity Operator'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    // Assign Tags
    tags: {
      layer: serviceLayerConfig.displayName
    }
  }
}

// Federated Credentials have to be sequentially added.  Ensure depends on.
module federatedCredsDevSample './modules/federated_identity.bicep' = {
  name: '${serviceLayerConfig.name}-federated-cred-ns_dev-sample'
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
    appIdentity
  ]
}

module appRoleAssignments './modules/app_assignments.bicep' = {
  name: '${serviceLayerConfig.name}-user-managed-identity-operator'
  params: {
    operatorIdentityName: stampIdentity.outputs.name
    identityclientId: appIdentity.outputs.clientId
    kvName: keyvault.outputs.name
  }
  dependsOn: [
    federatedCredsDevSample
  ]
}

/////////////////
// Helm Charts 
/////////////////
module helmAppConfigProvider './modules/aks-run-command/main.bicep' = {
  name: '${serviceLayerConfig.name}-helm-AppConfigProvider'
  params: {
    aksName: cluster.outputs.aksClusterName
    location: location

    newOrExistingManagedIdentity: 'existing'
    managedIdentityName: stampIdentity.outputs.name
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

var appSettings = [
  {
    name: 'Settings:FontColor'
    value: 'Green'
    contentType: 'text/plain'
    label: 'ConfigMap-Sample'
  }
  {
    name: 'Settings:Message'
    value: 'Hello from App Configuration'
    contentType: 'text/plain'
    label: 'ConfigMap-Sample'
  }
]

module app_config 'modules/app-configuration/main.bicep' = {
  name: '${serviceLayerConfig.name}-appconfig'
  params: {
    resourceName: serviceLayerConfig.name
    location: location
    tags: {
      layer: serviceLayerConfig.displayName
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
    keyValues: concat(appSettings)
  }
  dependsOn: [
    appRoleAssignments
  ]
}

@description('The name of the azure keyvault.')
output ENV_CONFIG_ENDPOINT string = app_config.outputs.endpoint

//--------------Config Map---------------
var configMaps = {
  devSampleTemplate: '''
values.yaml: |
  serviceAccount:
    create: false
    name: "workload-identity-sa"
  azure:
    enabled: true
    tenantId: "{0}"
    clientId: {1}
    configEndpoint: {2}
    keyvaultName: {3}
'''
}

module devSampleMap './modules/aks-config-map/main.bicep' = if (enableConfigMap) {
  name: '${serviceLayerConfig.name}-cluster-workloadidentitymap'
  params: {
    aksName: cluster.outputs.aksClusterName
    location: location
    name: 'dev-sample-values'
    namespace: 'default'
    fileData: [
      format(configMaps.devSampleTemplate, 
             subscription().tenantId, 
             appIdentity.outputs.clientId,
             app_config.outputs.endpoint,
             keyvault.outputs.name)
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
  name: '${serviceLayerConfig.name}-cluster-gitops'
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
    devSampleMap
    espool1
    espool2
    espool3
  ]
}

//ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
