@description('Specify the config map name.')
param name string = 'configuration'

@description('Specify the namespace for the config mapl')
param namespace string = 'default'

@description('Specify the name of the AKS cluster.')
param cluster string

@description('Specify the location of the AKS cluster.')
param location string

param dataMap array = [
  // Example
  {
    key: 'hello'
    value: 'world'
  }
]

var configmapValues = [for (key, value) in dataMap: '--from-literal=${key}=${value}']
var configmapValuesString = join(configmapValues, ' ')

module configMap './aks-run-command/main.bicep' = {
  name: '${deployment().name}-configmap-${name}'
  params: {
    aksName: cluster
    location: location
    commands: [
      format('kubectl get configmap {0} >/dev/null 2>&1 && kubectl delete configmap {0}', name)
      format('kubectl create configmap {0} {1} -n {2} --save-config', name, configmapValuesString, namespace)
    ]
    cleanupPreference: 'Always'
  }
}
