@description('The name of the Managed Cluster resource.')
param clusterName string

resource existingManagedCluster 'Microsoft.ContainerService/managedClusters@2024-04-02-preview' existing = {
  name: clusterName
}

resource appConfigExtension 'Microsoft.KubernetesConfiguration/extensions@2023-05-01' = {
  name: 'appconfigurationkubernetesprovider'
  scope: existingManagedCluster
  properties: {
    autoUpgradeMinorVersion: true
    configurationSettings: {
      'global.clusterType': 'managedclusters'
    }
    extensionType: 'microsoft.appconfiguration'
  }
}
