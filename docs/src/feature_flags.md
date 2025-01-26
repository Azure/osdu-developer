# Configuration Flags

Feature flags are configuration settings used to modify the default behavior of an OSDU™ personal instance.

<div class="grid cards" markdown>

- :material-toggle-switch-outline: __Toggle__ alternate functionality
- :material-cloud-outline: __Deploy__  alternate infrastructure
- :material-cog-outline: __Override__ default settings
- :material-wrench-outline: __Configure__ custom software 

</div>


!!! warning "CLI Deployment Only"
    Feature flags are implemented as named environment variables which correspond to ARM template parameter objects and are set prior to provisioning.

=== "Command"
    
    ```bash
    azd env set <FLAG> <VALUE>
    ```

## Azure Region and Subscription

Azure subscriptions and region location are set interactively by default but can be directly specified.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| AZURE_SUBSCRIPTION_ID    | Azure subscription ID for resource deployment                              |
| AZURE_LOCATION           | Azure location for resource deployment                                      |

## Microsoft Entra ID Application

Application registrations are created automatically with a naming convention of osdu-{environment}-{subscription} but can be manually created and provided.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| AZURE_CLIENT_ID           | Use an existing Azure AD App Client ID                                      |
| AZURE_CLIENT_PRINCIPAL_OID| Skip Principal ID lookup and use provided.                                  |
| AZURE_TENANT_ID           | Skip Tenant ID lookup and use provided.                                     |


## Custom Infrastructure

Infrastructure customizations can be modified using the following feature flags.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| CLUSTER_INGRESS           | Specifies the Ingress type for the cluster (External, Internal, or Both)    |
| VMSIZE_SYSTEM_POOL        | Overrides the default server for the system pool. (4x8 ARM)                 |
| VMSIZE_ZONE_POOL          | Overrides the default server for the zone pool. (2x8 ARM)                   |
| VMSIZE_USER_POOL          | Overrides the default server for the default pool. (4x8 INTEL)              |
| ENABLE_NODE_AUTO_PROVISIONING | Enables node auto provisioning (True by default)                        |
| ENABLE_PRIVATE_CLUSTER    | Enables private cluster (False by default)                                  |


## Custom Software

Software customizations can be modified using the following feature flags.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_SOFTWARE           | Disables loading of all software when set to false (True by default)        |
| ENABLE_PRIVATE_SOFTWARE   | Software from Azure Blob instead of Git Repositories (False by default)     |
| ENABLE_OSDU_CORE          | Disables loading of the osdu core services (True by default)                |
| ENABLE_OSDU_REFERENCE     | Disables loading of the osdu reference services (True by default)           |
| SOFTWARE_VERSION          | Sets the version (branch) of OSDU to be installed (release-0-27)            |
| SOFTWARE_REPOSITORY       | Customizes the repository location used for software definition             |
| SOFTWARE_BRANCH           | Customizes the branch used for software definition                          |


## Experimental Software

Experimental Software can be enabled using the following feature flags.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_EXPERIMENTAL       | Enables loading of experimental software (False by default)                 |
| ENABLE_ADMIN_UI           | Enables loading of the Admin UI (False by default)                          |


## Enable VNET Injection

Modify the network configuration for use with a pre-existing virtual network.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| VIRTUAL_NETWORK_GROUP     | Resource group of the existing virtual network                               |
| VIRTUAL_NETWORK_NAME      | Name of the existing virtual network                                         |
| VIRTUAL_NETWORK_PREFIX    | Address prefix of the existing virtual network                               |
| VIRTUAL_NETWORK_IDENTITY  | Managed identity associated with the existing virtual network                |
| AKS_SUBNET_NAME           | Name of the subnet for AKS within the existing virtual network               |
| AKS_SUBNET_PREFIX         | Address prefix for the AKS subnet                                            |
| POD_SUBNET_NAME           | Name of the subnet for Pods within the existing virtual network              |
| POD_SUBNET_PREFIX         | Address prefix for the Pod subnet                                            |
