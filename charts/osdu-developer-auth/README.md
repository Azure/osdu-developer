# Helm Chart for Creating Config Maps from App Configuration

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Translate Values File
cat > custom_values.yaml << EOF
nameOverride: ""
fullnameOverride: "osdu-auth"

EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=default
helm upgrade --install osdu-auth . -n $NAMESPACE -f custom_values.yaml
```
