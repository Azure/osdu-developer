# Architecture

!!! Hint
    OSDU Developer is built using the following principles from the Azure Well-Architeced Framework.
    For a deeper understanding, we recommend reading our article on Micosoft Learn
    [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/).
    This provides valuable insights into best practices and design
    considerations of azure workloads.

#### Desired State Configuration

Bicep is a domain-specific language (DSL) for deploying Azure resources declaratively. It simplifies authoring ARM templates and allows you to define the desired state of your Infrastructure as Code (IaC). Azure Resource Manager (ARM) processes the Bicep file to ensure the Azure environment matches the defined desired state, correcting any drift through redeployment.

!!! Note
    Microsoft recommends when developing with Bicep to use official [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/).


#### Desired State Management

[GitOps](https://opengitops.dev) uses Git as a single source of truth for declarative components and applications. It ensures that the actual state of the components or application matches the desired state defined in the Git repository, automating updates through continuous monitoring and Git commits.


## Command Sequence

This sequence diagram illustrates the interactions within the Azure CLI developer command structures.

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

## Infrastructure

This diagram provides a visual representation of the infrastructure as deployed. It is intended to help illustrate the various components and interactions within Azure.

![[0]][0]

### Components

1. Azure Virtual Network - Illustrate the default network design.
2. Kubernetes Node Pools - Illustrate the design for the cluster nodepools.
3. Storage Resources - Illustrate how Storage Accounts and Cosmos Databases connect to the network.
4. Ingress Load Balancers - Illustrate how the Load Balancers created by Istio Gateways are available in the network.

## Software

In this workspace, we utilize a GitOps approach for efficient and reliable software management. This method leverages a Git repository as the source of truth for defining and updating the software configurations and deployments within the infrastructure.

### GitOps Configuration

A GitOps configuration resides in this Git repository and uses a customized [repo-per-team](https://fluxcd.io/flux/guides/repository-structure/#repo-per-team) pattern. This repository includes:

- **Configuration Files**: YAML files defining the desired state of our components and applications.

- **Charts**: Helm charts used for defining, installing, and upgrading Kubernetes applications.

### GitOps Advantages

- **Consistency and Standardization**: Ensures consistent configurations across different environments.
- **Audit Trails**: Every change is recorded in Git, providing a clear audit trail.
- **Rollbacks and Recovery**: Every change is recorded in Git, providing a clear audit trail.
- **Enhanced Security**: Changes are reviewed through pull requests, increasing security and collaboration.

A GitOps approach simplifies the process of deploying and managing software, making it easier to maintain and update, as well as providing a configurable way of leveraging other software configurations by pointing to alternate repositories hosting other configurations. By leveraging this method, we ensure that our deployments can be extended to things that not only include the default software load.

![[1]][1]

[0]: images/architecture.png "Architecture Diagram"
[1]: images/architecture_2.png "Gitops Diagram"