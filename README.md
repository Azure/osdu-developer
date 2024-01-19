# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Open Subsurface Data Universe](https://osduforum.org) (OSDU) is a standard data platform that brings together a diverse array of subsurface and well data. It enables the energy industry to access and analyze data across various sources efficiently. This project aims to provide a streamlined approach for developing and working directly with [OSDU](https://community.opengroup.org/osdu/platform) using the [Microsoft Azure Cloud](https://azure.microsoft.com/).


## Project Principles

The guiding principle of this project is to offer an accessible solution for facilitating direct engagement with the OSDU codebase on Azure in a minimal fashion. This solution is not intended for production use and does not come with official support. Our approach aligns with two key pillars from the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework):

1. Cost Optimization -- We aim to create a cost-effective solution, balancing cost with security considerations.
2. Security -- Our goal is to enhance security levels within the constraints of a development-focused solution.

To support ease of use, the project integrates closely with [Github Codespaces](https://github.com/features/codespaces) and the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/), facilitating seamless development and innovation on the OSDU platform.


## Setup

This section guides you through setting up the necessary Azure features for the OSDU Developer project. Please note that this solution uses Azure features currently in Public Preview, which might not be fully stable and are subject to changes.

### Registering Azure Features

Before you begin, you need to register specific features in Azure that the OSDU Developer solution relies on. Here's how to do it:


**Step 1: Register the AzureServiceMeshPreview feature**

The AzureServiceMeshPreview feature enables [AKS service mesh addon for Istio](https://learn.microsoft.com/en-us/azure/aks/istio-about) essential for the OSDU Developer solution. To register this feature, use the Azure CLI command below:

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

_* Please wait a few minutes for the feature to register. The process might take up to 10 minutes._


**Step 2: Verify the Registration Status**

After registering the feature, ensure that the registration was successful. Check the status using the following command:

```bash
az feature show --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
```

Look for a status that indicates "Registered". If the status hasn't updated, you may need to wait a little longer and try again.


**Step 3: Refresh the Resource Provider**

Once the feature is registered, it's necessary to refresh the resource provider to apply the changes. Use this command to refresh the Microsoft.ContainerService resource provider:

```bash
az provider register --namespace Microsoft.ContainerService
```

With these steps, you have successfully registered the necessary Azure features to work with the OSDU Developer project. Next, you can proceed to the deployment phase.


## Templated Deployment

Deploying the OSDU solution is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, it's worth noting that navigating parameter options can be challenging. For users seeking customization, we recommend using the Azure Developer CLI - Workflow, detailed in the following section.

To facilitate a smooth deployment experience, we provide a "Deploy to Azure" button. Clicking this button will redirect you to the Azure portal, where the ARM template is pre-loaded for your convenience.

__Important Parameter Requirement:__

During the deployment process, there's one essential parameter you need to provide:

`applicationClientId`: Fill this with the Application ClientId that you intend to use for the OSDU solution. This step is crucial for the proper functioning of the template.
Upon completing the deployment, the infrastructure and software components of the OSDU solution will be automatically provisioned. This includes loading the software configuration through a [GitOps](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gitops-aks/gitops-blueprint-aks) approach, enabled by AKS (Azure Kubernetes Service).

To begin, simply click the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)



## Azure Developer CLI - Workflow

The recommended approach for working with the OSDU solution is through the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview). This method provides greater flexibility for customization and setting options. Here’s a streamlined guide to using the Azure Developer CLI:


### Enabling Alpha Features for Azure Developer CLI

This solution utilizes Alpha Features in the Azure Developer CLI for advanced functionalities.

**Resource Group Scoped Deployments**

This allows more granular control over deployments at the resource group level.

Enable this feature using the following command:

```bash
azd config set alpha.resourceGroupDeployments on
```

Note: Alpha features are in experimental stages and may undergo changes.


### Authentication

Authenticate your session to interact with Azure resources:

```bash
azd auth login
```

### Setting Up Environment Variables

Define the necessary environment variables for your deployment:

1. Initialize the environment and set the Azure Client ID:

```bash
azd init -e dev
```

2. Set Azure Client ID:

Replace <your_ad_application_name> with your actual Azure AD Application Name.

```bash
APP_NAME=<your_ad_application_name>
azd env set AZURE_CLIENT_ID $(az ad app list --display-name $APP_NAME --query "[].appId" -otsv)
```

### Optional Feature Flags

Customize your OSDU deployment by enabling these optional features based on your specific requirements:


#### Feature: Pod Subnet

__Purpose:__ Enhances network configuration for Kubernetes Pods.

