# Getting Started

Prerequisites and configuration steps for deploying personal OSDU™ instances in an Azure Subscription.


## Software Tools

!!! tip "Install Required Software"
    Install the following software locally.

| Software | Description | Download Link |
|----------|-------------|---------------|
| Visual Studio Code | Code editor with REST Client Extension | [Download](https://code.visualstudio.com/download) |
| PowerShell Core | Cross-platform task automation solution | [Download](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4) |
| Azure CLI | Command-line tool for managing Azure resources | [Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Azure Developer CLI | Command-line tool for Azure development | [Download](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) |

!!! note "Visual Studio Code Extension"
    After installing Visual Studio Code, make sure to install the [REST Client Extension](https://marketplace.visualstudio.com/items?itemName=humao.rest-client).


## Subscription Quota

It is recommended to have at least 50 vCPUs in a region along with the ability to deploy Cosmos DB instances which can be resource constrained in some regions.  Defaults for MSDN accounts can be increased by requesting a [quota increase](https://learn.microsoft.com/en-us/azure/quotas/regional-quota-requests).

!!! note "Ensure Sufficient Quota"
    The choice between BS and DS family vCPUs depends on your specific deployment requirements:

    - Increase DS family vCPU quota if necessary.
    - Increase BS family vCPU quota if using `ENABLE_BATCH`.

| Quota Name | Minimum Quantity |
|------------|------------------|
| Total Regional vCPUs | 100 |
| Standard BS Family vCPUs | 50 |
| Standard DS Family vCPUs | 50 |


!!! tip "Available Cosmos DB Regions"
    Use the following command to determine the availability of Cosmos DB regions:

    === "Bash"
        ```bash
        az provider show --namespace Microsoft.DocumentDB \
          --query "resourceTypes[?resourceType=='databaseAccounts'].locations" \
          --output json
        ```

    === "PowerShell"
        ```powershell
        az provider show --namespace Microsoft.DocumentDB `
          --query "resourceTypes[?resourceType=='databaseAccounts'].locations" `
          --output json
        ```


## Estimating Costs

Costs will vary widely based on the selected region, instance size, and usage. The following table provides a rough guideline for an idle instance.

!!! note "Costs Will Vary"
    Idle instance with no activity consumes approximately __$40.00__ per day.

| Resource | Daily | Resource | Daily |
|----------|--------------|----------|--------------|
| Virtual Machines | $14.59 | Load Balancer | $0.60 |
| Log Analytics | $9.76 | Redis Cache | $0.49 |
| Storage | $2.75 | Key Vault | $0.09 |
| Azure Cosmos DB | $2.46 | Virtual Network | $0.08 |
| Microsoft Defender for Cloud | $1.82 | Container Registry | $0.06 |
| Container Instances | $0.03 | Bandwidth | $0.004 |
| Service Bus | $0.001 | | |



## Resource Providers

The following Azure Resource Providers must be registered in your subscription.

!!! tip "Register Resource Providers"
    For instructions to register providers refer to the [Azure Resource Providers and Types documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

| Resource Provider                 | Description                                                                 |
|-----------------------------------|-----------------------------------------------------------------------------|
| Microsoft.AlertsManagement        | Manages alerts and notifications for Azure resources                        |
| Microsoft.AppConfiguration        | Manages application settings and feature flags                              |
| Microsoft.Authorization           | Manages access control and permissions for Azure resources                  |
| Microsoft.Cache                   | Manages Azure Cache for Redis instances                                     |
| Microsoft.CloudShell              | Provides an interactive command-line shell experience in the Azure portal   |
| Microsoft.Compute                 | Manages virtual machines, virtual machine scale sets, and related resources |
| Microsoft.ContainerRegistry       | Manages container registries for storing and managing container images      |
| Microsoft.ContainerService        | Manages Kubernetes clusters and related resources                           |
| Microsoft.Dashboard               | Creates and manages dashboards for visualizing Azure resources              |
| Microsoft.DocumentDB              | Manages Azure Cosmos DB databases and collections                           |
| Microsoft.Insights                | Provides monitoring and diagnostics for Azure resources                     |
| Microsoft.KeyVault                | Safeguards and manages cryptographic keys and secrets                       |
| Microsoft.KubernetesConfiguration | Manages Azure Kubernetes Service (AKS) clusters and related resources       |
| Microsoft.ManagedIdentity         | Provides an identity for Azure resources without the need for credentials   |
| Microsoft.Monitor                 | Provides monitoring and alerting capabilities for Azure resources           |
| Microsoft.Network                 | Manages virtual networks, network security groups, and related resources    |
| Microsoft.OperationalInsights     | Provides log analytics and monitoring for Azure resources                   |
| Microsoft.OperationsManagement    | Manages and monitors the health and performance of Azure resources          |
| Microsoft.Resources               | Manages Azure Resource Manager resources and resource groups                |
| Microsoft.ServiceBus              | Provides reliable messaging and publish/subscribe capabilities              |
| Microsoft.Storage                 | Manages Azure Storage accounts and resources                                |

## Required Role Assignments

To deploy and manage an OSDU™ personal instance, you need the following Azure role assignments:

!!! tip "Assigning Roles"
    For instructions on assigning roles, refer to the [Azure Role Assignments documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-steps).

| Role                                    | Purpose                                                                                   |
|-----------------------------------------|-------------------------------------------------------------------------------------------|
| Contributor                             | Manage all resources in the subscription, except for assigning roles or managing policies |
| Role Based Access Control Administrator | Manage access to Azure resources by assigning roles using Azure RBAC                      |
| Resource Policy Contributor             | Create and manage resource policies                                                       |

## Microsoft Entra App Registration

Register an application in Microsoft Entra ID.  This is required for OSDU™ personal instance integration with Microsoft Entra ID and delegate access with identity management.

These credentials will be used in your ARM template deployment to authenticate and authorize the deployment process.

!!! important
    Only required when using custom ARM template deployments or using CLI feature setting overrides.

!!! tip "Registering Applications"
    For instructions on registering applications, refer to the [Quickstart documentation](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app?tabs=certificate).


| Name | Description/Value |
|------|-------------|  
| Directory (tenant) ID | Unique identifier for the Microsoft Entra tenant |
| Application (client) ID | Unique identifier for the registered application |
| Object ID | Unique identifier for the application object in Microsoft Entra |
| Application (client) Secret | Confidential key used to authenticate the application |
| Single-page application redirect URI | http://localhost:8080 |

!!! warning "Secure Your Secret"
    The client secret is sensitive information. Make sure to store it securely and never commit it to version control systems.


