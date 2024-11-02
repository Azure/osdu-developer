@description('The name of the Azure Kubernetes Service Cluster')
param clusterName string = ''

resource managedCluster 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' existing = if (clusterName != '') {
  name: clusterName
}

var policyDefinitionId = '/providers/Microsoft.Authorization/policySetDefinitions/c047ea8e-9c78-49b2-958b-37e56d291a44'
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'aksDeploymentSafeguardsAssignment'
  scope: managedCluster
  properties: {
    displayName: 'AKS Deployment Safeguards'
    #disable-next-line use-resource-id-functions
    policyDefinitionId: policyDefinitionId
    enforcementMode: 'DoNotEnforce'
    parameters: {
      effect: { value: 'Audit' }
      allowedUsers: {
        value: [] // Specify allowed users or leave empty array
      }
      allowedGroups: {
        value: [] // Specify allowed groups or leave empty array
      }
      cpuLimit: {
        value: '4' // Specify CPU limit, e.g., '1' for 1 core
      }
      memoryLimit: {
        value: '4Gi' // Specify memory limit, e.g., '1Gi' for 1 Gibibyte
      }
      labels: {
        value: [] // Specify required labels or leave empty object
      }
      allowedContainerImagesRegex: {
        value: '.*' // Specify regex for allowed container images, e.g., '.*' to allow all
      }
      reservedTaints: {
        value: [] // Specify reserved taints or leave empty array
      }
    }
  }
}
