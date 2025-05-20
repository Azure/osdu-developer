# DNS Configuration Helm Chart

This chart configures DNS labels for Azure Kubernetes Service (AKS) LoadBalancer IPs, enabling automatic FQDN assignment for OSDU services.

--------------------------------------------------------------------------------
## Prerequisites

- Azure Kubernetes Service (AKS) cluster with workload identity enabled
- Istio service mesh deployed
- Azure CLI and kubectl access configured

--------------------------------------------------------------------------------
## Install Process

Either manually modify the `values.yaml` for the chart or generate a `custom_values.yaml` to use.

_The following commands can help generate a prepopulated custom values file._

```bash
# Setup Variables
GROUP=<your_resource_group>

SUBSCRIPTION=$(az account show --query id -otsv)
AKS_NAME=$(az aks list --resource-group $GROUP --query "[0].name" -otsv)

cat > custom_values.yaml << EOF
################################################################################
# Azure environment specific values
#
azure:
  tenantId: $(az account show --query tenantId -otsv)
  clientId: $(az identity list --resource-group $GROUP --query "[?contains(name, 'osdu-identity')].clientId" -otsv)
  configEndpoint: $(az appconfig list --resource-group $GROUP --query "[0].endpoint" -otsv)
  keyvaultName: $(az keyvault list --resource-group $GROUP --query "[0].name" -otsv)
  keyvaultUri: $(az keyvault list --resource-group $GROUP --query "[0].properties.vaultUri" -otsv)
  subscription: $SUBSCRIPTION
  resourceGroup: $GROUP
  aksName: $AKS_NAME
EOF
```

--------------------------------------------------------------------------------
## Manual Testing

Test the chart locally:

```bash
helm template dns-configuration . -f custom_values.yaml
```

--------------------------------------------------------------------------------
## Install Helm Chart

```bash
# Create the release in the osdu-system namespace where the ServiceAccount exists
NAMESPACE=osdu-system
helm upgrade --install dns-configuration . -n $NAMESPACE -f custom_values.yaml

# For testing with custom values
helm upgrade --install dns-configuration . -n $NAMESPACE \
  --set azure.subscription=$(az account show --query id -otsv) \
  --set azure.aksName="$(az aks list --query "[0].name" -otsv)"

# Verify the job completed
kubectl get jobs -n $NAMESPACE
kubectl get pods -n $NAMESPACE | grep dns-configuration

# Check job logs
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app.kubernetes.io/name=dns-configuration -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME -n $NAMESPACE

# Check the created ConfigMap
kubectl get configmap dns-config -n $NAMESPACE -o yaml
```

--------------------------------------------------------------------------------
## Uninstall

```bash
# Uninstall the release
helm uninstall dns-configuration -n $NAMESPACE

# Manually clean up ConfigMap if needed
kubectl delete configmap dns-config -n $NAMESPACE
```

--------------------------------------------------------------------------------
## Configuration Options

| Parameter                | Description                              | Default                |
|--------------------------|------------------------------------------|------------------------|
| `serviceAccount.create`  | Create a new service account             | `false`                |
| `serviceAccount.name`    | Service account name to use              | `workload-identity-sa` |
| `azure.tenantId`         | Azure tenant ID                          | `<your_tenant_id>`     |
| `azure.clientId`         | Azure client ID for workload identity    | `<your_client_id>`     |
| `azure.subscription`     | Azure subscription ID                    | `<your_subscription_id>` |
| `azure.resourceGroup`    | Resource group containing the AKS cluster| `<your_resource_group>` |
| `azure.aksName`          | AKS cluster name                         | `<your_aks_cluster_name>` |
| `azure.uniqueId`         | Unique ID for the cluster                | `""`                  |

--------------------------------------------------------------------------------
## Output

The chart creates a ConfigMap named `dns-config` in the release namespace containing:

- `external_ip`: The LoadBalancer external IP address
- `fqdn`: The fully qualified domain name
- `dns_label`: The DNS label assigned

Other services can reference this ConfigMap to obtain the FQDN for certificate generation and gateway configuration.