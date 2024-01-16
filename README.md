# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

This project is intended to provide a simple way of providing a mechanism to develop for OSDU using the Azure Cloud.

## Project Principals

The guiding principal we have for this project is to focus on providing a solution to allow for an easy way to develop for OSDU using the Azure cloud. It is not intended to support any kind of a production scenario and no support for this solution is provided.  It is built with the following 2 pillars of the [Azure Well-Architected-Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework) kept in mind.

1. Cost Optimization -- A cost optimized solution with cost in mind but accepting the tradeoff of security.
2. Security -- The intent is to provide a feature enabled solution to increase levels of security as best as possible.

Additionally, the solution is desired to be easy to use and to support that is built with support for [Github Codespaces](https://github.com/features/codespaces) along with the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/).


## Setup

__Features__

This solution makes use of features in Azure that are in Public Preview and might require some features to be registered for use.

Register the _AzureServiceMeshPreview_ feature flag by using the az feature register command:

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

It takes a few minutes for the feature to register. Verify the registration status by using the az feature show command:

```bash
az feature show --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

When the status reflects Registered, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command:

```bash
az provider register --namespace Microsoft.ContainerService
```

This solution uses Resource Group Scoped Deployments which is an Alpha Feature for the Azure Developer CLI.

```bash
azd config set alpha.resourceGroupDeployments on   # Enable Alpha Feature
```

__Login__

Log into the Azure CLI from a command line and set the subscription. 
If running with windows ensure that Azure Powershell is connected as well.

```bash
azd auth login
```

__Environment Variables__

An environment must be created using the following environment variables.

**Environment Variables**

An environment must be created using the following environment variables.

| Variable              | Purpose                                 |
| :-------------------- | :-------------------------------------- |
| AZURE_SUBSCRIPTION_ID | The Azure Subscription _(GUID)_         |
| AZURE_LOCATION        | The Azure Region                        |
| AZURE_CLIENT_ID       | Azure AD Application Client Id _(GUID)_ |

```bash
azd init -e dev

APP_NAME=                                          # <-- <your_ad_application_name>
azd env set AZURE_CLIENT_ID $(az ad app list --display-name $APP_NAME --query "[].appId" -otsv)
```

### Workspace

The developer workspace is brought online using the azure developer cli

| Action | Command                    |
| :----- | :------------------------- |
| Start  | `azd up`                   |
| Stop   | `azd down --purge --force` |


![[0]][0]
_Architecture Diagram_

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.

[0]: docs/images/architecture.png "Architecture Diagram"