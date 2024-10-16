# Search

The search service can be run locally in editors with the following configuration.

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: search-azure
Class: org.opengroup.osdu.search.provider.azure.SearchApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `POLICY_SERVICE_ENDPOINT`            | `http://${AZURE_HOST}/policy/api/policy/v1`    | Policy service endpoint                    |
| `AAD_CLIENT_ID`                      | `<your_aad_client_id>`                         | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `search`                                       | Spring application name                    |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `LOG_PREFIX`                         | `search`                                       | Log prefix                                 |
| `SEARCH_SERVICE_SPRING_LOGGING_LEVEL`| `DEBUG`                                        | Logging level for the Search service       |
| `ENTITLEMENTS_SERVICE_API_KEY`       | `OBSOLETE`                                     | API Key for Entitlements                   |
| `POLICY_SERVICE_ENABLED`             | `false`                                        | Enable Policy Service                      |
| `COSMOSDB_DATABASE`                  | `osdu-db`                                      | Cosmos DB database name                    |
| `REDIS_DATABASE`                     | `5`                                            | Redis database number                      |
| `ENVIRONMENT`                        | `evt`                                          | Environment                                |
| `ELASTIC_CACHE_EXPIRATION`           | `1`                                            | Elastic cache expiration                   |
| `MAX_CACHE_VALUE_SIZE`               | `60`                                           | Maximum cache value size                   |
| `PARTITION_SERVICE_ENDPOINT`         | `http://partition/api/partition/v1`            | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://entitlements/api/entitlements/v2`      | Entitlements service endpoint              |
| `POLICY_SERVICE_ENDPOINT`            | `http://policy/api/policy/v1`                  | Policy service endpoint                    |