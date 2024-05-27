# OSDU Developer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The [OSDU™](https://community.opengroup.org/osdu/platform) data platform is a standard for subsurface and well data, enabling efficient data access and analysis across the energy industry. This project is a solution that aims to enable development and work with OSDU on the [Microsoft Azure Cloud](https://azure.microsoft.com/).


## Guiding Principles

This development approach focuses on the following principles from the Microsoft [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework). It is intended for development purposes and is not recommended for production scenarios, nor does it come with any official support.


1. **Cost Optimization** -- Creating a cost-effective solution while balancing security.
2. **Security** -- Enhancing security within a development context, adhering to a zero trust model.
3. **Operational Excellence** -- Prioritizing DevOps, standards, and automation to ensure efficient operations and robust monitoring.


**Bicep for Desired State Configuration**

Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It simplifies authoring ARM templates and allows you to define the desired state of your Azure infrastructure in code. Azure Resource Manager (ARM) processes the Bicep file to ensure the Azure environment matches the defined desired state, correcting any drift through redeployment.

**GitOps for Desired State Management**

GitOps uses Git as a single source of truth for declarative components and applications. It ensures that the actual state of the components or application matches the desired state defined in the Git repository, automating updates through continuous monitoring and Git commits.

**Combination of Bicep and GitOps**

Combining Bicep and GitOps provides a unified strategy for defining both infrastructure and software, enabling automated alignment and deployment through a single source of truth.

Integration with [GitHub Codespaces](https://github.com/features/codespaces) and the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/) simplifies development and innovation.


## Prerequisites

Before starting, ensure you have the following prerequisites:

__Azure Subscription__: An active Microsoft Azure subscription.

__Azure CLI__: Installed and configured on your local machine. You can download it [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

__Azure Developer CLI__: Installed on your local machine. Installation instructions are available [here](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd).

> Resource Group Scoped Deployments should be enabled  
    ```
    azd config set alpha.resourceGroupDeployments on
    ```

Optional but recommended:

__Visual Studio Code__: Installed with the [REST Client Extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) for an enhanced development experience.


## Installation

The recommended approach is to clone the repository and use the Azure Developer CLI, which allows for customization and additional configuration. Alternatively, you can use the ARM Template Deploy to Azure button for a straightforward deployment, but would require manual configuration for establishing the first user and intial tokens.


### Recommended: Azure Developer CLI

1. Clone the repository:

```bash
git clone https://github.com/azure/osdu-developer.git
cd osdu-developer
``` 

2. Authenticate your session:

```bash
az login
az account set --subscription <your_subscription_id>
azd auth login
```

3. Initialize an environment and provision:

```bash
# Initialize and Create a new Environment
azd init -e dev

# Provision the solution
azd provision
```

4. Post Provisioning Configuration:

Once the environment has been provisioned, retrieve the ingress URL `https://<your_ingress>/auth/` and obtain an authorization code to use in getting a refresh token for calling APIs.

```bash
# Open URL in Browser
azd env get-values |grep INGRESS_EXTERNAL

# Set Retrieved Authorization Code
azd env set AUTH_CODE <your_auth_code>
azd hooks run predeploy
```


#### Environment Overrides

Environment Variables can be optionally overriden

```bash
# Override Default Subscription
azd env set AZURE_SUBSCRIPTION_ID <your_subscription_id>

# Override Client Id Creation
azd env set AZURE_CLIENT_ID <your_client_id>

# Override Software Location
azd env set SOFTWARE_REPOSITORY <your_git_url>
azd env set SOFTWARE_BRANCH <your_branch>
```

### Alternative: ARM Template Deployment

Deploying the resources is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, navigating parameter options can be challenging.

To facilitate a smooth deployment experience, we provide a "Deploy to Azure" button. Clicking this button will redirect you to the Azure portal, where the ARM template is pre-loaded for your convenience.

**Important Parameter Requirement:**

During the deployment process, there's one essential parameter you need to provide:

`applicationClientId`: Fill this with the Application ClientId that you intend to use. This step is crucial for the proper functioning of the template.

Upon completing the deployment, the infrastructure and software components will be automatically provisioned. This includes loading the software configuration through a [GitOps](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gitops-aks/gitops-blueprint-aks) approach, enabled by AKS (Azure Kubernetes Service).

To begin, simply click the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)


# Additional Information

## Architecture

For further understanding of the interactions of the Azure Developer CLI and the architecture of the solution, please refer to the Architecture Documentation which can be found [here](docs/archiecture.md).


## Customizations

There are many ways to customize the deployment. For example, virtual network injection can be implemented. Details on how to perform such customizations can be found [here](docs/vnet-injection.md).


## Feature Flags

Feature flags are leveraged to assist in major modifications to the solution, ensuring adherence to different policies and requirements. More information can be found [here](docs/feature-flags.md).
                          

## Github Actions

The repository is configured with Github Actions to automate the validation of pull requests.. The strategy for actions can be found [here](docs/pipelines.md).




## Customizations

There are many things that can be done to customize the deployment. One example of this might be virtual network injection.

See [this tutorial](docs/vnet-injection.md) for how a customization like this might be performed.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.


