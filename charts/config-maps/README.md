# Helm Chart for Creating Config Maps from App Configuration

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Setup Variables
GROUP=$<your_resource_group>

# Translate Values File
cat > custom_values.yaml << EOF
nameOverride: ""
fullnameOverride: "config-map-ac"

serviceAccount:
  create: false
  name: "workload-identity-sa"
azure:
  tenantId: $(az account show --query tenantId -otsv)
  configEndpoint: $(az appconfig list --resource-group $GROUP --query '[].endpoint' -otsv)
  clientId: $(az identity list --resource-group $GROUP --query "[?contains(name, 'service')].clientId" -otsv)
  keyvaultUri: $(az keyvault list --resource-group $GROUP --query '[].properties.vaultUri' -otsv)
  keyvaultName: $(az keyvault list --resource-group $GROUP --query '[].name' -otsv)
EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=default
helm upgrade --install config-maps . -n $NAMESPACE -f custom_values.yaml
```
