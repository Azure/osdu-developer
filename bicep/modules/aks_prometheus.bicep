// Parameters

@description('Specifies the name of the Azure Monitor managed service for Prometheus resource.')
param name string

@description('Specifies the location of the Azure Monitor managed service for Prometheus resource.')
param location string = resourceGroup().location

@description('Specifies the name of the AKS cluster.')
param clusterName string

@description('Specifies whether or not public endpoint access is allowed for the Azure Monitor managed service for Prometheus resource.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Specifies the resource id of an Action Group resource. If empty, no action is specifies for metric alerts.')
param actionGroupId string = ''

@description('Specifies the resource tags for the Azure Monitor managed service for Prometheus resource.')
param tags object

var nodeRecordingRuleGroupPrefix = 'NodeRecordingRulesRuleGroup-'
var nodeRecordingRuleGroupName = '${nodeRecordingRuleGroupPrefix}${clusterName}'
var nodeRecordingRuleGroupDescription = 'Node Recording Rules RuleGroup'
var version = ' - 0.1'

// Resources
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-06-02-preview' existing = {
  name: clusterName
}

resource azureMonitorWorkspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: name
  location: location
  tags: tags
}

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: 'MSProm-${location}-${clusterName}'
  location: location
  kind: 'Linux'
  tags: tags
  properties: {
    networkAcls: {
      publicNetworkAccess: publicNetworkAccess
    }
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'MSProm-${location}-${clusterName}'
  location: location
  tags: tags

  properties: {
    dataCollectionEndpointId: dataCollectionEndpoint.id
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {}
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: azureMonitorWorkspace.id
          name: 'MonitoringAccount1'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
        destinations: [
          'MonitoringAccount1'
        ]
      }
    ]
  }
}

resource dataCollectionRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'MSProm-${location}-${clusterName}'
  scope: aksCluster
  properties: {
    dataCollectionRuleId: dataCollectionRule.id
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
  }
}

resource nodeRecordingRuleGroup 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: nodeRecordingRuleGroupName
  location: location
  properties: {
    description: '${nodeRecordingRuleGroupDescription}${version}'
    scopes: [
      azureMonitorWorkspace.id
    ]
    enabled: true
    clusterName: clusterName
    interval: 'PT1M'
    rules: [
      {
        record: 'instance:node_num_cpu:sum'
        expression: 'count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})'
      }
      {
        record: 'instance:node_cpu_utilisation:rate5m'
        expression: '1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))'
      }
      {
        record: 'instance:node_load1_per_cpu:ratio'
        expression: '(  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})'
      }
      {
        record: 'instance:node_memory_utilisation:ratio'
        expression: '1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})'
      }
      {
        record: 'instance:node_vmstat_pgmajfault:rate5m'
        expression: 'rate(node_vmstat_pgmajfault{job="node"}[5m])'
      }
      {
        record: 'instance_device:node_disk_io_time_seconds:rate5m'
        expression: 'rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])'
      }
      {
        record: 'instance_device:node_disk_io_time_weighted_seconds:rate5m'
        expression: 'rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])'
      }
      {
        record: 'instance:node_network_receive_bytes_excluding_lo:rate5m'
        expression: 'sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))'
      }
      {
        record: 'instance:node_network_transmit_bytes_excluding_lo:rate5m'
        expression: 'sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))'
      }
      {
        record: 'instance:node_network_receive_drop_excluding_lo:rate5m'
        expression: 'sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))'
      }
      {
        record: 'instance:node_network_transmit_drop_excluding_lo:rate5m'
        expression: 'sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))'
      }
    ]
  }
}

