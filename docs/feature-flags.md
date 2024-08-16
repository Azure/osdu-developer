# Optional Features

Customize your resources by enabling these optional features based on your specific requirements:


### Feature: Software Options

__Purpose:__ Specify software load options.

__Details:__ There are situations in which partial selection of software to install is helpful. Software loads can be disabled as well as categories of OSDU services can be selectively enabled/disabled from loading.

__How To Enable:__

```bash
azd env set ENABLE_SOFTWARE true/false
azd env set ENABLE_OSDU_CORE true/false
azd env set ENABLE_OSDU_REFERENCE true/false
```


### Feature: Pod Subnet

__Purpose:__ Enhances network configuration for Kubernetes Pods.

__Details:__ Typically, with kubenet in Kubernetes, nodes are assigned IP addresses from the Azure virtual network subnet. Enabling the Pod Subnet feature allows Pods to receive IP addresses from a different address space, separate from the subnet of the nodes. This separation alters the network flows.


__How To Enable:__

```bash
azd env set ENABLE_POD_SUBNET true
```


### Feature: Vnet Injection

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


### Feature: Manage

__Purpose:__ Facilitates secure access to internal network resources.

__Details:__ Internal ingress configurations can sometimes make it challenging to access network resources. The Bastion feature addresses this by creating a bastion host and a virtual machine. These components act as a secure gateway, allowing you to communicate with and manage resources within the private network, even if they're not exposed to the public internet.

__How To Enable:__

```bash
azd env set ENABLE_MANAGE true
```

### Feature: Public Blob Access

__Purpose:__ Control public access to Blob Storage.

__Details:__ The Storage accounts have public access points that can be enabled or disabled to enhance security.

__How to Disable:__

```bash
azd env set ENABLE_BLOB_PUBLIC_ACCESS false
```