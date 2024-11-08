# Airflow DAGs Helm Chart

This Helm chart installs and configures OSDU (Open Subsurface Data Universe) DAGs into an existing Airflow installation.

## Overview

This chart manages two primary types of DAGs:
1. **Manifest DAGs**: Ingestion workflow DAGs for OSDU
2. **CSV Parser DAGs**: DAGs for parsing and processing CSV files in OSDU

## Prerequisites

- Kubernetes cluster with Helm installed
- Existing Airflow installation
- PVC named "airflow-dags-pvc" for DAG storage
- Required secrets and configmaps for Airflow configuration

## Install Process

You can install this chart either by:
1. Directly modifying the `values.yaml`
2. Creating a custom values file (recommended)

### Option 1: Using FluxCD HelmRelease

The chart can be deployed using FluxCD's HelmRelease custom resource, which supports:
- Automatic dependency management
- Values from ConfigMaps and Secrets
- Automatic remediation on failure

Example HelmRelease configuration:
```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: airflow-dags
  namespace: airflow
  annotations:
    clusterconfig.azure.com/use-managed-source: "true"
    kustomize.toolkit.fluxcd.io/substitute: disabled
spec:
  targetNamespace: airflow
  releaseName: airflow-dags
  dependsOn:
    - name: azure-keyvault-airflow
      namespace: default
    - name: config-maps-airflow
      namespace: default
  chart:
    spec:
      chart: ./charts/airflow-dags
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
  interval: 5m0s
  install:
    remediation:
      retries: 3
  valuesFrom:
    - kind: ConfigMap
      name: airflow-configmap
      valuesKey: value.yaml
    - kind: Secret
      name: airflow-secrets
      valuesKey: client-key
      targetPath: secrets.airflowSecrets.clientKey
  values:
    airflow:
      manifestdag:
        enabled: true
        items:
          - name: manifest
            folder: "src/osdu_dags"
            compress: true
            url: "https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/archive/master/ingestion-dags-master.tar.gz"
            pvc: "airflow-dags-pvc"
      csvdag:
        enabled: true
        folder: "airflowdags"
        compress: true
        url: "https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz"
        pvc: "airflow-dags-pvc"
        replacements:
          - find: '{| K8S_POD_OPERATOR_KWARGS or {} |}'
            replace:
              labels:
                aadpodidbinding: "osdu-identity"
              annotations:
                "sidecar.istio.io/inject": "false"
          - find: '{| ENV_VARS or {} |}'
            replace:
              storage_service_endpoint: "http://storage.osdu-core.svc.cluster.local/api/storage/v2"
              schema_service_endpoint: "http://schema.osdu-core.svc.cluster.local/api/schema-service/v1"
              search_service_endpoint: "http://search.osdu-core.svc.cluster.local/api/search/v2"
              partition_service_endpoint: "http://partition.osdu-core.svc.cluster.local/api/partition/v1"
              unit_service_endpoint: "http://unit.osdu-core.svc.cluster.local/api/unit/v2/unit/symbol"
              file_service_endpoint: "http://file.osdu-core.svc.cluster.local/api/file/v2"
              KEYVAULT_URI: {{ .Values.keyvaultUri }}
              appinsights_key: {{ .Values.appInsightsKey }}
              azure_paas_podidentity_isEnabled: "false"
              AZURE_TENANT_ID: {{ .Values.tenantId }}
              AZURE_CLIENT_ID: {{ .Values.clientId }}
              AZURE_CLIENT_SECRET: {{ .Values.secrets.airflowSecrets.clientKey }}
              aad_client_id: {{ .Values.clientId }}
          - find: '{| DAG_NAME |}'
            replace: 'csv-parser'
          - find: '{| DOCKER_IMAGE |}'
            replace: 'community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/csv-parser-v0-27-0-azure-1:60747714ac490be0defe8f3e821497b3cce03390'
          - find: '{| NAMESPACE |}'
            replace: 'airflow'
```

This example demonstrates:
- Dependencies on other Helm releases
- Integration with Azure KeyVault
- Configuration via ConfigMaps and Secrets
- Automatic remediation settings
- Complete DAG configuration for both manifest and CSV parser DAGs

### Option 2: Manual Installation

Generate a custom values file using the following template:

```bash
# Setup Variables
GROUP=<your_group>

# Generate custom_values.yaml
cat > custom_values.yaml << EOF
# ... (values configuration)
EOF

# Install/Upgrade the chart
NAMESPACE=airflow
helm upgrade --install airflow-dags -f custom_values.yaml . -n $NAMESPACE
```

## Configuration

### Manifest DAGs
- Enables OSDU ingestion workflow DAGs
- Configurable source URL and installation folder
- Supports compression for efficient storage

### CSV Parser DAGs
- Enables CSV parsing functionality
- Configurable environment variables for service endpoints
- Supports text replacements for customization
- Configurable Kubernetes pod annotations and labels

## Values Reference

Key configuration options:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `airflow.manifestdag.enabled` | Enable manifest DAGs | `true` |
| `airflow.csvdag.enabled` | Enable CSV parser DAGs | `true` |
| `airflow.*.folder` | Installation folder | varies |
| `airflow.*.url` | Source URL for DAGs | varies |
| `airflow.*.pvc` | PVC for DAG storage | `airflow-dags-pvc` |

For detailed configuration options, see the values.yaml file.