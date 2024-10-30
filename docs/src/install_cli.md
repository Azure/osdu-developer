# Command Line (AZD)

??? info "_Article Audience_"
    :fontawesome-solid-cloud:{ .lg .middle } __Cloud Architects__: Working with Infrastructure and Software

    :fontawesome-solid-code:{ .lg .middle } __Application Developer__: Working with Services and Applications

    :fontawesome-brands-git-alt:{ .lg .middle } __DevOps Engineers__: Automation and Deployment Customizations

The Azure Developer CLI (azd) simplifies deployment and management of Azure resources through intuitive commands and built-in best practices. The CLI enables rapid provisioning combined with management tasks via hook-executed scripts. Built-in environment management capabilities support isolated environments with automatic environment variable configuration.

??? Tip "Learning Opportunity"
    Learn more about the [Azure Developer CLI (azd)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview?tabs=linux) and how to use it.

_Supports [Containers](https://code.visualstudio.com/docs/devcontainers/containers) as an alternative for local workstation._

[![Open in GitHub Codespaces](https://img.shields.io/static/v1?style=for-the-badge&label=GitHub+Codespaces&message=Open&color=brightgreen&logo=github)](https://github.com/codespaces/new?skip_quickstart=true&machine=basicLinux32gb&repo=742135816&ref=main&devcontainer_path=.devcontainer%2Fdevcontainer.json&geo=UsEast)

[![Open in Remote - Containers](https://img.shields.io/static/v1?style=for-the-badge&label=Remote%20-%20Containers&message=Open&color=blue&logo=visualstudiocode)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/Azure/osdu-developer)



## Instructions

1. Clone the repository to your file system.

    === "Command"

        ```powershell
        git clone https://github.com/Azure/osdu-developer.git
        ```

2. Authenticate and select the subscription.

    === "Command"

        ```powershell
        az login --scope https://graph.microsoft.com//.default
        azd auth login
        az account set --subscription <your_subscription_id>
        ```

3. Enable required features.

    === "Command"
    
        ```powershell
        azd config set alpha.resourceGroupDeployments on
        ```


4. Initialize the environment and enable any feature flags.

    === "Command"
    
        ```powershell
        azd init -e <your_env_name>
        azd env set <feature_flag> <value>
        ```

5. Deploy the solution.

    === "Command"
    
        ```powershell
        azd provision
        ```

    !!! Warning
        Deployment can exceed 1 hour. For timeouts execute `azd provision` again to continue.

