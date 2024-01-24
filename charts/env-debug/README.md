# Helm Chart for Environment Debuging

__Create a Custom Values__

_The following commands can help generate a prepopulated custom_values file._
```bash
# Setup Variables
RAND="<your_random_value>"               # ie: bedfb

GROUP=$(az group list --query "[?contains(name, 'ctl${UNIQUE}')].name" -otsv)
ENV_VAULT=$(az keyvault list --resource-group $GROUP --query [].name -otsv)

# Translate Values File
cat > custom_values.yaml << EOF
replicaCount: 1

nameOverride: ""
fullnameOverride: ""

service:
  type: ClusterIP
  port: 80
  targetPort: 8080

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80

################################################################################
# Specify the azure environment specific values
#
azure:
  enabled: true
  tenant: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/tenant-id --query value -otsv)
  subscription: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/subscription-id --query value -otsv)
  resourcegroup: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/base-name-cr --query value -otsv)-rg
  identity: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/base-name-cr --query value -otsv)-osdu-identity
  identity_id: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/osdu-identity-id --query value -otsv)
  keyvault: $ENV_VAULT
  appid: $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/aad-client-id --query value -otsv)

env:
- name: MESSAGE
  value: Hello World!
- name: AZURE_TENANT_ID
  secret:
    name: active-directory
    key: tenantid
- name: WORKSPACE_ID
  secret:
    name: central-logging
    key: workspace-id

EOF


__Install Helm Chart__

Install the helm chart.

```bash
# Create Namespace
NAMESPACE=dev-sample
helm upgrade --install dev-sample . -n $NAMESPACE --create-namespace
```
