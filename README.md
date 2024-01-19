# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Open Subsurface Data Universe](https://osduforum.org) (OSDU) is a standard data platform that brings together a diverse array of subsurface and well data. It enables the energy industry to access and analyze data across various sources efficiently. This project aims to provide a streamlined approach for developing and working directly with [OSDU](https://community.opengroup.org/osdu/platform) using the [Azure Cloud Platform](https://azure.microsoft.com/).


## Project Principles

The guiding principle of this project is to offer an accessible solution for facilitating direct engagement with the OSDU codebase on Azure in a minimal fashion. This solution is not intended for production use and does not come with official support. Our approach aligns with two key pillars from the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework):

1. Cost Optimization -- We aim to create a cost-effective solution, balancing cost with security considerations.
2. Security -- Our goal is to enhance security levels within the constraints of a development-focused solution.

To support ease of use, the project integrates closely with [Github Codespaces](https://github.com/features/codespaces) and the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/), facilitating seamless development and innovation on the OSDU platform.


## Setup

### Registering Azure Features

This solution utilizes Azure features that are currently in Public Preview. Certain features need to be registered before use.

**Step 1: Register the AzureServiceMeshPreview feature**
Use the `az feature register` command to register the _AzureServiceMeshPreview_ feature flag:

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

It may take a few minutes for the feature to register.


**Step 2: Verify the Registration Status**

Confirm the registration status using the az feature show command:

```bash
az feature show --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

Look for a status that indicates Registered.

**Step 3: Refresh the Resource Provider**

Once registered, refresh the Microsoft.ContainerService resource provider:

```bash
az provider register --namespace Microsoft.ContainerService
```


## Templated Deployment

The solution can be deployed directly with the ARM template but parameter options can be difficult to navigate.  However, this method works just fine when leveraging a fully default deployment.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)



## Azure Developer CLI - Workflow

The recommended way for working with the solution is to leverage the Azure Developer CLI so that options can be better set, the solution modified or parameters changed in order to customize a deployment that has more flexability.

### Enabling Alpha Features for Azure Developer CLI

**Resource Group Scoped Deployments**

This solution uses Resource Group Scoped Deployments, an Alpha Feature in the Azure Developer CLI.

Enable this feature using the following command:

```bash
azd config set alpha.resourceGroupDeployments on   # Enable Alpha Feature
```

Note: Alpha features are experimental and might be subject to changes. Use them with this consideration.


### Authentication

The Azure Developer CLI requires authentication.  Log in using the following command:

```bash
azd auth login
```

### Environment Variables

Set up the environment using the following variables. You can find these values in your Azure portal or by using appropriate Azure CLI commands.


| Variable              | Purpose                                 |
| :-------------------- | :-------------------------------------- |
| AZURE_SUBSCRIPTION_ID | The Azure Subscription _(GUID)_         |
| AZURE_LOCATION        | The Azure Region                        |
| AZURE_CLIENT_ID       | Azure AD Application Client Id _(GUID)_ |
| ENABLE_POD_SUBNET     | Feature Flag - Pod Subnet               |
| ENABLE_BASTION        | Feature Flag - Bastion and Manage VM    |
| ENABLE_VPN_GATEWAY    | Feature Flag - VPN Site to Site         |


Initialize the environment and set the Azure Client ID:

```bash
azd init -e dev

APP_NAME=   # <-- <your_ad_application_name>

azd env set AZURE_CLIENT_ID $(az ad app list --display-name $APP_NAME --query "[].appId" -otsv)

# Feature Flags (Optional)
azd env set ENABLE_POD_SUBNET true
azd env set ENABLE_BASTION true
azd env set ENABLE_VPN_GATEWAY true
```


_Feature: Pod Subnet_

With kubenet, nodes get an IP address from the Azure virtual network subnet. With this feature enables the Pods receive an IP address from a logically different address space then the Azure virtual network subnet of the nodes.


_Feature: Bastion_

With internal ingress enabled it can be challenging to communicate.  The bastion feature if enabled will create a bastion host and a virtual machine that can be used to communicate to resources from the private network.


_Feature: VPN Gateway_

It is common to have site to site VPN connections and the ability to optionally configure a point to site vpn connction when using internal ingress.  Development in this scenario can be challenging. The vpn gateway feature if enabled assists in creating the required resources necessary to establish connections to the private network.

Additional values are necessary with this feature.

1. REMOTE_NETWORK_PREFIX - The CIDR of the remote network. (192.168.1.0/24)
2. REMOTE_VPN_ADDRESS - The Remote VPN Gateway IP address.
3. VPN_SHARED_KEY - The Shared Key for the VPN Connection.


### Commands

The solution template is provisioned using the azure developer cli.

| Action | Command                    |
| :----- | :------------------------- |
| Start  | `azd provision`            |
| Stop   | `azd down --purge --force` |


## Infrastructure

The following diagram helps to visualize the architecture of the resources.

![[0]][0]



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