# OSDU Developer Sandbox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  

The developer sandbox solution enables software development for the [OSDU™](https://community.opengroup.org/osdu/platform) data platform. 
> For a fully managed implementation use [Azure Data Manager for Energy](https://azure.microsoft.com/en-us/products/data-manager-for-energy).

Clone the repository to a local machine.

```bash
# Clone the repository
git clone https://github.com/Azure/osdu-developer.git

# Change to directory
cd osdu-developer
```

Alternatively, use a GitHub Codespace.

 [![GitHub Codespace](https://github.com/codespaces/badge.svg)](https://codespaces.new/azure/osdu-developer)

## Prerequisites

> The `App Configuration Data Owner` role __must__ be assigned to the user using this solution at the subscription level. For more information see [documentation](https://learn.microsoft.com/en-us/azure/azure-app-configuration/quickstart-deployment-overview?tabs=portal#azure-app-configuration-authorization).


- __Shell Requirements__: 
  - For Windows: PowerShell Core (pwsh).
  - For Linux or Mac: A POSIX-compliant shell (bash/zsh).

- __Visual Studio Code__: Install and configure on your local machine with the [REST Client Extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client). You can download it [here](https://code.visualstudio.com/download).

- __Azure CLI__: Installed on your local machine. You can download it [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

- __Azure Developer CLI__: Installed on your local machine. You can download it [here](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd).

    ```bash
    # Enable Alpha Feature Resource Group Scoped Deployments
    azd config set alpha.resourceGroupDeployments on

    # Enable Azure CLI Token Authentication
    azd config set auth.useAzCliAuth "true"
    ```


## Setup

1. Configure

    ```bash
    # Enable Alpha Feature Resource Group Scoped Deployments
    azd config set alpha.resourceGroupDeployments on

    # Enable Azure CLI Token Authentication
    azd config set auth.useAzCliAuth "true"
    ```

2. Authenticate

    ```bash
    # Login and set subscription
    az login --scope https://graph.microsoft.com//.default
    ```

3. Provision

    ```bash    
    # Create Environment and provision the solution
    azd init -e dev # Environment name as desired.
    
    # (Optional) Override Default Subscription
    azd env set AZURE_SUBSCRIPTION_ID <your_subscription_id>

    # (Optional) Override Default Location
    azd env set AZURE_LOCATION <azure_region>

    # (Optional) Override Default Application
    azd env set AZURE_CLIENT_ID <your_client_id>

    # (Optional) Override Software Location
    azd env set SOFTWARE_REPOSITORY <your_git_url>
    azd env set SOFTWARE_BRANCH <your_branch>

    # Provision the solution
    azd provision
    ```

4. Integrate

    Once the environment has been provisioned, access the ingress URL `https://<your_ingress>/auth/` and obtain an authorization code for use in getting a refresh token for calling APIs.

    ```bash    
    # Set retrieved authorization code
    azd env set AUTH_CODE <your_auth_code>
    azd hooks run token
    ```

5. Cleanup

    ```bash
    # Remove all resources
    azd down --purge --force
    ```

### ARM Template Deployment  (Alternative)

Deploying the resources is efficient and straightforward using an ARM (Azure Resource Manager) template. While this method utilizes default settings for ease of use, navigating parameter options can be challenging if using customizations.

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


#### Feature Flags

Feature flags are leveraged to assist in major modifications to the solution, ensuring adherence to different policies and requirements. More information can be found [here](docs/feature-flags.md).
                          

#### Github Actions

The repository is configured with Github Actions to automate the validation of pull requests.. The strategy for actions can be found [here](docs/pipelines.md).


#### Customizations

There are many things that can be done to customize the deployment. One example of this might be virtual network injection. More information can be found [here](docs/vnet-injection.md).


