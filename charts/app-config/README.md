# Helm Chart for App Configuration

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Translate Values File
cat > custom_values.yaml << EOF
azureWorkloadIdentity:
  clientId: "<your_client_id"

appConfiguration:
  endpoint: "<your_endpoint>"
EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=dev-sample
helm install app-config . -n $NAMESPACE --create-namespace
```
