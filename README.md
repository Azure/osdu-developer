# OSDU Developer Sandbox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  

The developer sandbox solution enables software development for the [OSDU™](https://community.opengroup.org/osdu/platform) data platform. 
> For a fully managed implementation use [Azure Data Manager for Energy](https://azure.microsoft.com/en-us/products/data-manager-for-energy).


## OSDU Services

Supported services running [Milestone 24](https://community.opengroup.org/groups/osdu/platform/-/milestones/26#tab-issues)

| **Service**                                                                                     | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Partition Service](https://community.opengroup.org/osdu/platform/system/partition)             | Manages data partitions to ensure efficient data management and scalability.                   |
| [Entitlement Service](https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements) | Provides access control and permissions management for data within the OSDU platform.         |
| [Legal Service](https://community.opengroup.org/osdu/platform/security-and-compliance/legal)   | Ensures that data compliance and legal requirements are met, including data privacy and governance. |
| [Indexer Service](https://community.opengroup.org/osdu/platform/system/indexer-service)        | Indexes and categorizes data to enable efficient search and retrieval.                        |
| [Indexer Queue](https://community.opengroup.org/osdu/platform/system/indexer-queue)            | Manages the queue for processing indexing tasks, ensuring data is indexed in a timely manner. |
| [Schema Service](https://community.opengroup.org/osdu/platform/system/schema-service)          | Manages and provides access to data schemas that define the structure and format of data.     |
| [Storage Service](https://community.opengroup.org/osdu/platform/system/storage)                | Provides scalable storage solutions for managing and retrieving large volumes of data.       |
| [Search Service](https://community.opengroup.org/osdu/platform/system/search-service)          | Facilitates searching and querying across data stored within the OSDU platform.               |
| [File Service](https://community.opengroup.org/osdu/platform/system/file)                      | Handles file operations such as storage, retrieval, and management of data files.             |




## Features

| **Feature**            | **Description**                                                                                                    |
|------------------------|--------------------------------------------------------------------------------------------------------------------|
| Data Partitions        | Supports a single data partition for managing and organizing data within the platform, named "opendes."            |
| Schema Loading         | Automatically loads Well Known Schemas for efficient data management and validation.                               |
| Software Locations     | Utilizes Flux to direct the software loading process to private GitHub repositories and branches.                  |
| Ingress                | Supports both public-facing and private network access points.                                                     |
| Network Flexability    | Supports VNet injection and integration with existing networks, to easily allow for S2S Vpn access.                |
| Mesh Observability     | Provides observability for istio using Kiali dashboards to investigate latency, traffic, errors, and saturation.   |
| Elastic Tools          | Supports connectivity to Elastic Kibana for advanced devtools, search capabilities, and user management.           |
| Application Logging    | Integrated with Application Insights for detailed service-level logging and metrics monitoring.                    |
| Initial User           | Includes initial user setup and configuration for openid connect access.                                           |
| Rest Scripts           | Integrated Sample Rest Scripts for easily executing API calls to test and explore functionality.                   |
| Token Tools            | Integrated Access Token Tools for easy retrieval of Bearer Access Tokens for with Swagger Pages and docs.          |




## Getting Started

> **IMPORTANT:** In order to deploy and run this example, you'll need an **Azure subscription**. 

> **AZURE RESOURCE COSTS:** This solution will create an Azure Kubernetes Cluster that has a monthly cost and consumes a minimum of 44 vCPUs, as well as creation of other Azure Resources such as Storage Accounts, Cosmos Databases and Redis Cache.


### Prerequisites

#### To Run in GitHub Codespaces or VS Code Remote Containers

This solution can be run virtually by using GitHub Codespaces or VS Code Remote Containers _(Docker required)_.  Click on one of the buttons below to open this repo in one of those options. 

[![Open in Remote - Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Azure/osdu-developer)
[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://github.com/codespaces/new?skip_quickstart=true&machine=basicLinux32gb&repo=742135816&ref=main&devcontainer_path=.devcontainer%2Fdevcontainer.json&geo=UsEast)

#### To Run Locally

- __Visual Studio Code__: Install and configure with [REST Client Extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) on your local machine. [Download](https://code.visualstudio.com/download)

- __PowerShell Core__: Installed on your local machine.  [Download](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4)

- __Azure CLI__: Installed on your local machine. [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

- __Azure Developer CLI__: Installed on your local machine. [Download](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)


### Installation

#### Project Setup

1. Run `azd config set alpha.resourceGroupDeployments on` to enable Resource Group Scoped Deployments.

1. Run `azd auth login` to login with your azure credentials.

1. Run `azd init -e dev` to initialize a new environment.

1. Run `az login --scope https://graph.microsoft.com//.default` to create or access Application information in Azure Active Directory.

1. Run `azd provision` - This will provision Azure resources and deploy this solution including installing software to the cluster and configuring the Application Identity.

1. After the application has been successfully deployed a browser should open to obtain a new [OAuth2 Authorization Code](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow#applications-that-support-the-auth-code-flow).

1. Run `azd env set AUTH_CODE {Single Use Authorization Code}`

1. Run `azd hooks run settings` to obtain OpenID refresh tokens and configure settings for Visual Studio Code.

> NOTE: It may take over an hour for the application to be fully deployed. If you see an "Azure Login" page please reauthenticate the Azure CLI, and continue to wait.

#### Optional Overrides

1. Run `azd env set AZURE_CLIENT_ID {Name of existing Application Id}` to not create a new Application.
1. Run `azd env set SOFTWARE_REPOSITORY {URL of GitHub Repository}` to isolate software installation to an alternate respository.
1. Run `azd env set SOFTWARE_BRANCH {Name of GitHub Branch}` to isolate software installation to an alternate branch.

#### Resource Removal

1. Run `azd down --force --purge` to remove all Azure Resources.

> NOTE: Manual removal of the resource group is also fine but requires manual purge of the KeyVault and App Configuration.


### ARM Template Deployment  (Alternative)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)

Deploying the resources is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, navigating parameter options can be challenging.

**Important Parameter Requirement:**

During the deployment process, some information is required to be provided in the deployment form:

- `Email Address`: Specify a valid email address to be used as the first user.
- `Application Client Id`: Specify the Application Client Id. (This is the unique application ID of this application.)
- `Application Client Secret`: Specify the Application Client Secret. (A valid secret for the application client ID.)
- `Application Client Principal OID`: Specify the Enterprise Application Object Id. (This is the unique ID of the service principal object associated with the application.)

Upon completing the deployment, the infrastructure and software components will be automatically provisioned. 


## Additional Information

#### Architecture

For further understanding of the interactions of the Azure Developer CLI and the architecture of the solution, please refer to the Architecture Documentation which can be found [here](docs/architecture.md).

#### IDE Settings

Services can be run locally in an IDE like IntelliJ.  Identified required environment variables to start the services can be found [here](docs/service-environments.md)


#### Feature Flags

Feature flags are leveraged to assist in major modifications to the solution, ensuring adherence to different policies and requirements. More information can be found [here](docs/feature-flags.md).
                          

#### GitHub Actions

The repository is configured with GitHub Actions to automate the validation of pull requests.. The strategy for actions can be found [here](docs/pipelines.md).


#### Customizations

There are many things that can be done to customize the deployment. One example of this might be virtual network injection. More information can be found [here](docs/vnet-injection.md).

