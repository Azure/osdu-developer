# storage-volumes Helm Chart

This Helm chart provisions Azure Blob-backed PersistentVolumes (PV) and PersistentVolumeClaims (PVC) in Kubernetes using the Azure Blob CSI driver.

## Values

| Key                | Description                                      | Required | Default           |
|--------------------|--------------------------------------------------|----------|-------------------|
| azure.clientId     | Azure AD workload identity client ID              | Yes      | -                 |
| azure.resourceGroup| Azure resource group name                        | Yes      | -                 |
| azure.storageAccountName | Azure storage account name                  | Yes      | -                 |
| volumes            | List of volume definitions (see below)           | Yes      | -                 |
| volumes[].volumeName | Name for the PV and PVC                        | Yes      | -                 |
| volumes[].containerName  | Azure blob container name for this volume   | Yes      | -                 |
| volumes[].storageSize| Storage size for PV/PVC                        | No       | 5Gi               |
| volumes[].accessModes | List of access modes (e.g. ReadWriteMany)      | No       | [ReadWriteMany]   |


### Example `values.yaml`

```yaml
azure:
  clientId: "<your_client_id>"
  resourceGroup: "<your_resource_group>"
  storageAccountName: "<your_storage_account>"

volumes:
  - volumeName: "blob-persistent-pv"
    containerName: "<your_blob_container>"
    # Optional, defaults shown
    storageSize: "10Gi"
    accessModes:
      - ReadWriteMany
```

## Usage

Install or upgrade the chart with your custom values:

```bash
helm upgrade --install storage-volumes ./storage-volumes -n <namespace> -f values.yaml
```

This will create a PersistentVolume and PersistentVolumeClaim for each entry in `volumes`, using the Azure Blob CSI driver.
