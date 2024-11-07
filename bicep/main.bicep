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
  registry: {
    sku: 'Basic'
  }
  insights: {
    sku: 'web'
  }
  storage: {
    sku: 'Standard_LRS'
    containers: [
      'system'
      'azure-webjobs-hosts'
      'azure-webjobs-eventhub'
      'gitops'
    ]
    tables: [
      'partitionInfo'
    ]
    shares: [
      'airflow-logs'
      'airflow-dags'
    ]
  }
  partitions: [
    {
      name: 'opendes'
    }
  ]
}

var rg_unique_id = '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'


/*
 __   _______   _______ .__   __. .___________. __  .___________.____    ____ 
|  | |       \ |   ____||  \ |  | |           ||  | |           |\   \  /   / 
|  | |  .--.  ||  |__   |   \|  | `---|  |----`|  | `---|  |----` \   \/   /  
|  | |  |  |  ||   __|  |  . `  |     |  |     |  |     |  |       \_    _/   
|  | |  '--'  ||  |____ |  |\   |     |  |     |  |     |  |         |  |     
|__| |_______/ |_______||__| \__|     |__|     |__|     |__|         |__|     
*/
module stampIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
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


/*
     ___      .__   __.      ___       __      ____    ____ .___________. __    ______     _______.
    /   \     |  \ |  |     /   \     |  |     \   \  /   / |           ||  |  /      |   /       |
   /  ^  \    |   \|  |    /  ^  \    |  |      \   \/   /  `---|  |----`|  | |  ,----'  |   (----`
  /  /_\  \   |  . `  |   /  /_\  \   |  |       \_    _/       |  |     |  | |  |        \   \    
 /  _____  \  |  |\   |  /  _____  \  |  `----.    |  |         |  |     |  | |  `----.----)   |   
/__/     \__\ |__| \__| /__/     \__\ |_______|    |__|         |__|     |__|  \______|_______/    
*/
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.7.1' = {
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


/*
 __  .__   __.      _______. __    _______  __    __  .___________.    _______.
|  | |  \ |  |     /       ||  |  /  _____||  |  |  | |           |   /       |
|  | |   \|  |    |   (----`|  | |  |  __  |  |__|  | `---|  |----`  |   (----`
|  | |  . `  |     \   \    |  | |  | |_ | |   __   |     |  |        \   \    
|  | |  |\   | .----)   |   |  | |  |__| | |  |  |  |     |  |    .----)   |   
|__| |__| \__| |_______/    |__|  \______| |__|  |__|     |__|    |_______/    
*/

module insights 'br/public:avm/res/insights/component:0.3.0' = {
  name: '${configuration.name}-insights'
  params: {
    name: '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }


    kind: configuration.insights.sku
    workspaceResourceId: logAnalytics.outputs.resourceId
    
    diagnosticSettings: [
      {
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
        name: 'customSetting'
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]
  }
}


/*
  ______     ___       ______  __    __   _______ 
 /      |   /   \     /      ||  |  |  | |   ____|
|  ,----'  /  ^  \   |  ,----'|  |__|  | |  |__   
|  |      /  /_\  \  |  |     |   __   | |   __|  
|  `----./  _____  \ |  `----.|  |  |  | |  |____ 
 \______/__/     \__\ \______||__|  |__| |_______|                             
*/
// This takes a long time to deploy so we are starting as soon as possible.
module redis 'br/public:avm/res/cache/redis:0.3.2' = {
  name: '${configuration.name}-cache'
  params: {
    name: '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }

    skuName: 'Basic' 
    capacity: 1
    replicasPerMaster: 1
    replicasPerPrimary: 1
    zoneRedundant: false
    enableNonSslPort: true
  }
}


/*
.__   __.  _______ .___________.____    __    ____  ______   .______       __  ___ 
|  \ |  | |   ____||           |\   \  /  \  /   / /  __  \  |   _  \     |  |/  / 
|   \|  | |  |__   `---|  |----` \   \/    \/   / |  |  |  | |  |_)  |    |  '  /  
|  . `  | |   __|      |  |       \            /  |  |  |  | |      /     |    <   
|  |\   | |  |____     |  |        \    /\    /   |  `--'  | |  |\  \----.|  .  \  
|__| \__| |_______|    |__|         \__/  \__/     \______/  | _| `._____||__|\__\ 
.______    __          ___       _______   _______ 
|   _  \  |  |        /   \     |       \ |   ____|
|  |_)  | |  |       /  ^  \    |  .--.  ||  |__   
|   _  <  |  |      /  /_\  \   |  |  |  ||   __|  
|  |_)  | |  `----./  _____  \  |  '--'  ||  |____ 
|______/  |_______/__/     \__\ |_______/ |_______|
*/
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
    }
  }
  dependsOn: [
    stampIdentity
    logAnalytics
  ]
}


