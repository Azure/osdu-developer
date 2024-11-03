# Getting Started

Prerequisites and configuration steps for deploying personal OSDU™ instances in an Azure Subscription.

## Subscription Quota

It is recommended to have at least 50 vCPUs in a region for vCPU families along with the ability to deploy Cosmos DB instances which can be resource constrained in some regions.  Defaults can be increased by requesting a [quota increase](https://learn.microsoft.com/en-us/azure/quotas/regional-quota-requests).

!!! note "Ensure Sufficient Quota"
    The deployment requires quota for the following VM families:

    - Standard_D4pds_v5 nodes for system workloads
    - Standard_D2pds_v5 nodes for zonal workloads  
    - Standard_D4s_v5 nodes for default workloads


| Quota Name | Minimum Quantity |
|------------|------------------|
| Total Regional vCPUs | 100 |
| Standard DPDSv5 Family vCPUs | 50 |
| Standard DSv5 Family vCPUs | 50 |


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

## Preview Features

To use AKS Automatic in preview, you must register several feature flags. Register the following features using the [az feature register](https://learn.microsoft.com/en-us/cli/azure/feature?view=azure-cli-latest#az-feature-register) command.

=== "Command"
    ```bash
    az feature register --namespace Microsoft.ContainerService --name EnableAPIServerVnetIntegrationPreview
    az feature register --namespace Microsoft.ContainerService --name NRGLockdownPreview
    az feature register --namespace Microsoft.ContainerService --name SafeguardsPreview
    az feature register --namespace Microsoft.ContainerService --name NodeAutoProvisioningPreview
    az feature register --namespace Microsoft.ContainerService --name DisableSSHPreview
    az feature register --namespace Microsoft.ContainerService --name AutomaticSKUPreview
    ```

After the features are registered, refresh the registration of the Microsoft.ContainerService resource provider:

=== "Command"
    ```bash
    az provider register --namespace Microsoft.ContainerService
    ```

!!! tip "Verify Registration Status"
    Check the registration status using the following command. It may take a few minutes for the status to show *Registered*:

    === "Command"
        ```bash
        az feature show --namespace Microsoft.ContainerService --name AutomaticSKUPreview
        ```


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


