
## Install Process

Either manually modify the values.yaml for the chart or generate a custom_values yaml to use.

_The following commands can help generate a prepopulated custom_values file._
```bash
# Setup Variables
GROUP=<your_group>

# Translate Values File
cat > custom_values.yaml << EOF
################################################################################
# Specify the azure environment specific values
#
azure:
  tenantId: $(az account show --query tenantId -otsv)
  clientId: $(az identity list --resource-group $GROUP --query "[?contains(name, 'service')].clientId" -otsv)
  keyvaultName: $(az keyvault list --resource-group $GROUP --query '[].name' -otsv)

################################################################################
# Specify the resource limits
#
resourceLimits:
  defaultCpuRequests: "0.5"
  defaultMemoryRequests: "4Gi"
  defaultCpuLimits: "1"
  defaultMemoryLimits: "4Gi"
EOF

NAMESPACE=osdu-azure
helm template osdu-developer-base . -f custom_values.yaml

helm upgrade --install osdu-developer-base -f custom_values.yaml . -n $NAMESPACE
```