
## Install Process

Either manually modify the values.yaml for the chart or generate a custom_values yaml to use.

_The following commands can help generate a prepopulated custom_values file._
```bash
GROUP=$<your_resource_group>

# Translate Values File
cat > custom_values.yaml << EOF
################################################################################
# Specify the azure environment specific values
#
EOF

NAMESPACE=osdu-azure
helm template osdu-developer-service -f custom_values.yaml .

helm upgrade --install osdu-developer-service -f custom_values.yaml . -n $NAMESPACE
```