/*
  ______  __       __    __       _______.___________. _______ .______      
 /      ||  |     |  |  |  |     /       |           ||   ____||   _  \     
|  ,----'|  |     |  |  |  |    |   (----`---|  |----`|  |__   |  |_)  |    
|  |     |  |     |  |  |  |     \   \       |  |     |   __|  |      /     
|  `----.|  `----.|  `--'  | .----)   |      |  |     |  |____ |  |\  \----.
 \______||_______| \______/  |_______/       |__|     |_______|| _| `._____|
.______    __          ___       _______   _______ 
|   _  \  |  |        /   \     |       \ |   ____|
|  |_)  | |  |       /  ^  \    |  .--.  ||  |__   
|   _  <  |  |      /  /_\  \   |  |  |  ||   __|  
|  |_)  | |  `----./  _____  \  |  '--'  ||  |____ 
|______/  |_______/__/     \__\ |_______/ |_______|
*/
module clusterBlade 'modules/blade_cluster.bicep' = {
  name: 'cluster-blade'
  params: {
    bladeConfig: {
      sectionName: 'clusterblade'
      displayName: 'Cluster Resources'
    }

    tags: {
      id: rg_unique_id
    }

    location: location
    enableTelemetry: enableTelemetry

    enableNodeAutoProvisioning: clusterConfiguration.enableNodeAutoProvisioning == 'false' ? false : true
    enablePrivateCluster: clusterConfiguration.enablePrivateCluster == 'true' ? true : false

    workspaceResourceId: logAnalytics.outputs.resourceId
    identityId: enableVnetInjection ? networkBlade.outputs.networkConfiguration.identityId : stampIdentity.outputs.resourceId
    managedIdentityName: stampIdentity.outputs.name
    
    aksSubnetId: enableVnetInjection ? networkBlade.outputs.aksSubnetId : ''
    podSubnetId: enableVnetInjection ? networkBlade.outputs.podSubnetId : ''
    vmSize: customVMSize
  }
  dependsOn: [
    stampIdentity
    logAnalytics
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
// AVM doesn't support output of the principalId from the extension module so we have to use a deployment script to get it.
// This takes a long time to deploy so we are starting as soon as possible.
module fluxExtension 'modules/flux-extension/main.bicep' = {
  name: '${configuration.name}-flux-extension'
  params: {
    clusterName: clusterBlade.outputs.clusterName
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
  dependsOn: [
    clusterBlade
  ]
}


/*
     _______.  ______ .______       __  .______   .___________.
    /       | /      ||   _  \     |  | |   _  \  |           |
   |   (----`|  ,----'|  |_)  |    |  | |  |_)  | `---|  |----`
    \   \    |  |     |      /     |  | |   ___/      |  |     
.----)   |   |  `----.|  |\  \----.|  | |  |          |  |     
|_______/     \______|| _| `._____||__| | _|          |__|     
*/
module extensionClientId 'br/public:avm/res/resources/deployment-script:0.4.0' = {
  name: '${configuration.name}-script-clientId'
  
  params: {
    kind: 'AzureCLI'
    name: 'script-${configuration.name}-aks-extension'
    azCliVersion: '2.63.0'
    location: location
    managedIdentities: {
      userAssignedResourcesIds: [
        stampIdentity.outputs.resourceId
      ]
    }

    environmentVariables: [
      {
        name: 'rgName'
        value: '${resourceGroup().name}_aks_${clusterBlade.outputs.clusterName}_nodes'
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


/*
.______       _______   _______  __       _______.___________..______     ____    ____ 
|   _  \     |   ____| /  _____||  |     /       |           ||   _  \    \   \  /   / 
|  |_)  |    |  |__   |  |  __  |  |    |   (----`---|  |----`|  |_)  |    \   \/   /  
|      /     |   __|  |  | |_ | |  |     \   \       |  |     |      /      \_    _/   
|  |\  \----.|  |____ |  |__| | |  | .----)   |      |  |     |  |\  \----.   |  |     
| _| `._____||_______| \______| |__| |_______/       |__|     | _| `._____|   |__|                                                                                                                              
*/
module registry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: '${configuration.name}-container-registry'
  params: {
    name: '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    enableTelemetry: enableTelemetry

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }

    // Hook up Diagnostics
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]

    // Configure Service
    acrSku: configuration.registry.sku

    managedIdentities: {
      systemAssigned: true
      userAssignedResourceIds: [
        stampIdentity.outputs.resourceId
      ]
    }

    // Add Role Assignment
    roleAssignments: [
      {
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'AcrPull'
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

var name = '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'

@description('The list of secrets to persist to the Key Vault')
var vaultSecrets = [ 
  {
    secretName: 'tenant-id'
    secretValue: subscription().tenantId
  }
  {
    secretName: 'app-dev-sp-tenant-id'
    secretValue: subscription().tenantId
  }
  {
    secretName: 'subscription-id'
    secretValue: subscription().subscriptionId
  }
  // Azure AD Secrets
  {
    secretName: 'app-dev-sp-password'
    secretValue: applicationClientSecret == '' ? 'dummy' : applicationClientSecret
  }
  {
    secretName: 'app-dev-sp-id'
    secretValue: applicationClientId
  }
  {
    secretName: 'cpng-user-name'
    secretValue: 'dbuser'
  }
  {
    secretName: 'cpng-user-password'
    secretValue: substring(uniqueString('dbuser', resourceGroup().id, configuration.name), 0, 8)
  }
  {
    secretName: 'cpng-superuser-name'
    secretValue: 'dbadmin'
  }
  {
    secretName: 'cpng-superuser-password'
    secretValue: substring(uniqueString('dbadmin', resourceGroup().id, configuration.name), 0, 8)
  }
  {
    secretName: 'airflow-db-connection'
    secretValue: 'postgresql://dbuser:${substring(uniqueString('dbuser', resourceGroup().id, configuration.name), 0, 8)}@airflow-cluster-rw.postgresql.svc.cluster.local:5432/airflow-db'
  }
  {
    secretName: 'airflow-admin-username'
    secretValue: 'admin'
  }
  {
    secretName: 'airflow-admin-password'
    secretValue: substring(uniqueString('airflow', resourceGroup().id, configuration.name), 0, 8)
  }
  {
    secretName: 'airflow-fernet-key'
    secretValue: substring(uniqueString('airflow-fernet', resourceGroup().id, configuration.name), 0, 8)
  }
  {
    secretName: 'airflow-webserver-key'
    secretValue: substring(uniqueString('airflow-webserver', resourceGroup().id, configuration.name), 0, 8)
  }
]

module keyvault 'br/public:avm/res/key-vault/vault:0.5.1' = {
  name: '${configuration.name}-keyvault'
  params: {
    name: length(name) > 24 ? substring(name, 0, 24) : name
    location: location
    enableTelemetry: enableTelemetry
    
    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }

    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]

    enablePurgeProtection: false
    
    // Configure RBAC
    enableRbacAuthorization: true
    roleAssignments: union(
      applicationClientPrincipalOid != '' ? [
        {
          roleDefinitionIdOrName: 'Key Vault Secrets User'
          principalId: applicationClientPrincipalOid
          principalType: 'ServicePrincipal'
        }
      ] : [],
      [
        {
          roleDefinitionIdOrName: 'Key Vault Secrets User'
          principalId: stampIdentity.outputs.principalId
          principalType: 'ServicePrincipal'
        }
      ]
    )

    // Configure Network Access
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: clusterBlade.outputs.natClusterIP
        }
      ]
    }

    // Configure Secrets
    secrets: {
      secureList: [for secret in vaultSecrets: {
        name: secret.secretName
        value: secret.secretValue
      }]
    }
  }
}


/*
     _______. _______   ______ .______       _______ .___________.    _______.
    /       ||   ____| /      ||   _  \     |   ____||           |   /       |
   |   (----`|  |__   |  ,----'|  |_)  |    |  |__   `---|  |----`  |   (----`
    \   \    |   __|  |  |     |      /     |   __|      |  |        \   \    
.----)   |   |  |____ |  `----.|  |\  \----.|  |____     |  |    .----)   |   
|_______/    |_______| \______|| _| `._____||_______|    |__|    |_______/    
*/
// This custom module is used to persist insights, cache and workspace secrets to the Key Vault.
module keyvaultSecrets 'modules/keyvault_secrets.bicep' = {
  name: '${configuration.name}-diag-secrets'
  params: {
    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    workspaceName: logAnalytics.outputs.name
    insightsName: insights.outputs.name
    cacheName: redis.outputs.name
  }
  dependsOn: [
    insights
    redis
    keyvault
  ]
}

var commonLayerConfig = {
  database: {
    name: 'osdu-graph'
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


/*   _______.___________.  ______   .______          ___       _______  _______ 
    /       |           | /  __  \  |   _  \        /   \     /  _____||   ____|
   |   (----`---|  |----`|  |  |  | |  |_)  |      /  ^  \   |  |  __  |  |__   
    \   \       |  |     |  |  |  | |      /      /  /_\  \  |  | |_ | |   __|  
.----)   |      |  |     |  `--'  | |  |\  \----./  _____  \ |  |__| | |  |____ 
|_______/       |__|      \______/  | _| `._____/__/     \__\ \______| |_______|                                                                 
*/
// AVM Module Customized due to required Secrets.
module storage 'modules/storage-account/main.bicep' = {
  name: '${configuration.name}-storage'
  params: {
    name: '${replace(configuration.name, '-', '')}${uniqueString(resourceGroup().id, configuration.name)}'
    location: location
    skuName: configuration.storage.sku

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }
    
    // Hook up Diagnostics
    diagnosticSettings: [
      {
        workspaceResourceId: logAnalytics.outputs.resourceId
      }
    ]

     // Configure Service
     blobServices: {
      containers: map(configuration.storage.containers, container => {
        name: container
      })
    }
    tableServices: {
      tables: map(configuration.storage.tables, table => {
        name: table
      })
    }
    fileServices: {
      shares: map(configuration.storage.shares, share => {
        name: share
      })
    }

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: 'Storage File Data SMB Share Reader'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: 'Storage Table Data Contributor'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
      {
        roleDefinitionIdOrName: 'Storage File Data Privileged Contributor'
        principalId: stampIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
      }
    ]

    // Apply Security
    allowBlobPublicAccess: enableBlobPublicAccess
    publicNetworkAccess: 'Enabled'
    allowSharedKeyAccess: true
    // https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#debug-deployment-scripts
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'     // <--- Allow all traffic.  Should be changed to Deny.
      ipRules: [
        {
          value: clusterBlade.outputs.natClusterIP
        }
      ]
    }

    // Persist Secrets to Vault
    secretsExportConfiguration: {
      keyVaultResourceId: keyvault.outputs.resourceId
      accountName: [
        'system-storage'
        'tbl-storage'
      ]
      accessKey1: [
        'system-storage-key'
        'tbl-storage-key'
      ]
      connectionString1: [
        'system-storage-connection'
      ]     
      blobEndpoint: [
        'system-storage-blob-endpoint'
      ]
      tableEndpoint: [
        'tbl-storage-endpoint'
      ]
    }
  }
  dependsOn: [
    keyvault
    clusterBlade
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
// AVM Module Customized due to required Secrets.
module database 'modules/cosmos-db/main.bicep' = {
  name: '${configuration.name}-cosmos-db'
  params: {
    resourceName: configuration.name
    resourceLocation: location

    // Assign Tags
    tags: {
      layer: configuration.displayName
      id: rg_unique_id
    }

    // Hook up Diagnostics
    diagnosticWorkspaceId: logAnalytics.outputs.resourceId
    diagnosticLogsRetentionInDays: 0

    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      networkAclBypass: 'AzureServices'
      ipRules: [
        '${clusterBlade.outputs.natClusterIP}'
      ]
      virtualNetworkRules: []
    }


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

    // Hookup Customer Managed Encryption Key
    systemAssignedIdentity: false
    userAssignedIdentities: !empty(cmekConfiguration.identityId) ? {
      '${cmekConfiguration.identityId}': {}
    } : {}
    defaultIdentity: !empty(cmekConfiguration.identityId) ? cmekConfiguration.identityId : ''
    kvKeyUri: !empty(cmekConfiguration.kvUrl) && !empty(cmekConfiguration.keyName) ? '${cmekConfiguration.kvUrl}/keys/${cmekConfiguration.keyName}' : ''

    // Persist Secrets to Vault
    keyVaultName: keyvault.outputs.name
    databaseEndpointSecretName: 'graph-db-endpoint'
    databasePrimaryKeySecretName: 'graph-db-primary-key'
    databaseConnectionStringSecretName: 'graph-db-connection'
    

    roleAssignments: [
      {
        roleDefinitionIdOrName: 'Contributor'
        principals: [
          {
            id: applicationClientPrincipalOid
          }
        ]
        principalType: 'ServicePrincipal'
      }
    ]
  }
}


/*
     _______.  ______ .______       __  .______   .___________.    _______.
    /       | /      ||   _  \     |  | |   _  \  |           |   /       |
   |   (----`|  ,----'|  |_)  |    |  | |  |_)  | `---|  |----`  |   (----`
    \   \    |  |     |      /     |  | |   ___/      |  |        \   \    
.----)   |   |  `----.|  |\  \----.|  | |  |          |  |    .----)   |   
|_______/     \______|| _| `._____||__| | _|          |__|    |_______/    
*/


var directoryUploads = [
  {
    directory: 'software'
  }
  {
    directory: 'charts'
  }
  {
    directory: 'stamp'
  }
]

@batchSize(1)
module gitOpsUpload 'br/public:avm/res/resources/deployment-script:0.4.0' = [for item in directoryUploads: {
  name: '${configuration.name}-storage-${item.directory}-upload'
  params: {
    name: 'script-${storage.outputs.name}-${item.directory}'

    location: location
    cleanupPreference: 'Always'
    retentionInterval: 'PT1H'
    timeout: 'PT30M'
    runOnce: true
    
    managedIdentities: {
      userAssignedResourcesIds: [
        stampIdentity.outputs.resourceId
      ]
    }    

    kind: 'AzureCLI'
    azCliVersion: '2.63.0'
    
    environmentVariables: [
      { name: 'AZURE_STORAGE_ACCOUNT', value: storage.outputs.name }
      { name: 'FILE', value: 'main.zip' }
      { name: 'URL', value: 'https://github.com/azure/osdu-developer/archive/refs/heads/main.zip' }
      { name: 'CONTAINER', value: 'gitops' }
      { name: 'UPLOAD_DIR', value: string(item.directory) }
    ]
    scriptContent: loadTextContent('./modules/deploy-scripts/software-upload.sh')
  }
}]


//TODO: This needs to be removed and moved into a kubernetes job.
module manifestDagShareUpload 'modules/script-share-upload/main.bicep' = {
  name: '${configuration.name}-storage-dag-upload-manifest'
  params: {
    newStorageAccount: true
    location: location
    storageAccountName: storage.outputs.name
    identityName: stampIdentity.outputs.name

    shareName: 'airflow-dags'
    filename: 'src/osdu_dags'
    compress: true
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/archive/master/ingestion-dags-master.tar.gz'
  }
  dependsOn: [
    stampIdentity
    storage
  ]
}

//TODO: This needs to be removed and moved into a kubernetes job.
module csvDagShareUpload 'modules/script-share-csvdag/main.bicep' = {
  name: '${configuration.name}-storage-dag-upload-csv'
  params: {
    newStorageAccount: true
    location: location
    storageAccountName: storage.outputs.name
    identityName: stampIdentity.outputs.name
    
    shareName: 'airflow-dags'
    filename: 'airflowdags'
    fileurl: 'https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz'
    keyVaultUrl: keyvault.outputs.uri
    insightsKey: insights.outputs.instrumentationKey
    clientId: applicationClientId
    clientSecret: applicationClientSecret
  }
  dependsOn: [
    stampIdentity
    storage
  ]
}

/*
.______      ___      .______     .___________. __  .___________. __    ______   .__   __. 
|   _  \    /   \     |   _  \    |           ||  | |           ||  |  /  __  \  |  \ |  | 
|  |_)  |  /  ^  \    |  |_)  |   `---|  |----`|  | `---|  |----`|  | |  |  |  | |   \|  | 
|   ___/  /  /_\  \   |      /        |  |     |  |     |  |     |  | |  |  |  | |  . `  | 
|  |     /  _____  \  |  |\  \----.   |  |     |  |     |  |     |  | |  `--'  | |  |\   | 
| _|    /__/     \__\ | _| `._____|   |__|     |__|     |__|     |__|  \______/  |__| \__| 
.______    __          ___       _______   _______ 
|   _  \  |  |        /   \     |       \ |   ____|
|  |_)  | |  |       /  ^  \    |  .--.  ||  |__   
|   _  <  |  |      /  /_\  \   |  |  |  ||   __|  
|  |_)  | |  `----./  _____  \  |  '--'  ||  |____ 
|______/  |_______/__/     \__\ |_______/ |_______|
*/
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
    kvName: keyvault.outputs.name
    natClusterIP: clusterBlade.outputs.natClusterIP
    
    enableBlobPublicAccess: enableBlobPublicAccess

    partitions: configuration.partitions
    managedIdentityName: stampIdentity.outputs.name
  }
  dependsOn: enableVnetInjection ? [
    networkBlade
    stampIdentity
    logAnalytics
    keyvault
  ] :[
    stampIdentity
    logAnalytics
    keyvault
  ]
}


/*
  ______   ______   .__   __.  _______  __    _______ 
 /      | /  __  \  |  \ |  | |   ____||  |  /  _____|
|  ,----'|  |  |  | |   \|  | |  |__   |  | |  |  __  
|  |     |  |  |  | |  . `  | |   __|  |  | |  | |_ | 
|  `----.|  `--'  | |  |\   | |  |     |  | |  |__| | 
 \______| \______/  |__| \__| |__|     |__|  \______| 
.______    __          ___       _______   _______ 
|   _  \  |  |        /   \     |       \ |   ____|
|  |_)  | |  |       /  ^  \    |  .--.  ||  |__   
|   _  <  |  |      /  /_\  \   |  |  |  ||   __|  
|  |_)  | |  `----./  _____  \  |  '--'  ||  |____ 
|______/  |_______/__/     \__\ |_______/ |_______|
*/
module configBlade 'modules/blade_configuration.bicep' = {
  name: 'config-blade'
  params: {
    bladeConfig: {
      sectionName: 'configblade'
      displayName: 'Config Resources'
    }

    tags: {
      id: rg_unique_id
    }

    location: location

    osduVersion: clusterSoftware.osduVersion == '' ? 'master' : clusterSoftware.osduVersion
    enableSoftwareLoad: clusterSoftware.enable == 'false' ? false : true
    enableOsduCore: clusterSoftware.osduCore == 'false' ? false : true
    enableOsdureference: clusterSoftware.osduReference == 'false' ? false : true
    enableExperimental: experimentalSoftware.enable == 'true' ? true : false
    enableAdminUI: experimentalSoftware.adminUI == 'true' ? true : false

    emailAddress: emailAddress
    applicationClientId: applicationClientId
    applicationClientPrincipalOid: applicationClientPrincipalOid

    managedIdentityName: stampIdentity.outputs.name
    kvName: keyvault.outputs.name
    kvUri: keyvault.outputs.uri
    partitionStorageNames: partitionBlade.outputs.partitionStorageNames
    partitionServiceBusNames: partitionBlade.outputs.partitionServiceBusNames
    
    clusterName: clusterBlade.outputs.clusterName
    oidcIssuerUrl: clusterBlade.outputs.oidcIssuerUrl
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
    clusterBlade
    partitionBlade
    fluxExtension
  ]
}

// module storageAcl 'modules/network_acl_storage.bicep' = {
//   name: '${configuration.name}-storage-acl'
//   params: {
//     storageName: storage.outputs.name
//     location: location
//     skuName: configuration.storage.sku
//     natClusterIP: clusterBlade.outputs.natClusterIP
//   }
//   dependsOn: [
//     manifestDagShareUpload
//     csvDagShareUpload
//     gitOpsUpload
//   ]
// }

// =============== //
//   Outputs       //
// =============== //

output ACR_NAME string = registry.outputs.name
output AKS_NAME string = clusterBlade.outputs.clusterName
output INSTRUMENTATION_KEY string = insights.outputs.instrumentationKey
output COMMON_NAME string = storage.outputs.name
output DATA_NAME string = partitionBlade.outputs.partitionStorageNames[0]

//ACSCII Art link : https://textkool.com/en/ascii-art-generator?hl=default&vl=default&font=Star%20Wars&text=changeme
