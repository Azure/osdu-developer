# OSDU Developer Sandbox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  

This is an [Azure Cloud](https://azure.microsoft.com/) developer sandbox to enable software development for the [OSDU™](https://community.opengroup.org/osdu/platform) data platform.  It is not recommended for any production scenario.  For a fully managed implementation please see [Azure Data Manager for Energy](https://azure.microsoft.com/en-us/products/data-manager-for-energy).


## Guiding Principles

The developer sandbox is built using the following principles from the [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/what-is-well-architected-framework).


1. **Cost Optimization** - Creating a cost-effective solution while balancing security.
2. **Security** - Enhancing security within a development context, adhering to a zero trust model.
3. **Operational Excellence** - Prioritizing DevOps standards with automation to ensure efficient operations and robust monitoring.


**Bicep: Desired State Configuration**

Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It simplifies authoring ARM templates and allows you to define the desired state of your Azure infrastructure in code. Azure Resource Manager (ARM) processes the Bicep file to ensure the Azure environment matches the defined desired state, correcting any drift through redeployment.

**GitOps: Desired State Management**

GitOps uses Git as a single source of truth for declarative components and applications. It ensures that the actual state of the components or application matches the desired state defined in the Git repository, automating updates through continuous monitoring and Git commits.


## Prerequisites

- __Azure Subscription__: An active Microsoft Azure subscription.

- __Azure RBAC Role__: Ensure the `App Configuration Data Owner` role has been assigned on the desired Azure Subscription as explained [here](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-deployment-overview?tabs=portal#manage-azure-app-configuration-data-in-deployment).

- __Azure CLI__: Install and configured on your local machine. You can download it [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

- __Azure Developer CLI__: Install and configured on your local machine. You can download it [here](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd).

    ```bash
    # Enable Resource Group Scoped Deployment
    azd config set alpha.resourceGroupDeployments on
    ```

- __Visual Studio Code__: Install and configure on your local machine with the [REST Client Extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client). You can download it [here](https://code.visualstudio.com/download)

- **Docker Desktop**: Install and configure on your local machine. You can download it [here](https://www.docker.com/products/docker-desktop).

- **Optional**: Either **PowerShell Core** or a **Bash shell in WSL**. You can download PowerShell Core [here](https://github.com/PowerShell/PowerShell) and set up WSL [here](https://docs.microsoft.com/en-us/windows/wsl/install).


## Setup

The recommended approach is to use the Azure Developer CLI, which allows for customization and additional configuration. You can use the ARM Template Deployment, but will require additional manual configuration for establishment of the first user and intial access tokens.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/azure/osdu-developer)

### AZD CLI Deployment (Recommended)

1. Authentication

    ```bash
    # Login and set subscription
    az login --scope https://graph.microsoft.com//.default
    az account set --subscription <your_subscription_id>
    azd auth login
    ```

2. Provisioning

    ```bash
    # Initialize a new environment
    azd init -e dev
    
    # Provision the solution
    azd provision
    ```

3. Configuration

    Once the environment has been provisioned, retrieve the ingress URL `https://<your_ingress>/auth/` and obtain an authorization code to use in getting a refresh token for calling APIs.

    ```bash
    # Open URL in browser (bash)
    azd env get-values |grep INGRESS_EXTERNAL

    # Open URL in browser (pwsh)
    azd env get-values | Where-Object { $_ -match "INGRESS_EXTERNAL" }
    
    # Set retrieved authorization code
    azd env set AUTH_CODE <your_auth_code>
    azd hooks run predeploy
    ```

4. Cleanup

    ```bash
    # Remove all resources
    azd down --purge --force
    
    # Delete the environment
    rm -rf .azure/<your_environment_name>
    ```


#### Optional Overrides

Environment settings can be overriden as necessary.

```bash
# Override Default Subscription
azd env set AZURE_SUBSCRIPTION_ID <your_subscription_id>

# Override Client Id Creation
azd env set AZURE_CLIENT_ID <your_client_id>

# Override Software Location
azd env set SOFTWARE_REPOSITORY <your_git_url>
azd env set SOFTWARE_BRANCH <your_branch>
```

### ARM Template Deployment  (Alternative)

Deploying the resources is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, navigating parameter options can be challenging.

To facilitate a smooth deployment experience, we provide a "Deploy to Azure" button. Clicking this button will redirect you to the Azure portal, where the ARM template is pre-loaded for your convenience.

The application expects an [OAuth 2.0 and OpenID Connect (OIDC)](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-implicit-grant-flow) capable Entra Application has been preconfigured with either a Web or SPA platform configuration with the required redirect URIs for the ingress.

**Important Parameter Requirement:**

During the deployment process, identity information is necessary and required to be provided in the deployment form:

- `Email Address`: Specify a valid email address to be used as the first user.

- `Application Client Id`: Specify the Application Client Id. (This is the unique application ID of this application.)
- `Application Client Secret`: Specify the Application Client Secret. (A valid secret for the application client ID.)
- `Application Client Principal OID`: Specify the Enterprise Application Object Id. (This is the unique ID of the service principal object associated with the application.)


Upon completing the deployment, the infrastructure and software components will be automatically provisioned. This includes loading the software configuration through a [GitOps](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gitops-aks/gitops-blueprint-aks) approach, enabled by AKS (Azure Kubernetes Service).

To begin, simply click the button below:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json)


## Additional Information

#### Architecture

For further understanding of the interactions of the Azure Developer CLI and the architecture of the solution, please refer to the Architecture Documentation which can be found [here](docs/archiecture.md).


#### Customizations

There are many ways to customize the deployment. For example, virtual network injection can be implemented. Details on how to perform such customizations can be found [here](docs/vnet-injection.md).


#### Feature Flags

Feature flags are leveraged to assist in major modifications to the solution, ensuring adherence to different policies and requirements. More information can be found [here](docs/feature-flags.md).
                          

#### Github Actions

The repository is configured with Github Actions to automate the validation of pull requests.. The strategy for actions can be found [here](docs/pipelines.md).


#### Customizations

There are many things that can be done to customize the deployment. One example of this might be virtual network injection. More information can be found [here](docs/vnet-injection.md).


## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.


