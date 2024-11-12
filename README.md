# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  ![GitHub milestone details](https://img.shields.io/github/milestones/progress/azure/osdu-developer/1) 


<!-- ![Github Issues](https://img.shields.io/github/issues/azure/osdu-developer)
![Github Pull Requests](https://img.shields.io/github/issues-pr/azure/osdu-developer) -->


[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://github.com/codespaces/new?skip_quickstart=true&machine=basicLinux32gb&repo=742135816&ref=main&devcontainer_path=.devcontainer%2Fdevcontainer.json&geo=UsEast)
[![Open in Remote - Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Azure/osdu-developer)

This project provides simplified personal deployments of the [OSDU™](https://community.opengroup.org/osdu/platform) data platform on Microsoft Azure.


- [Documentation](https://azure.github.io/osdu-developer/): Detailed concepts and architecture.
- [Services](https://azure.github.io/osdu-developer/services_source/): Current list of supported OSDU capabilities.
- [Tutorials](https://azure.github.io/osdu-developer/tutorial_cli/): Step-by-step guides for getting started
- [Roadmap](https://github.com/orgs/Azure/projects/696/views/2): Ongoing and future development plans


### Getting Started

This project uses the following Azure Container Service preview features:

- [API Server VNet Integration](https://learn.microsoft.com/en-us/azure/aks/api-server-vnet-integration)
- [Node Resource Group Lockdown](https://learn.microsoft.com/en-us/azure/aks/node-resource-group-lockdown)
- [AKS Safeguards](https://learn.microsoft.com/en-us/azure/aks/deployment-safeguards)
- [Node Auto Provisioning](https://learn.microsoft.com/en-us/azure/aks/node-autoprovision?tabs=azure-cli)
- [SSH Disable](https://learn.microsoft.com/en-us/azure/aks/manage-ssh-node-access?tabs=node-shell#disable-ssh-overview)

Review the [documentation](https://azure.github.io/osdu-developer/getting_started/) prior to proceeding.

### CLI Quickstart

> **Tutorial:** [Deploy OSDU Personal Instance via CLI](https://azure.github.io/osdu-developer/tutorial_cli/)

Clone the repository and run the following commands to deploy.

```bash
# Authenticate
az login --scope https://graph.microsoft.com//.default
az account set --subscription <your_subscription_id>
azd auth login

# Prepare
azd init -e dev 
azd env set <feature_flag> <value>

# Provisioning
azd provision

# Configure
azd env set AUTH_CODE <auth_code>
azd hooks run settings

# Cleanup
azd down --force --purge
```

### Portal Quickstart

> **Tutorial:** [Deploy OSDU Personal Instance via Portal](https://azure.github.io/osdu-developer/tutorial_arm/)

Deploy using the Azure Portal.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)

## Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

For details on contributing to this repository, see the [Contribution Guide](./CONTRIBUTING.md).

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
