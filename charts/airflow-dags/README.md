## Install Process

Either manually modify the values.yaml for the chart or generate a custom_values yaml to use.

_The following commands can help generate a prepopulated custom_values file._
```bash
# Setup Variables
GROUP=<your_group>

# Translate Values File
cat > custom_values.yaml << EOF
################################################################################
# Specify the airflow dags specific values
#
airflow:
  manifestdag:
    enabled: true
    items:
      - name: manifest
        folder: "src/osdu_dags"
        compress: true
        url: "https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags/-/archive/master/ingestion-dags-master.tar.gz"
        pvc: "airflow-dags-pvc"
  csvdag:
    enabled: true
    folder: "airflowdags"
    compress: true
    url: "https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz"
    pvc: "airflow-dags-pvc"
    replacements:
      - find: '{| K8S_POD_OPERATOR_KWARGS or {} |}'
        replace:
          labels:
            aadpodidbinding: "osdu-identity"
          annotations:
            "sidecar.istio.io/inject": "false"
      - find: '{| ENV_VARS or {} |}'
        replace:
          storage_service_endpoint: "http://storage.osdu-core.svc.cluster.local/api/storage/v2"
          schema_service_endpoint: "http://schema.osdu-core.svc.cluster.local/api/schema-service/v1"
          search_service_endpoint: "http://search.osdu-core.svc.cluster.local/api/search/v2"
          partition_service_endpoint: "http://partition.osdu-core.svc.cluster.local/api/partition/v1"
          unit_service_endpoint: "http://unit.osdu-core.svc.cluster.local/api/unit/v2/unit/symbol"
          file_service_endpoint: "http://file.osdu-core.svc.cluster.local/api/file/v2"
          KEYVAULT_URI: "https://dummy-keyvault.vault.azure.net/"
          appinsights_key: "dummy-app-insights-key"
          azure_paas_podidentity_isEnabled: "false"
          AZURE_TENANT_ID: "dummy-tenant-id"
          AZURE_CLIENT_ID: "dummy-client-id"
          AZURE_CLIENT_SECRET: "dummy-client-secret"
          aad_client_id: "dummy-client-id"
      - find: '{| DAG_NAME |}'
        replace: 'csv-parser'
      - find: '{| DOCKER_IMAGE |}'
        replace: 'community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/csv-parser-v0-27-0-azure-1:60747714ac490be0defe8f3e821497b3cce03390'
      - find: '{| NAMESPACE |}'
        replace: 'airflow'

EOF

NAMESPACE=airflow
helm template airflow-dags . -f custom_values.yaml

helm upgrade --install airflow-dags -f custom_values.yaml . -n $NAMESPACE
```