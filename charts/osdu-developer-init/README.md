# Helm Chart for Initializing OSDU Core

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Translate Values File
cat > custom_values.yaml << EOF
nameOverride: ""
fullnameOverride: "osdu-init"

tenantId:
clientId:
clientSecret:
serviceBus:
partition:
EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=osdu-core
helm template osdu-core-osdu-init-user -f custom_values.yaml .

helm upgrade --install osdu-core-osdu-init-partition . -n $NAMESPACE -f custom_values.yaml
```
