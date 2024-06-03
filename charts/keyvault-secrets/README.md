# Helm Chart for Azure Key Vaults

This Helm chart is designed to manage secrets from Azure Key Vaults. The following instructions will guide you through creating a custom values file and installing the Helm chart.

## Create a Custom Values File

The following commands can help generate a prepopulated custom values file.

```bash
# Translate Values File
cat > custom_values.yaml << EOF
nameOverride: ""
fullnameOverride: ""

################################################################################
# Specify the azure environment specific values
#
azure:
  clientId: <your_client_id>
  keyvaultName: <your_keyvault>
  tenantId: <your_tenant_id>

secrets:
  - secretName: <a_secret_name>
    data:
      - key: <a_secret_key>
        vaultSecret: <your_keyvault_secret>

EOF
```


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=default
helm upgrade --install keyvault-secrets . -n default -f custom_values.yaml
```
