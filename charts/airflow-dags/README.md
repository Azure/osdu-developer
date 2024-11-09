# Airflow DAGs Helm Chart

This Helm chart installs and configures OSDU (Open Subsurface Data Universe) DAGs into an existing Airflow installation by ensuring the DAGs are downloaded values parsed, compressed and uploaded to the Storage Share.

## Overview

This chart manages two primary types of DAGs:
1. **Manifest DAGs**: Ingestion workflow DAGs for OSDU
2. **CSV Parser DAGs**: DAGs for parsing and processing CSV files in OSDU

## Prerequisites

### Infrastructure Requirements
- Kubernetes cluster with Helm installed
- Existing Airflow installation
- PVC named "airflow-dags-pvc" for DAG storage

### Suggested Custom Values

The best way to get values is by providing information in the ConfigMap and Secret values.

#### ConfigMap Values (`airflow-configmap`)
***yaml
value.yaml: |
  clientId: "<azure-client-id>"
  tenantId: "<azure-tenant-id>"
  keyvaultUri: "<keyvault-uri>"
***

#### Secret Values (`airflow-secrets`)
***yaml
data:
  client-key: "<azure-client-secret>"
  insights-key: "<instrumentation-key>"
***

## Installation Methods

### Using FluxCD HelmRelease (Recommended)

The chart can be deployed using FluxCD's HelmRelease custom resource. Example configuration:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: airflow-dags
  namespace: airflow
spec:
  targetNamespace: airflow
  releaseName: airflow-dags
  dependsOn:
    - name: azure-keyvault-airflow
      namespace: default
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
            url: "https://example.com/manifest-dags.tar.gz"
            pvc: "airflow-dags-pvc"
      csvdag:
        enabled: true
        folder: "airflowdags"
        compress: true
        url: "https://example.com/csv-parser.tar.gz"
        pvc: "airflow-dags-pvc"
```

### 2. Manual Installation

```bash
# Install/Upgrade the chart
helm upgrade --install airflow-dags -f custom_values.yaml . -n airflow
```

## Values Reference

| Parameter | Description | Default |
|-----------|-------------|---------|
| `airflow.manifestdag.enabled` | Enable manifest DAGs | `true` |
| `airflow.csvdag.enabled` | Enable CSV parser DAGs | `true` |
| `airflow.*.folder` | Installation folder | varies |
| `airflow.*.url` | Source URL for DAGs | varies |
| `airflow.*.pvc` | PVC for DAG storage | `airflow-dags-pvc` |

## Troubleshooting

For troubleshooting issues:

1. Check pod logs:

```bash
kubectl logs -n airflow $(kubectl get pods -n airflow | grep csvdag-upload | awk '{print $1}')
```

2. Verify ConfigMap and Secret values:

```bash
kubectl describe configmap airflow-configmap -n airflow
kubectl describe secret airflow-secrets -n airflow
```

For detailed troubleshooting steps and implementation details, see the [IMPLEMENTATION.md](./IMPLEMENTATION.md) file.