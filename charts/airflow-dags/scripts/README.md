# CSV DAG Processing Scripts

This directory contains scripts for processing and deploying CSV parser DAGs.

## Manual Testing Instructions

1. Create a test directory and copy both `csv-dag.sh` and `replace.py` into it:

```bash
mkdir test-csvdag
cd test-csvdag
cp ../csv-dag.sh ../replace.py .
```

2. Create local directories for mounting:
```bash
mkdir scripts share
cp replace.py scripts/
```

3. Export these environment variables by running the following commands:
```bash
export URL="https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser/-/archive/master/csv-parser-master.tar.gz"
export FILE="airflowdags"
export SEARCH_AND_REPLACE='[
  {
    "find": "{| K8S_POD_OPERATOR_KWARGS or {} |}", 
    "replace": {
      "labels": {
        "aadpodidbinding": "osdu-identity"
      },
      "annotations": {
        "sidecar.istio.io/inject": "false"
      }
    }
  },
  {
    "find": "{| ENV_VARS or {} |}", 
    "replace": {
      "storage_service_endpoint": "http://storage.osdu-core.svc.cluster.local/api/storage/v2",
      "schema_service_endpoint": "http://schema.osdu-core.svc.cluster.local/api/schema-service/v1",
      "search_service_endpoint": "http://search.osdu-core.svc.cluster.local/api/search/v2",
      "partition_service_endpoint": "http://partition.osdu-core.svc.cluster.local/api/partition/v1",
      "unit_service_endpoint": "http://unit.osdu-core.svc.cluster.local/api/unit/v2/unit/symbol",
      "file_service_endpoint": "http://file.osdu-core.svc.cluster.local/api/file/v2",
      "KEYVAULT_URI": "https://dummy-keyvault.vault.azure.net/",
      "appinsights_key": "dummy-app-insights-key",
      "azure_paas_podidentity_isEnabled": "false",
      "AZURE_TENANT_ID": "dummy-tenant-id",
      "AZURE_CLIENT_ID": "dummy-client-id",
      "AZURE_CLIENT_SECRET": "dummy-client-secret",
      "aad_client_id": "dummy-client-id"
    }
  }
]'
```

4. Run the script in a CBL-Mariner container:
```bash
docker run -it --rm \
  -v "$(pwd)/scripts:/scripts" \
  -v "$(pwd)/share:/share" \
  -v "$(pwd)/csv-dag.sh:/csv-dag.sh" \
  -e URL="$URL" \
  -e FILE="$FILE" \
  -e SEARCH_AND_REPLACE="$SEARCH_AND_REPLACE" \
  mcr.microsoft.com/cbl-mariner/base/python:3 \
  /bin/bash /csv-dag.sh
```

5. Check the results in the local share directory:
```bash
ls -l share/
```

### Notes
- The script will create a zip file in the mounted `share` directory
- All temporary files are created inside the container and cleaned up automatically
- The container is removed after execution (`--rm` flag)