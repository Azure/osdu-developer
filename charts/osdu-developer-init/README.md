# Helm Chart for Initializing OSDU Core

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Translate Values File
cat > custom_values.yaml << EOF
nameOverride: ""
fullnameOverride: "osdu-init"

jobs:
  entitlementInit: true
  partitionInit: true
tenantId: <your_tenant_id>
clientId: <your_client_id>
clientSecret:
  name: active-directory
  key: principal-clientpassword
partition: opendes
serviceBus: <your_service_bus_name>
EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=osdu-init
helm upgrade --install osdu-init . -n $NAMESPACE -f custom_values.yaml
```
