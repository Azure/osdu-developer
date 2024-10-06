# OSDU Core

This repository can be used to hold the source code for the OSDU Core Services.

Environment variables can be automatically generated and then be referenced in IntelliJ with the [EnvFile](https://plugins.jetbrains.com/plugin/7861-envfile) plugin.


## Partition Service

The partition service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: partition-azure
Class: opengroup.osdu.partition.provider.azure.PartitionApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
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
| `ENVIRONMENT`                           | `<your_environment>`                           | local or cloud                             |
| `AZURE_AD_TENANT_ID`                    | `<your_tenant_id>`                             | Azure tenant ID                            |
| `INTEGRATION_TESTER`                    | `<your_client_id>`                             | Azure client ID                            |
| `AZURE_TESTER_SERVICEPRINCIPAL_SECRET`  | `<your_client_secret>`                         | Azure client secret                        |
| `AZURE_AD_APP_RESOURCE_ID`              | `<your_client_id>`                             | Azure client ID                            |
| `PARTITION_BASE_URL`                    | `http://localhost:8080/`                       | Service URL                                |



## Entitlements Service

The entitlement service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: entitlements-v2-azure
Class: org.opengroup.osdu.entitlements.v2.azure.EntitlementsV2Application
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
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
| `SERVICE_DOMAIN_NAME`                | `dataservices.energy`                                  | Service domain name                        |
| `ROOT_DATA_GROUP_QUOTA`              | `5000`                                         | Root data group quota                      |
| `REDIS_TTL_SECONDS`                  | `1`                                            | Redis TTL in seconds                       |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_ACTIVEDIRECTORY_SESSION_STATELESS` | `true`                                    | Enable stateless session for AD            |



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

The legal service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: legal-azure
Class: org.opengroup.osdu.legal.azure.LegalApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

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



### Testing

The legal service can be tested locally in IntelliJ with the following run configuration

```
Build and Run Configuration: JUnit
---------------------------------------
Java SDK:  Java zulu-17
Module: legal-test-azure
All in package: org.opengroup.osdu.legal
```




## Schema Service

The schema service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: os-schema-azure
Class: org.opengroup.osdu.schema.azure.SchemaApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

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

The storage service can be run locally in IntelliJ with the following run configuration

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



## Indexer Service

The indexer service can be run locally in IntelliJ with the following run configuration

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






## Search Service

The search service can be run locally in IntelliJ with the following run configuration

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

## File Service

The file service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: file-azure
Class: org.opengroup.osdu.file.provider.azure.FileAzureApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```

| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1`        | Partition service endpoint                 |
| `OSDU_ENTITLEMENTS_URL`              | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `AAD_CLIENT_ID`                      | `<your_aad_client_id>`                         | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `file`                                         | Spring application name                    |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `LOG_PREFIX`                         | `file`                                         | Log prefix                                 |

## Workflow Service

The workflow service can be run locally in IntelliJ with the following run configuration

```
Build and Run Configuration: SpringBoot
---------------------------------------
Java SDK:  java zulu-17
Module: file-azure
Class: org.opengroup.osdu.workflow.provider.azure.WorkflowAzureApplication
VM Options: -javaagent:/<your_full_path>/osdu-developer/src/applicationinsights-agent.jar
```


| Variable                             | Value                                          | Description                                |
|--------------------------------------|------------------------------------------------|--------------------------------------------|
| `APPINSIGHTS_KEY`                    | `<your_appinsights_key>`                       | Application Insights key                   |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | `<your_appinsights_connection>`             | Application Insights Connection            |
| `KEYVAULT_URI`                       | `<your_keyvault_uri>`                          | Key Vault URI                              |
| `AZURE_HOST`                         | `<your_host_ip>`                               | Azure host IP                              |
| `PARTITION_SERVICE_ENDPOINT`         | `http://${AZURE_HOST}/api/partition/v1/`       | Partition service endpoint                 |
| `OSDU_ENTITLEMENTS_URL`              | `http://${AZURE_HOST}/api/entitlements/v2`     | Entitlements service endpoint              |
| `OSDU_AIRFLOW_URL`                   | `https://${AZURE_HOST}/airflow`                | Airflow URL                                |
| `AAD_CLIENT_ID`                      | `<your_aad_client_id>`                         | Active Directory client ID                 |
| `SPRING_APPLICATION_NAME`            | `workflow`                                     | Spring application name                    |
| `LOG_PREFIX`                         | `workflow`                                     | Log prefix                                 |
| `COSMOSDB_DATABASE`                  | `osdu-db`                                      | Cosmos DB database name                    |
| `COSMOSDB_SYSTEM_DATABASE`           | `osdu-system-db`                               | Cosmos DB system database name             |
| `AIRFLOW_STORAGE_ACCOUNT_NAME`       | `<your_storage_account_name>`                  | Airflow storage account name               |
| `AZURE_PAAS_PODIDENTITY`             | `false`                                        | Azure PaaS pod identity                    |
| `AZURE_ISTIOAUTH_ENABLED`            | `true`                                         | Turn Istio auth on                         |
| `AZURE_PAAS_PODIDENTITY_ISENABLED`   | `false`                                        | Azure PaaS pod identity enabled            |
| `OSDU_AIRFLOW_USERNAME`              | `<your_airflow_username>`                      | Airflow username                           |
| `OSDU_AIRFLOW_PASSWORD`              | `<your_airflow_password`                       | Airflow password                           |
| `OSDU_AIRFLOW_VERSION2_ENABLED`      | `true`                                         | Enable Airflow version 2                   |
| `DP_AIRFLOW_FOR_SYSTEM_DAG`          | `false`                                        | Use Airflow for system DAGs                |
| `IGNORE_DAGCONTENT`                  | `true`                                         | Ignore DAG content                         |
| `IGNORE_CUSTOMOPERATORCONTENT`       | `true`                                         | Ignore custom operator content             |
| `SERVER_PORT`                        | `8080`                                         | Server port                                |

// ... end of file ...