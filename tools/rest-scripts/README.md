# Rest Scripts

This directory has scripts to assist in making rest calls.
-----------------------------------------------------------------

## Getting Started

1. Once you have vscode running, you want to make sure and install the [rest-client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension.  An environment has been configured in `.vscode/settings.json` that adheres to the following format.

```json
{
    "rest-client.environmentVariables": {
        "${AZURE_RESOURCE_GROUP}": {
          "TENANT_ID": "${AZURE_TENANT_ID}",
          "CLIENT_ID": "${AZURE_CLIENT_ID}",
          "CLIENT_SECRET": "${AZURE_CLIENT_SECRET}",
          "HOST": "${AUTH_INGRESS}",
          "REFRESH_TOKEN": "${AUTH_REFRESH}",
          "DATA_PARTITION": "opendes"
        }
    }
}
```

