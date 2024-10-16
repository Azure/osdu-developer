# Workflow

The workflow service can be run locally in editors with the following configuration.

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