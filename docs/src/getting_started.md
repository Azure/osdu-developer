# Getting Started

Before starting it is important to ensure the Azure Subscription is properly configured for a personal instance.

## Resource Providers

To ensure the successful deployment, the following Azure Resource Providers must be registered in the subscription.

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

### Registering Resource Providers

To register the necessary resource providers for your subscription, please refer to the [Azure Resource Providers and Types documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-providers-and-types).

This documentation provides detailed instructions on how to register resource providers using the Azure portal, Azure CLI, and other methods.

## Role Assignments

The following role assignments are required for users within the subscription to ensure the proper functioning of this solution:

| Role                          | Purpose                                                                                                  | Role ID                                          |
|-------------------------------|----------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| Contributor                   | Grants full access to manage all resources, but does not allow you to assign roles in Azure RBAC, manage assignments in Azure Blueprints, or share image galleries. | `b24988ac-6180-42a0-ab88-20f7382dd24c`           |
| Role Based Access Control Administrator | Manages access to Azure resources by assigning roles using Azure RBAC. This role does not allow you to manage access using other ways, such as Azure Policy. | `f58310d9-a9f6-439a-9e8d-f62e7b41a168`           |
| Resource Policy Contributor   | Users with rights to create/modify resource policies, create support tickets, and read resources/hierarchy. This role is essential for managing resource policies effectively. | `36243c78-bf99-498c-9df9-86d9f8d28608`           |

### Assigning Roles

To assign roles to users within your Azure subscription, follow the steps outlined in the [Azure Role Assignments documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-steps).

This documentation provides you with detailed instructions on how to assign roles using the Azure portal, Azure CLI, and other methods.