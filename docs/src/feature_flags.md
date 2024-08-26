# Feature Flags

Feature flags can be set prior to running provision with the command `azd env set <FLAG> <VALUE>`

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
| SOFTWARE_VERSION          | Sets the version (branch) of OSDU to be installed                           |

## Bastion Management

Modify the infrastructure and network by enabling Bastion Host with a virtual machine to use for access.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_MANAGE             | Enables a Bastion Host with a virtual machine for private admin access      |

## Public Storage Access

Control public access to Storage.

| Feature Flag              | Description                                                                 |
|---------------------------|-----------------------------------------------------------------------------|
| ENABLE_BLOB_PUBLIC_ACCESS | Enables public access for storage account blob (False by default)           |


## Vnet Injection

__Purpose:__ Enables a bring your own network capability.

__Details:__ Typically, internal solutions require a preconfigured network due to possible S2S vpn configurations or a Hub Spoke Network design.

__How To Enable:__

```bash
azd env set VIRTUAL_NETWORK_GROUP <your_network_group>
azd env set VIRTUAL_NETWORK_NAME <your_network_name>
azd env set VIRTUAL_NETWORK_PREFIX <your_network_prefix>
azd env set VIRTUAL_NETWORK_IDENTITY <your_network_managed_identity>

azd env set AKS_SUBNET_NAME <your_subnet_name>
azd env set AKS_SUBNET_PREFIX <your_subnet_prefix>

azd env set POD_SUBNET_NAME <your_subnet_name>
azd env set POD_SUBNET_PREFIX <your_subnet_prefix>
```


