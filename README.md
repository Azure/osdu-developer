# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  ![GitHub milestone details](https://img.shields.io/github/milestones/progress/azure/osdu-developer/1)


<!-- ![Github Issues](https://img.shields.io/github/issues/azure/osdu-developer)
![Github Pull Requests](https://img.shields.io/github/issues-pr/azure/osdu-developer) -->


OSDU Developer enables the deployment of personal instances of the [OSDU™](https://community.opengroup.org/osdu/platform) data platform. 

For detailed instructions, view our online [Documentation](https://azure.github.io/osdu-developer/) and see what the team is currently working by looking through the [Roadmap](https://github.com/orgs/Azure/projects/696/views/2).

## OSDU Services

Supported services of OSDU are based on the release branch of OSDU as specified in the [OSDU Milestones](https://community.opengroup.org/osdu/platform/-/milestones). (ie: release/0.25 release/0.26, release/0.27, master etc.)

| **Core Services**                                                                               | **Description**                                                                                 |
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
| [Workflow Service](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-workflow/)  | Initiates business processes within the system. During the prototype phase, it facilitates CRUD operations on workflow metadata and triggers workflows in Apache Airflow. Additionally, the service manages process startup records, acting as a wrapper around Airflow functions.. |

| **Reference Helper Services**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Unit Service](https://community.opengroup.org/osdu/platform/system/reference/unit-service)    | Provides dimension/measurement and unit definitions.                                             |
| [CRS Catalog Service](https://community.opengroup.org/osdu/platform/system/reference/crs-catalog-service) | Provides API endpoints to work with geodetic reference data, allowing developers to retrieve CRS definitions, select appropriate CRSs for data ingestion, and search for CRSs based on various constraints. |
| [CRS Conversion Service](https://community.opengroup.org/osdu/platform/system/reference/crs-conversion-service)  | Enables the conversion of coordinates from one coordinate reference system (CRS) to another. |

| **Airflow DAGS**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Manifest Ingestion DAG](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags)    | Used for ingesting single or multiple metadata artifacts about datasets into OSDU.                                             |
| [CSV Parser DAG:](https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser)    | Helps in parsing CSV files into a format for ingestion and processing.                                             |

## Experimental Software

OSDU offers different experimental capabilities that are very new or community contributions. These services are not yet fully mature but are available for early adopters to test and provide feedback.  This solution supports the concepts of experimental software with opt in feature flags.

| **Experimental Services**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Admin UI](https://community.opengroup.org/osdu/ui/admin-ui-group/admin-ui-totalenergies/admin-ui-totalenergies)    | A community supported Angular Administration UI for OSDU.                                             |


## Getting Started

> **IMPORTANT:** In order to deploy and run this example, you'll need an **Azure subscription** with [these namespaces](https://azure.github.io/osdu-developer/getting_started/#resource-providers/) registered. 


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

### CLI Deployment  (Recommended)

Deploying the resources via CLI is the recommended approach. This method allows for customization of the deployment parameters to better suit your needs, and offers tighter integration with other capabilities in this repository.

Follow this [tutorial](https://azure.github.io/osdu-developer/tutorial_cli/) for a quick overview of doing this from the Azure Cloud Shell.

> **NOTE:** Clone the latest version of this repo on your computer and switch to the directory. Note that the deployment scripts are being updated continously, make sure you update to the latest version.

> **NOTE:** If you are using a pre-existing Entra ID App, you will need to set the feature flag `AZURE_CLIENT_ID` and `AZURE_CLIENT_SECRET` with the values from your app (See [Feature Flags](https://azure.github.io/osdu-developer/feature_flags/#custom-infrastructure) for more information on feature flags).

```bash
# Authentication
az login --scope https://graph.microsoft.com//.default
az account set --subscription <your_subscription_id>
azd auth login

# Prepare Environment
azd init -e dev # This if first environment
azd env new dev # This if adding a new environment
azd env set <feature_flag> <value> # Set any necessary feature flags

# Provisioning
azd provision

# Configure Settings for Integrations
azd env set AUTH_CODE <auth_code>
azd hooks run settings

# Cleanup
azd down --force --purge
```


### Portal Template Deployment  (Alternative)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)

Deploying the solution is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, navigating parameter options and modifications can be challenging.

Follow this [tutorial](https://azure.github.io/osdu-developer/tutorial_arm/) for a quick overview of an ARM template deployment.

**Important Parameter Requirement:**

During the deployment process, some information is required to be provided in the deployment form:

- `Email Address`: A valid email address to be used as a first user.
- `Application Client Id`: Specify the Application Client Id. (The unique application ID of this application.)
- `Application Client Secret`: Specify the Application Client Secret. (A valid secret for the application client ID.)
- `Application Client Principal OID`: Specify the Enterprise Application Object Id. (The unique ID of the service principal object associated with the application.)

 
## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

For details on contributing to this repository, see the [Contribution Guide](./CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
