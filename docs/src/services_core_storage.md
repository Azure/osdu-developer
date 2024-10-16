# Storage

The storage service can be run locally in editors with the following configuration.

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: storage-azure
Class: org.opengroup.osdu.storage.provider.azure.StorageApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `LEGAL_SERVICE_ENDPOINT`             | `http://${AZURE_HOST}/api/legal/v1`            | Legal service endpoint                     |
| `AAD_CLIENT_ID`                      | `<your_aad_client_id>`                         | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `storage`                                      | Spring application name                    |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `LOG_PREFIX`                         | `storage`                                      | Log prefix                                 |
| `AZURE_STORAGE_ENABLE_HTTPS`         | `true`                                         | Enable HTTPS for Azure storage             |
| `COSMOSDB_DATABASE`                  | `osdu-db`                                      | Cosmos DB database name                    |
| `SERVER_PORT`                        | `8080`                                         | Server port                                |
| `SERVICEBUS_TOPIC_NAME`              | `recordstopic`                                 | Service Bus topic name                     |
| `SERVICEBUS_V2_TOPIC_NAME`           | `recordstopic-v2`                              | Service Bus topic name (version 2)         |
| `REDIS_DATABASE`                     | `4`                                            | Redis database number                      |
| `ENTITLEMENTS_SERVICE_API_KEY`       | `OBSOLETE`                                     | Entitlements service API key               |
| `LEGAL_SERVICE_REGION`               | `southcentralus`                               | Legal service region                       |
| `LEGAL_SERVICEBUS_TOPIC_NAME`        | `legaltagschangedtopiceg`                      | Legal service bus topic name               |
| `LEGAL_SERVICEBUS_TOPIC_SUBSCRIPTION`| `eg_sb_legaltagchangedsubscription`            | Legal service bus topic subscription       |
| `OPA_ENABLED`                        | `false`                                        | Enable OPA                                 |

