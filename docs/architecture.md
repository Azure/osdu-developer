# Architecture.

Guiding Principles
The developer sandbox is built using the following principles from the Azure Well-Architected Framework.

Cost Optimization - Creating a cost-effective solution while balancing security.
Security - Enhancing security within a development context, adhering to a zero trust model.
Operational Excellence - Prioritizing DevOps standards with automation to ensure efficient operations and robust monitoring.
Bicep: Desired State Configuration

Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It simplifies authoring ARM templates and allows you to define the desired state of your Azure infrastructure in code. Azure Resource Manager (ARM) processes the Bicep file to ensure the Azure environment matches the defined desired state, correcting any drift through redeployment.

GitOps: Desired State Management

GitOps uses Git as a single source of truth for declarative components and applications. It ensures that the actual state of the components or application matches the desired state defined in the Git repository, automating updates through continuous monitoring and Git commits.


# Sequence Diagram

This diagram documents how the interactions work for the Azure CLI Developer Command Structures

<!--- https://diagrams.helpful.dev/ --->

```mermaid
sequenceDiagram
    participant Azd as user
    participant Provision as command
    participant Azure as azure


    rect rgb(191, 223, 255)
    alt
    Note over Provision: featureCheck
    Note over Provision: credCheck
    end
    Azd->>+Provision: azd provision
    Provision->>Azure: arm deploy
    Provision-->>-Azd: complete
    alt
    Note over Provision: softwareCheck
    Note over Provision: entraAuth
    end
    end

    rect rgb(144,238,144)
    alt
    Note over Provision: firstUser
    Note over Provision: refreshToken
    end
    Azd->>Provision: azd deploy
    activate Provision
    Provision-->>Azd: complete
    deactivate Provision
    alt
    Note over Provision: settingsJson
    end
    end
```

# Infrastructure

The architecture diagram below provides a visual representation of the infrastructure when deployed. It's designed to help you understand the various components and how they interact within the Azure environment.

![[0]][0]

## Key Components Illustrated in the Diagram:

1. Azure Virtual Network: Illustrates the network and how feature enablement changes the network structure and subnets.
2. Azure Kubernetes Service (AKS): Demonstrates the Kubernetes clusters and an example of how software is set up along with interactions to other Azure services.
3. Storage Resources: Illustrates the use of services such as Azure Storage Accounts and Azure Cosmos Databases and how they connect to the network.
4. Optional Features: If enabled, features like the Bastion Host, Public Blob Access and Pod Subnet are represented, attempting to show their placement and role within the architecture.

## Software Management with a Gitops Approach

In this workspace, we utilize a GitOps approach for efficient and reliable software management. This method leverages this Git repository as the source of truth for defining and updating the software configurations and deployments within the infrastructure.

### GitOps Configuration

Our GitOps configuration resides in this Git repository and uses a customized [repo-per-team](https://fluxcd.io/flux/guides/repository-structure/#repo-per-team) pattern. This repository includes:

- **Configuration Files**: YAML files defining the desired state of our components and applications.

- **Charts**: Helm charts used for defining, installing, and upgrading Kubernetes applications.

### Advantages of GitOps

- **Consistency and Standardization**: Ensures consistent configurations across different environments.
- **Audit Trails**: Every change is recorded in Git, providing a clear audit trail.
- **Rollbacks and Recovery**: Every change is recorded in Git, providing a clear audit trail.
- **Enhanced Security**: Changes are reviewed through pull requests, increasing security and collaboration.

Our GitOps approach simplifies the process of deploying and managing software, making it easier to maintain and update, as well as providing a configurable way of leveraging other software configurations by pointing to alternate repositories hosting other configurations. By leveraging this method, we ensure that our deployments can be extended to things that not only include the default software load.

[0]: images/architecture.png "Architecture Diagram"
