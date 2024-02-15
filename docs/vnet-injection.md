# Virtual Network Injection

The provided custom deployment solution is a sample of how to leverage the virtual network (VNet) injection feature. This allows for the integration of the solution into a prexisting network design and ensuring the solution is on an internal network.


## Planning

Network planning is crucial when working with AKS on a prexexisting network solution.  This is an advanced topic and the assumption when bringing your own network is that it has been planned properly in advance.

Several resources exist that can help on planning networks for AKS and to understand the networking concepts for AKS.

- [AKS Network Topology and Connectivity](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/app-platform/aks/network-topology-and-connectivity)

- [Azure CNI Advanced Networking](https://learn.microsoft.com/en-us/azure/aks/concepts-network#azure-cni-advanced-networking)

- [AKS Network Plugin Overviews](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/how-to-choose-the-right-network-plugin-for-your-aks-cluster-a/ba-p/3969292)

__Default Solution__

The default implementation uses a simple Virtual Network with a Kubenet plugin.  One subnet which is provided to the AKS cluster is required, and additional subnets can be enabled for Bastion.

- Virtual Network CIDR: `10.1.0.0/16`

- Cluster Nodes Subnet CIDR: `10.1.0.0/20`

- Gateway Subnet CIDR: `10.1.17.0/24`

- Bastion Subnet CIDR: `10.1.16.0/24`

- Virtual Machine Subnet CIDR: `10.1.18.0/24`

- AKS Service CIDR: `172.16.0.0/16`

- AKS DNS Service IP: `172.16.0.10`

- Docker Bridge CIDR: `172.17.0.1/16`

__Custom Solution__

This custom configuration tutorial will use a pre-created network along with a dedicated Pod Subnet which activates the [Azure CNI for dynamic IP alocation](https://learn.microsoft.com/en-us/azure/aks/configure-azure-cni-dynamic-ip-allocation) network configuration.

Things to considered when planning.

- Virtual network
  - A network can be as large as /8, but has a limit of 65,536 IP Address

- Subnet
  - A minimum subnet size: (number of nodes + 1) + ((number of nodes + 1) * maximum pods per node that you configure)
  - Example 8 node cluster: (9) + (9 * 30 (default, 30 pods per node)) = 270 (/23 or larger)

- Kubernetes Service Address 
  - Must be smaller then /12


__Network Details__

For this example the following network details will be used.

- Virtual Network CIDR: `172.18.0.0/22`

- Cluster Nodes Subnet CIDR: `172.18.0.0/24`

- Pod Subnet CIDR: `172.18.1.0/24`

- AKS Service CIDR: `172.16.0.0/16`

- AKS DNS Service IP: `172.16.0.10`

- Docker Bridge CIDR: `172.17.0.1/16`


## Prepare a virtual network

This section outlines the steps for manually creating a virtual network outside of the solution.

__Resource Group__

Use the following command to create a new resource group:

```bash
NETWORK_GROUP='operations'
AZURE_LOCATION='eastus'

# resource_group
az group create --name $NETWORK_GROUP \
--location $AZURE_LOCATION
```

__Network Security Group__

Network Security Groups (NSGs) are essential for securing virtual network resources. NSGs control inbound and outbound traffic to network interfaces (NIC), VMs, and subnets. 

Use the following commands set up an NSG with rules to allow HTTP and HTTPS traffic.


```bash
NSG_NAME='custom-vnet-nsg'

# network_security_group
az network nsg create --name $NSG_NAME \
--resource-group $NETWORK_GROUP \
--location $AZURE_LOCATION


# http_inbound_rule
az network nsg rule create --name AllowHttpInbound \
--nsg-name $NSG_NAME --resource-group $NETWORK_GROUP \
--priority 200 --access Allow --direction Inbound \
--protocol 'Tcp' --source-address-prefixes 'VirtualNetwork' --source-port-ranges '*' \
--destination-address-prefixes '*' --destination-port-ranges '80'

# https_inbound_rule
az network nsg rule create --name AllowHttpsInbound \
--nsg-name $NSG_NAME --resource-group $NETWORK_GROUP \
--priority 210 --access Allow --direction Inbound \
--protocol 'Tcp' --source-address-prefixes 'VirtualNetwork' --source-port-ranges '*' \
--destination-address-prefixes '*' --destination-port-ranges '443'
```


__Virtual Network__

The virtual network is a critical component that enables Azure resources like AKS to communicate effectively. This step involves setting up the required 'ClusterSubnet' and an optional 'PodSubnet'.

Use the following commands set up the network with a required subnet for the cluster and an optional subnet for the pods.

```bash
NETWORK_NAME='custom-vnet'
VNET_PREFIX='172.18.0.0/22'

CLUSTER_SUBNET_NAME='cluster'
CLUSTER_SUBNET_PREFIX='172.18.0.0/24'

POD_SUBNET_NAME='pods'
POD_SUBNET_PREFIX='172.18.1.0/24'

# virtual_network
az network vnet create --name $NETWORK_NAME \
--resource-group $NETWORK_GROUP \
--location $AZURE_LOCATION \
--address-prefix $VNET_PREFIX

# virtual_network_subnet_cluster
az network vnet subnet create --name $CLUSTER_SUBNET_NAME \
--resource-group $NETWORK_GROUP \
--vnet-name $NETWORK_NAME \
--address-prefix $CLUSTER_SUBNET_PREFIX \
--network-security-group $NSG_NAME

# virtual_network_subnet_pods
az network vnet subnet create --name $POD_SUBNET_NAME \
--resource-group $NETWORK_GROUP \
--vnet-name $NETWORK_NAME \
--address-prefix $POD_SUBNET_PREFIX \
--network-security-group $NSG_NAME
```


## Initialize and Configure Solution

This section provides the steps to authenticate your session then initialize a custom environment using Azure Developer CLI (azd).


__Authenticate and Initialize__

First, authenticate your session and then initialize a custom environment:

```bash
# authenticate_session
azd auth login

# initialize_environment
azd init -e custom
```

__Configure Environment Variables__

Set the necessary environment variables for your deployment:

```bash
# define_application_id
APP_NAME=<your_ad_application_name>
azd env set AZURE_CLIENT_ID $(az ad app list --display-name $APP_NAME --query "[].appId" -otsv)

# identify_software_repository
azd env set SOFTWARE_REPOSITORY https://github.com/azure/osdu-developer
azd env set SOFTWARE_BRANCH main

# enable_feature_toggles
azd env set ENABLE_POD_SUBNET true
azd env set ENABLE_VNET_INJECTION true

# define_network_configuration
azd env set VIRTUAL_NETWORK_GROUP $NETWORK_GROUP
azd env set VIRTUAL_NETWORK_NAME $NETWORK_NAME
azd env set VIRTUAL_NETWORK_PREFIX $VNET_PREFIX
azd env set AKS_SUBNET_NAME $CLUSTER_SUBNET_NAME
azd env set AKS_SUBNET_PREFIX $CLUSTER_SUBNET_PREFIX
azd env set POD_SUBNET_NAME $POD_SUBNET_NAME
azd env set POD_SUBNET_PREFIX $POD_SUBNET_PREFIX
```

__Start the Deployment__

Initiate the deployment using the following command:

```bash
# provision_solution
azd provision
```
