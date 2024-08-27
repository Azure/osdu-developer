# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  [![Infra - Test](https://github.com/Azure/osdu-developer/actions/workflows/test.yml/badge.svg)](https://github.com/Azure/osdu-developer/actions/workflows/test.yml) ![GitHub milestone details](https://img.shields.io/github/milestones/progress/azure/osdu-developer/1)


<!-- ![Github Issues](https://img.shields.io/github/issues/azure/osdu-developer)
![Github Pull Requests](https://img.shields.io/github/issues-pr/azure/osdu-developer) -->


OSDU Developer enables the deployment of personal instances of the [OSDU™](https://community.opengroup.org/osdu/platform) data platform. 

> For a fully managed implementation use [Azure Data Manager for Energy](https://azure.microsoft.com/en-us/products/data-manager-for-energy).


For detailed instructions, view our online [Documentation](https://azure.github.io/osdu-developer/) and see what the team is currently working by looking through the [Roadmap](https://github.com/orgs/Azure/projects/696/views/2).

## OSDU Services

Supported services running [Milestone 24](https://community.opengroup.org/groups/osdu/platform/-/milestones/26#tab-issues)

| **Service**                                                                                     | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Partition Service](https://community.opengroup.org/osdu/platform/system/partition)             | Manages data partitions to ensure efficient data management and scalability.                    |
| [Entitlement Service](https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements) | Provides access control and permissions management for data within the OSDU platform. |
| [Legal Service](https://community.opengroup.org/osdu/platform/security-and-compliance/legal)   | Ensures that data compliance and legal requirements are met, including data privacy and governance. |
| [Indexer Service](https://community.opengroup.org/osdu/platform/system/indexer-service)        | Indexes and categorizes data to enable efficient search and retrieval.                           |
| [Indexer Queue](https://community.opengroup.org/osdu/platform/system/indexer-queue)            | Manages the queue for processing indexing tasks, ensuring data is indexed in a timely manner.    |
| [Schema Service](https://community.opengroup.org/osdu/platform/system/schema-service)          | Manages and provides access to data schemas that define the structure and format of data.        |
| [Storage Service](https://community.opengroup.org/osdu/platform/system/storage)                | Provides scalable storage solutions for managing and retrieving large volumes of data.           |
| [Search Service](https://community.opengroup.org/osdu/platform/system/search-service)          | Facilitates searching and querying across data stored within the OSDU platform.                  |
| [File Service](https://community.opengroup.org/osdu/platform/system/file)                      | Handles file operations such as storage, retrieval, and management of data files.                |
| [Unit Service](https://community.opengroup.org/osdu/platform/system/reference/unit-service)    | Provides dimension/measurement and unit definitions.                                             |
| [CRS Catalog Service](https://community.opengroup.org/osdu/platform/system/reference/crs-catalog-service) | Provides API endpoints to work with geodetic reference data, allowing developers to retrieve CRS definitions, select appropriate CRSs for data ingestion, and search for CRSs based on various constraints. |
| [CRS Conversion Service](https://community.opengroup.org/osdu/platform/system/reference/crs-conversion-service)  | Enables the conversion of coordinates from one coordinate reference system (CRS) to another. |

## Getting Started

> **IMPORTANT:** In order to deploy and run this example, you'll need an **Azure subscription** with [these namespaces](https://azure.github.io/osdu-developer/before_you_start/) registered. 

> **AZURE RESOURCE COSTS:** This solution will create an Azure Kubernetes Cluster that has a monthly cost and consumes a minimum of 44 vCPUs, as well as creation of other Azure Resources such as Storage Accounts, Cosmos Databases and Redis Cache.

Follow this [tutorial](https://azure.github.io/osdu-developer/tutorial_cli/) for a quick overview from the Azure Cloud Shell.

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

