# Indexer

The indexer service can be run locally in editors with the following configuration.

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: indexer-azure
Class: org.opengroup.osdu.indexer.azure.IndexerAzureApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `SCHEMA_SERVICE_URL`                 | `http://${AZURE_HOST}/api/schema-service/v1`   | Schema service endpoint                    |
| `STORAGE_SERVICE_URL`                | `http://${AZURE_HOST}/api/storage/v2`          | Storage service endpoint                   |
| `STORAGE_QUERY_RECORD_HOST`          | `http://${AZURE_HOST}/api/storage/v2/query/records`         | Storage service record query endpoint      |
| `STORAGE_QUERY_RECORD_FOR_CONVERSION_HOST` | `http://${AZURE_HOST}/api/storage/v2/query/records:batch`         | Storage service record batch query endpoint      |
| `AAD_CLIENT_ID`                      | `<your_aad_client_id>`                         | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `indexer`                                      | Spring application name                    |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `LOG_PREFIX`                         | `indexer`                                      | Log prefix                                 |
