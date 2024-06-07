# Service Environment Variables

The following information can be used as a guide for the required environment variables necessary to start a service locally, and the [local.http](../tools/rest-scripts/local.http) rest script can be used for a quick test to call the local services.

Environment Variables can be referenced in IntelliJ with the [EnvFile](https://plugins.jetbrains.com/plugin/7861-envfile) plugin.

## Partition Service

The partition service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: partition-azure
Class: opengroup.osdu.partition.provider.azure.PartitionApplication
```

The following environment variables are necessary to run the Partition Service.


| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_insights_key>`                          | Application Insights key                   |
| `KEYVAULT_URI`                       | `"https://<your_storage_name>.vault.azure.net"`| Key Vault URI                              |
| `AAD_CLIENT_ID`                      | `<your_client_id>`                             | Active Directory client ID                 |
| `SERVER_PORT`                        | `8080`                                         | HTTP Server Port                           |
| `SPRING_APPLICATION_NAME`            | `partition`                                    | Spring application name                    |
| `REDIS_DATABASE`                     | `1`                                            | Redis database number                      |
| `PARTITION_SPRING_LOGGING_LEVEL`     | `INFO`                                         | Logging level for the Partition service    |
| `AZURE_ISTIOAUTH_ENABLED`            | `false`                                        | Turn Istio auth off                        |
| `AZURE_ACTIVEDIRECTORY_APP_ID_URI`   | `api://<your_client_id>`                       | Active Directory app ID URI                |
| `AZURE_ACTIVEDIRECTORY_SESSION_STATELESS` | `true`                                    | Enable stateless session for AD            |






```json
{
  "APPINSIGHTS_KEY": "<your_insights_key>",
  "KEYVAULT_URI": "https://<your_keyvault_name.vault.azure.net",
  "AAD_CLIENT_ID": "<your_client_id>",
  "SERVER_PORT": "8080",
  "SPRING_APPLICATION_NAME": "partition",
  "REDIS_DATABASE": "1",
  "PARTITION_SPRING_LOGGING_LEVEL": "INFO",
  "AZURE_ISTIO_AUTH_ENABLED": "false",
  "AZURE_ACTIVEDIRECTORY_APP_ID_URI": "api://<your_client_id>",
  "AZURE_ACTIVEDIRECTORY_SESSION_STATELESS": "true"
}
```

### Testing

The partition service can be tested locally in IntelliJ with the following run configuration

```
Build and Run Configuration: JUnit
---------------------------------------
Java SDK:  Java zulu-17
Module: partition-test-azure
All in package: org.opengroup.osdu.partition
```

| Variable                                | Value                                          | Description                                |
|-----------------------------------------|------------------------------------------------|--------------------------------------------|
| `AZURE_AD_TENANT_ID`                    | `<your_tenant_id>`                             | Azure tenant ID                            |
| `INTEGRATION_TESTER`                    | `<your_client_id>`                             | Azure client ID                            |
| `AZURE_TESTER_SERVICEPRINCIPAL_SECRET`  | `<your_client_secret>`                         | Azure client secret                        |
| `AZURE_AD_APP_RESOURCE_ID`              | `<your_client_id>`                             | Azure client ID                            |
| `PARTITION_BASE_URL`                    | `http://localhost:8080/`                       | Service URL                                |

```json
{
  "AZURE_AD_TENANT_ID": "<your_tenant_id>",
  "INTEGRATION_TESTER": "<your_client_id>",
  "AZURE_TESTER_SERVICEPRINCIPAL_SECRET": "<your_client_secret>",
  "AZURE_AD_APP_RESOURCE_ID": "<your_client_id>",
  "PARTITION_BASE_URL": "http://localhost:8080/"
}
```


## Entitlements Service

The entitlement service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: entitlements-v2-azure
Class: org.opengroup.osdu.entitlements.v2.azure.EntitlementsV2Application
```

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_insights_key>`                          | Application Insights key                   |
| `KEYVAULT_URI`                       | `"https://${KV_NAME}.vault.azure.net"`         | Key Vault URI                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `AAD_CLIENT_ID`                      | `${AZURE_CLIENT_ID}`                           | Active Directory client ID                 |
| `SERVER_PORT`                        | `8080`                                         | HTTP Server Port                           |
| `SPRING_APPLICATION_NAME`            | `entitlements`                                 | Spring application name                    |
| `LOGGING_LEVEL`                      | `INFO`                                         | Logging level for the Entitlements service |
| `SERVICE_DOMAIN_NAME`                | `contoso.com`                                  | Service domain name                        |
| `ROOT_DATA_GROUP_QUOTA`              | `5000`                                         | Root data group quota                      |
| `REDIS_TTL_SECONDS`                  | `1`                                            | Redis TTL in seconds                       |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_ACTIVEDIRECTORY_SESSION_STATELESS` | `true`                                    | Enable stateless session for AD            |

```json
{
  "APPINSIGHTS_KEY": "<your_insights_key>",
  "KEYVAULT_URI": "https://<your_keyvault_name.vault.azure.net",
  "PARTITION_SERVICE_ENDPOINT": "http://<your_ingress_ip>/api/partition/v1/",
  "AAD_CLIENT_ID": "<your_client_id>",
  "SERVER_PORT": "8080",
  "SPRING_APPLICATION_NAME": "entitlements",
  "LOGGING_LEVEL": "INFO",
  "SERVICE_DOMAIN_NAME": "contoso.com",
  "ROOT_DATA_GROUP_QUOTA": "5000",
  "REDIS_TTL_SECONDS": "1",
  "AZURE_PAAS_PODIDENTITY": "false",
  "AZURE_ISTIO_AUTH_ENABLED": "true",
}
```

### Testing

The entitlement service can be tested locally in IntelliJ with the following run configuration

```
Build and Run Configuration: JUnit
---------------------------------------
Java SDK:  Java zulu-17
Module: entitlementsv2-test-azure
All in package: org.opengroup.osdu.entitlements
```


## Legal Service

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `KV_NAME`                            | `<your_keyvault_name>`                         | Key Vault name                             |
| `AZURE_TENANT_ID`                    | `<your_tenant_id>`                             | Azure tenant ID                            |
| `AZURE_CLIENT_ID`                    | `<your_client_id>`                             | Azure client ID                            |
| `AZURE_CLIENT_SECRET`                | `<your_client_secret>`                         | Azure client secret                        |
| `APPINSIGHTS_KEY`                    | `<your_insights_key>`                          | Application Insights key                   |
| `KEYVAULT_URI`                       | `"https://${KV_NAME}.vault.azure.net"`         | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `SPRING_APPLICATION_NAME`            | `legal`                                        | Spring application name                    |
| `AAD_CLIENT_ID`                      | `${AZURE_CLIENT_ID}`                           | Active Directory client ID                 |
| `REDIS_DATABASE`                     | `2`                                            | Redis database number                      |
| `SERVICEBUS_TOPIC_NAME`              | `legaltags`                                    | Service Bus topic name                     |
| `COSMOSDB_DATABASE`                  | `osdu-db`                                      | Cosmos DB database name                    |
| `ENTITLEMENTS_SERVICE_API_KEY`       | `OBSOLETE`                                     | Entitlements service API key               |
| `LEGAL_SERVICE_REGION`               | `us`                                           | Legal service region                       |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `AZURE_ISTIO_AUTH_ENABLED`           | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `AZURE_ACTIVEDIRECTORY_APP_ID_URI`   | `api://${AZURE_CLIENT_ID}`                     | Active Directory app ID URI                |
| `AZURE_ACTIVEDIRECTORY_SESSION_STATELESS` | `true`                                    | Enable stateless session for AD            |



## Schema Service

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `KV_NAME`                            | `<your_keyvault_name>`                         | Key Vault name                             |
| `STORAGE_ACCOUNT`                    | `<your_storage_account>`                       | Storage account name                       |
| `AZURE_TENANT_ID`                    | `<your_tenant_id>`                             | Azure tenant ID                            |
| `AZURE_CLIENT_ID`                    | `<your_client_id>`                             | Azure client ID                            |
| `AZURE_CLIENT_SECRET`                | `<your_client_secret>`                         | Azure client secret                        |
| `APPINSIGHTS_KEY`                    | `<your_insights_key>`                          | Application Insights key                   |
| `KEYVAULT_URI`                       | `"https://${KV_NAME}.vault.azure.net"`         | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `AAD_CLIENT_ID`                      | `${AZURE_CLIENT_ID}`                           | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `schema`                                       | Spring application name                    |
| `LOG_PREFIX`                         | `schema`                                       | Log prefix                                 |
| `AZURE_STORAGE_ENABLE_HTTPS`         | `true`                                         | Enable HTTPS for Azure storage             |
| `COSMOSDB_DATABASE`                  | `osdu-db`                                      | Cosmos DB database name                    |
| `ENTITLEMENTS_SERVICE_API_KEY`       | `OBSOLETE`                                     | Entitlements service API key               |
| `SERVER_PORT`                        | `8080`                                         | Server port                                |
| `EVENT_GRID_ENABLED`                 | `false`                                        | Enable Event Grid                          |
| `EVENT_GRID_TOPIC`                   | `schemachangedtopic`                           | Event Grid topic                           |
| `SERVICE_BUS_ENABLED`                | `true`                                         | Enable Service Bus                         |
| `SERVICEBUS_TOPIC_NAME`              | `schemachangedtopic`                           | Service Bus topic name                     |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |


## Storage Service

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `PARTITION_SERVICE_ENDPOINT`         | `<your_partition_service_endpoint>`            | Partition service endpoint                 |
| `ENTITLEMENTS_SERVICE_ENDPOINT`      | `<your_entitlements_service_endpoint>`         | Entitlements service endpoint              |
| `LEGAL_SERVICE_ENDPOINT`             | `<your_legal_service_endpoint>`                | Legal service endpoint                     |
| `CRS_CONVERSION_SERVICE_ENDPOINT`    | `<your_crs_conversion_service_endpoint>`       | CRS Conversion service endpoint            |
| `POLICY_SERVICE_ENDPOINT`            | `<your_policy_service_endpoint>`               | Policy service endpoint                    |
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