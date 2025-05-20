# Helm Chart for DNS Configuration

This chart configures DNS labels for Azure Kubernetes Service (AKS) LoadBalancer IPs, enabling automatic FQDN assignment for OSDU services.

## Prerequisites

- Azure Kubernetes Service (AKS) cluster with workload identity enabled
- Istio service mesh deployed
- Azure CLI and kubectl access configured

## Create a Custom Values File

Create a custom values file by running the following commands:

```bash
GROUP=<your_resource_group>

SUBSCRIPTION=$(az account show --query id -otsv)
AKS_NAME=$(az aks list --resource-group $GROUP --query "[0].name" -otsv)

cat > values.yaml <<EOF
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

## Manual Testing

Test the chart locally:

```bash
# Template the chart to see generated resources
helm template dns-configuration . -f custom_values.yaml
```

## Install Helm Chart

Install the chart manually:

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

## Uninstall

Remove the chart:

```bash
# Uninstall the release
helm uninstall dns-configuration -n $NAMESPACE

# Manually clean up ConfigMap if needed
kubectl delete configmap dns-config -n $NAMESPACE
```

## Configuration Options

The following table lists the configurable parameters and their default values.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `serviceAccount.create` | Create a new service account | `false` |
| `serviceAccount.name` | Service account name to use | `workload-identity-sa` |
| `azure.tenantId` | Azure tenant ID | `<your_tenant_id>` |
| `azure.clientId` | Azure client ID for workload identity | `<your_client_id>` |
| `azure.subscription` | Azure subscription ID | `<your_subscription_id>` |
| `azure.resourceGroup` | Resource group containing the AKS cluster | `<your_resource_group>` |
| `azure.aksName` | AKS cluster name | `<your_aks_cluster_name>` |
| `azure.uniqueId` | Unique ID for the cluster | `""` |
| `dns.prefix` | DNS prefix for FQDN | `osdu` |
| `dns.maxRetries` | Max retries for LoadBalancer IP | `60` |
| `dns.retryInterval` | Retry interval in seconds | `10` |
| `istio.serviceName` | Istio ingress service name | `istio-ingressgateway` |
| `istio.namespace` | Istio namespace | `istio-system` |
| `job.ttlSecondsAfterFinished` | Job cleanup TTL | `300` |

## Output

The chart creates a ConfigMap named `dns-config` in the default namespace containing:

- `external_ip`: The LoadBalancer external IP address
- `fqdn`: The fully qualified domain name
- `dns_label`: The DNS label assigned

Other services can reference this ConfigMap to obtain the FQDN for certificate generation and gateway configuration.