# Entitlements

The entitlement service can be run locally in editors with the following configuration.

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