__Details:__ Typically, with kubenet in Kubernetes, nodes are assigned IP addresses from the Azure virtual network subnet. Enabling the Pod Subnet feature allows Pods to receive IP addresses from a different address space, separate from the subnet of the nodes. This separation alters the network flows.

__How To Enable:__

```bash
azd env set ENABLE_POD_SUBNET true
```


#### Feature: Bastion

__Purpose:__ Facilitates secure access to internal network resources.

__Details:__ Internal ingress configurations can sometimes make it challenging to access network resources. The Bastion feature addresses this by creating a bastion host and a virtual machine. These components act as a secure gateway, allowing you to communicate with and manage resources within the private network, even if they're not exposed to the public internet.

__How To Enable:__

```bash
azd env set ENABLE_BASTION true
```


#### Feature: VPN Gateway

__Purpose:__ Establishes secure VPN connections for remote access.

__Details:__ The VPN Gateway feature is essential for projects that require secure remote network access. It facilitates the creation of site-to-site and point-to-site VPN connections, enabling secure and flexible development environments, especially when dealing with internal ingress. This feature is crucial for maintaining robust network security and facilitating seamless remote access.

__Additional Configuration Values:__

- REMOTE_NETWORK_PREFIX: The CIDR notation for the remote network (e.g., '192.168.1.0/24').
- REMOTE_VPN_ADDRESS: The IP address of the Remote VPN Gateway.
- VPN_SHARED_KEY: The shared key for establishing the VPN connection.

__How To Enable:__

```bash
azd env set ENABLE_VPN_GATEWAY true
azd env set REMOTE_NETWORK_PREFIX <your_network_prefix>
azd env set REMOTE_VPN_ADDRESS <your_vpn_ip>
azd env set _VPN_SHARED_KEY <your_shared_key>
```


### Deployment Commands

Efficiently manage your OSDU solution with these Azure Developer CLI commands. They are designed to streamline the deployment process, allowing for a smooth setup and teardown of your environment.

__Starting the Deployment__

To initiate the deployment of the OSDU solution, use the following command:

```bash
azd provision
```

This command starts the provisioning process, setting up all necessary resources in Azure according to your configuration.

__Removal and Cleaning up__

When you need to remove your deployment and clean up resources, use this command:

```bash
azd down --purge --force
```

This command will stop all running services and remove resources that were created during the deployment. The --purge flag ensures that any keyvaults are completely removed, and the --force option bypasses any confirmation prompts, making the process faster.


## Infrastructure

The architecture diagram below provides a visual representation of the OSDU solution's infrastructure when deployed. It's designed to help you understand the various components and how they interact within the Azure environment.

![[0]][0]


### Key Components Illustrated in the Diagram:

1. Azure Virtual Network: Illustrates the network and how feature enablement changes the network structure and subnets.
2. Azure Kubernetes Service (AKS): Demonstrates the Kubernetes clusters and an example of how software is set up along with interactions to other Azure services.
3. Storage Resources: Illustrates the use of services such as Azure Storage Accounts and Azure Cosmos Databases and how they connect to the network.
4. Optional Features: If enabled, features like the VPN Gateway, Bastion Host, and Pod Subnet are represented, attempting to show their placement and role within the architecture.


## Software Management with a Gitops Approach

In the OSDU solution, we utilize a GitOps approach for efficient and reliable software management. This method leverages this Git repository as the source of truth for defining and updating the software configurations and deployments within the infrastructure.

### Understanding GitOps

GitOps is a modern approach to automate software deployment and infrastructure updates. It uses Git as a single source of truth for declarative infrastructure and applications. By applying GitOps, changes are made through pull requests, ensuring a transparent, reviewable, and auditable process.

### GitOps Configuration

Our GitOps configuration resides in this Git repository and uses a customized [repo-per-team](https://fluxcd.io/flux/guides/repository-structure/#repo-per-team) structure. This repository includes:

- __Configuration Files__: YAML files defining the desired state of our components and applications.

- __Charts__: Helm charts used for defining, installing, and upgrading Kubernetes applications.

### Advantages of GitOps

- __Consistency and Standardization__: Ensures consistent configurations across different environments.
- __Audit Trails__: Every change is recorded in Git, providing a clear audit trail.
- __Rollbacks and Recovery__: Every change is recorded in Git, providing a clear audit trail.
- __Enhanced Security__: Changes are reviewed through pull requests, increasing security and collaboration.

Our GitOps approach simplifies the process of deploying and managing software, making it easier to maintain and update the OSDU solution, as well as providing a configurable way of leveraging other software configurations by pointing to alternate repositories hosting other configurations. By leveraging this method, we ensure that our deployments can be extended to things that not only include the default software load. 

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