resource communityALerts 'Microsoft.AlertsManagement/prometheusRuleGroups@2021-07-22-preview' = {
  name: 'CommunityCIAlerts-${clusterName}'
  location: location
  properties: {
    description: 'Kubernetes Alert RuleGroup-communityCIAlerts - 0.1'
    scopes: [
      azureMonitorWorkspace.id
    ]
    clusterName: clusterName
    enabled: true
    interval: 'PT1M'
    rules: [
      {
        alert: 'KubePodCrashLooping'
        expression: 'max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics"}[5m]) >= 1'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubePodNotReady'
        expression: 'sum by (namespace, pod, cluster) (  max by(namespace, pod, cluster) (    kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown"}  ) * on(namespace, pod, cluster) group_left(owner_kind) topk by(namespace, pod, cluster) (    1, max by(namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!="Job"})  )) > 0'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeDeploymentReplicasMismatch'
        expression: '(  kube_deployment_spec_replicas{job="kube-state-metrics"}    >  kube_deployment_status_replicas_available{job="kube-state-metrics"}) and (  changes(kube_deployment_status_replicas_updated{job="kube-state-metrics"}[10m])    ==  0)'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeStatefulSetReplicasMismatch'
        expression: '(  kube_statefulset_status_replicas_ready{job="kube-state-metrics"}    !=  kube_statefulset_status_replicas{job="kube-state-metrics"}) and (  changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[10m])    ==  0)'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeJobNotCompleted'
        expression: 'time() - max by(namespace, job_name, cluster) (kube_job_status_start_time{job="kube-state-metrics"}  and kube_job_status_active{job="kube-state-metrics"} > 0) > 43200'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeJobFailed'
        expression: 'kube_job_failed{job="kube-state-metrics"}  > 0'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeHpaReplicasMismatch'
        expression: '(kube_horizontalpodautoscaler_status_desired_replicas{job="kube-state-metrics"}  !=kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"})  and(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}  >kube_horizontalpodautoscaler_spec_min_replicas{job="kube-state-metrics"})  and(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}  <kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"})  and changes(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}[15m]) == 0'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeHpaMaxedOut'
        expression: 'kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}  ==kube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"}'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeCPUQuotaOvercommit'
        expression: 'sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(cpu|requests.cpu)"}))  /sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})  > 1.5'
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeMemoryQuotaOvercommit'
        expression: 'sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(memory|requests.memory)"}))  /sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})  > 1.5'
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeQuotaAlmostFull'
        expression: 'kube_resourcequota{job="kube-state-metrics", type="used"}  / ignoring(instance, job, type)(kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)  > 0.9 < 1'
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeVersionMismatch'
        expression: 'count by (cluster) (count by (git_version, cluster) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"git_version","$1","git_version","(v[0-9]*.[0-9]*).*"))) > 1'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeNodeNotReady'
        expression: 'kube_node_status_condition{job="kube-state-metrics",condition="Ready",status="true"} == 0'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeNodeUnreachable'
        expression: '(kube_node_spec_taint{job="kube-state-metrics",key="node.kubernetes.io/unreachable",effect="NoSchedule"} unless ignoring(key,value) kube_node_spec_taint{job="kube-state-metrics",key=~"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn"}) == 1'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeletTooManyPods'
        expression: 'count by(cluster, node) (  (kube_pod_status_phase{job="kube-state-metrics",phase="Running"} == 1) * on(instance,pod,namespace,cluster) group_left(node) topk by(instance,pod,namespace,cluster) (1, kube_pod_info{job="kube-state-metrics"}))/max by(cluster, node) (  kube_node_status_capacity{job="kube-state-metrics",resource="pods"} != 1) > 0.95'
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
      {
        alert: 'KubeNodeReadinessFlapping'
        expression: 'sum(changes(kube_node_status_condition{status="true",condition="Ready"}[15m])) by (cluster, node) > 2'
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        severity: 3
        enabled: true
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: actionGroupId == '' ? [] : [
          {
            actionGroupId: actionGroupId
          }
        ]
      }
    ]
  }
}

// Outputs
output id string = azureMonitorWorkspace.id
output name string = azureMonitorWorkspace.name
output location string = azureMonitorWorkspace.location
output accountId string = azureMonitorWorkspace.properties.accountId
output prometheusQueryEndpoint string = azureMonitorWorkspace.properties.metrics.prometheusQueryEndpoint
output internalId string = azureMonitorWorkspace.properties.metrics.internalId
