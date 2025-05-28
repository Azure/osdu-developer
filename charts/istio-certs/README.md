# Istio Certs Helm Chart

This chart configures DNS labels for Azure Kubernetes Service (AKS) LoadBalancer IPs, enabling automatic FQDN assignment for OSDU services.

--------------------------------------------------------------------------------

## Prerequisites

- Azure Kubernetes Service (AKS) cluster
- Istio service mesh deployed
- kubectl access configured

--------------------------------------------------------------------------------

## Install Process

Modify the `values.yaml` for the chart or create a `custom_values.yaml` with the following required values:

```yaml
azure:
  region: <your_azure_region>          # Azure region, e.g. eastus
  dnsName: <your_dns_label>            # Unique DNS label for the cluster
istioServiceName: istio-ingressgateway # Name of the Istio service
istioNamespace: istio-system           # Namespace of the Istio service
maxRetries: 30                         # Max retries for waiting on LoadBalancer IP
retryInterval: 10                      # Seconds between retries
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
| `azure.uniqueId`         | Unique ID for the cluster                | `""`                  |

--------------------------------------------------------------------------------
## Output

The chart creates a ConfigMap named `dns-config` in the release namespace containing:

- `external_ip`: The LoadBalancer external IP address
- `fqdn`: The fully qualified domain name
- `dns_label`: The DNS label assigned

Other services can reference this ConfigMap to obtain the FQDN for certificate generation and gateway configuration.