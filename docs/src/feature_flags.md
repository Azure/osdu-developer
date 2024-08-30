# Feature Flags

Feature flags can be set prior to running provision with the command `azd env set <FLAG> <VALUE>`

## Reusable Entra App

Entra App configurations are by default automatically created but one can be reused or created manually as well.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| AZURE_CLIENT_ID           | Use an existing Azure AD App Client ID                                      |
| AZURE_CLIENT_SECRET       | Use an existing Azure AD Client Secret and don't reset it.                  |
| AZURE_CLIENT_PRINCIPAL_OID| Skip Principal ID lookup and use provided.                                  |
| AZURE_TENANT_ID           | Skip Tenant ID lookup and use provided.                                     |

## Custom Infrastructure

Infrastructure customizations can be managed and modified using the following feature flags.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_BURSTABLE          | User cheaper Burstable server types in the cluster                          |
| CLUSTER_INGRESS           | Specifies the Ingress type for the cluster (External, Internal, or Both)    |
| CLUSTER_VM_SIZE           | Overrides the default server type with a custom VM size                     |


## Custom Software

Software customizations can be managed and modified using the following feature flags.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_SOFTWARE           | Disables loading of all software when set to false (True by default)        |
| ENABLE_OSDU_CORE          | Disables loading of the osdu core services (True by default)                |
| ENABLE_OSDU_REFERENCE     | Disables loading of the osdu reference services (True by default)           |
| SOFTWARE_VERSION          | Sets the version (branch) of OSDU to be installed (release-0-27)            |
| SOFTWARE_REPOSITORY       | Customizes the repository location used for software definition             |
| SOFTWARE_BRANCH           | Customizes the branch used for software definition                          |


## Storage Access

Control public access to Storage.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_BLOB_PUBLIC_ACCESS | Enables public access for storage account blob (False by default)           |


## Private Access

Modify the infrastructure and network by enabling Bastion Host with a virtual machine to use for access.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_MANAGE             | Enables a Bastion Host with a virtual machine for private admin access      |


## Cluster Network

Modify the cluster network configuration to utilize Azure CNI with Dynamic IP allocation.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_POD_SUBNET         | Enables a separate subnet for pod networking in the AKS cluster             |


## Virtual Network Injection

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
