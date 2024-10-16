# Partition

The partition service can be run locally in editors with the following configuration.

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
