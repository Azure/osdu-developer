# Overview


OSDU Developer is an open-source solution designed to enable the creation of lightweight, personal instances of [OSDU™](https://osduforum.org/osdu-data-platform-primer-1/) running on the Azure Public Cloud. These personal instances are tailored specifically for developers and work with the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview). This allows engineers to explore and author applications or work directly on technology prior to the transition to a fully managed service offering. A simplified one-click deployment capability with less development features is also available.

!!! Note
    Microsoft recommends using [Azure Data Manager for Energy (ADME)](https://azure.microsoft.com/en-us/products/data-manager-for-energy) on production workloads and integration testing.

The primary goal for this solution is to provide an environment that can help function within an inner loop process providing faster feedback for developers. This personal environment strives to be user-friendly yet maintain compliance with varying organizational standards. It offers a flexible framework to facilitate deeper exploration of OSDU™ capabilities.

![[0]][0]

Deploying personal instances provide valuable insights into early-stage development and integration processes. It emphasizes transparency, cost-efficiency, and flexibility, empowering developers to engage in essential application and cloud development scenarios.

!!! Note
    Learn more about how inner and outer loop concepts can enhance developer productivity by viewing a discusion with Scott Hanselman, VP of Developer Community at Microsoft on the Planet Argon Podcast [The Fear Factor in Maintainable Software](https://www.youtube.com/watch?v=V5OhIjn7pJo)
 
### Key Benefits

**Observability and Transparency:**  Interact directly with resource and software components within the solution to facilitate enhanced observability through logs, dashboards, and source code debugging.

**Cost Efficiency:**  Deploy with minimal resource consumption omitting costly features like disaster recovery and backup to minimize consumption costs.

**Flexibility:** Provide adaptable infrastructure to meet various organizational needs.

- Virtual Network Injection - Flexible network designs, including site-to-site VPN connections and integration with preexisting networks.

- Controlled Access - Public or private ingress, with the option to layer your own routing solutions for ingress, such as Azure Firewall or Azure Front Door.

- Software Isolation - Override and isolate defined software configurations as well as extend with custom configurations.

### Use Cases
 
Several use cases illustrate the practical applications for this approach.

**Service Development:** Create, update, debug, and work directly with OSDU services.

**Application Development:** Easy development for applications prior to integration with a managed service offering.

**Technology Innovation:**  Fork and extend exploring deeper integration with various technologies such as Azure Fabric, Co-Pilot, and Power Platform.

**Training and Onboarding:**  Train new employees on the OSDU™ platform, offering hands-on experience in a controlled environment.
 
![[1]][1]


## Features

 | **Feature**            | **Description**                                                                                                    |
|------------------------|--------------------------------------------------------------------------------------------------------------------|
| Data Partitions        | Supports a single data partition for managing and organizing data within the platform, named "opendes."            |
| Schema Loading         | Automatically loads Well Known Schemas for efficient data management and validation.                               |
| Software Locations     | Utilizes Flux to direct the software loading process to private GitHub repositories and branches.                  |
| Ingress                | Supports both public-facing and private network access points.                                                     |
| Network flexibility    | Supports VNet injection and integration with existing networks, to easily allow for S2S Vpn access.                |
| Mesh Observability     | Provides observability for istio using Kiali dashboards to investigate latency, traffic, errors, and saturation.   |
| Elastic Tools          | Supports connectivity to Elastic Kibana for advanced devtools, search capabilities, and user management.           |
| Application Logging    | Integrated with Application Insights for detailed service-level logging and metrics monitoring.                    |
| Initial User           | Includes initial user setup and configuration for openid connect access.                                           |
| Rest Scripts           | Integrated Sample Rest Scripts for easily executing API calls to test and explore functionality.                   |
| Token Tools            | Integrated Access Token Tools for easy retrieval of Bearer Access Tokens for with Swagger Pages and docs.          |

## About this guide

Follow the instructions in the "Tutorials" to quickly bring online a personal instance.

[0]: images/overview_1.png "Overview Diagram"
[1]: images/overview_2.png "Use Cases Diagram"