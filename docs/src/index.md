# Overview

OSDU Developer is an open-source solution designed to enable the creation of lightweight, personal instances of [OSDU™](https://osduforum.org/osdu-data-platform-primer-1/) running on the Azure Public Cloud. These personal instances are tailored specifically for developers and work with the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview). This allows engineers to explore and author applications or work directly on technology prior to transitioning to a fully managed service offering. A simplified one-click deployment capability, with fewer development features, is also available.

!!! Note
    Microsoft recommends using [Azure Data Manager for Energy (ADME)](https://azure.microsoft.com/en-us/products/data-manager-for-energy) for production workloads and integration testing.

The primary goal of this solution is to provide an environment that functions within an inner loop process, delivering faster feedback for developers. This personal environment is user-friendly while maintaining compliance with varying organizational standards. It offers a flexible framework to facilitate deeper exploration of OSDU™ capabilities.

![[0]][0]

Deploying personal instances provides valuable insights into early-stage development and integration processes. This approach emphasizes transparency, cost-efficiency, and flexibility, empowering developers to engage in essential application and cloud development scenarios.

??? Tip "Learning Opportunities"
    Learn more about how inner and outer loop concepts can enhance developer productivity by viewing a discussion with Scott Hanselman, VP of Developer Community at Microsoft, on the Planet Argon Podcast: [The Fear Factor in Maintainable Software](https://www.youtube.com/watch?v=V5OhIjn7pJo).

## Personas

The Open Subsurface Data Universe (OSDU) platform is utilized by a variety of personas within the energy industry.

<div class="grid cards" markdown>

-   :fontawesome-solid-code:{ .lg .middle } __Application Developers__

    ---

    Build applications leveraging OSDU APIs to manage subsurface data efficiently.


-   :fontawesome-solid-database:{ .lg .middle } __Data Engineers__

    ---

    Ensure proper data ingestion, transformation, and accessibility within the OSDU ecosystem.


-   :fontawesome-solid-chart-line:{ .lg .middle } __Data Scientists__

    ---

    Analyze large volumes of subsurface data to derive insights using machine learning and statistical methods.


-   :fontawesome-solid-cloud:{ .lg .middle } __Cloud Architects__

    ---

    Design scalable, secure infrastructure to support the OSDU platform and integrate it with cloud services.


-   :fontawesome-solid-user-tie:{ .lg .middle } __Domain Experts__

    ---

    Utilize their specialized knowledge to develop domain-specific applications and services on the OSDU platform.


-   :fontawesome-brands-git-alt:{ .lg .middle } __DevOps Engineers__

    ---

    Streamline the deployment, monitoring, and maintenance of OSDU platform applications, ensuring efficient development and operations.

</div>



- **DevOps Engineers**: Focus on the deployment, monitoring, and maintenance of applications on the OSDU platform, ensuring streamlined and efficient development and operational processes.

## Benefits

:material-eye-outline: **Observability:** Interact directly with resources and software components within the solution to enhance observability through logs, dashboards, and source code debugging.

:material-cash: **Affordability:** Deploy with minimal resource consumption by omitting costly features like disaster recovery and backups, minimizing operational costs.

:material-swap-horizontal-bold: **Flexibility:** The solution provides adaptable infrastructure to meet various organizational needs, including:

=== "Virtual Network Injection"

    Flexible network designs, including site-to-site VPN connections and integration with preexisting networks.

=== "Controlled Access"

    Public or private ingress, with the option to layer custom routing solutions for ingress, such as Azure Firewall or Azure Front Door.

=== "Software Isolation"

    Override and isolate software configurations as well as extend with custom configurations.


## Scenarios

Several different scenarios illustrate the practical applications of this approach:

:material-cog: __Service Development__

Create, update, debug, and work directly with OSDU services.


:fontawesome-solid-laptop-code: __Application Development__

Streamlined development for applications before integration with a managed service offering.


:fontawesome-solid-lightbulb: __Technology Innovation__

Fork and extend projects to explore deeper integration with various technologies such as Azure Fabric, Co-Pilot, and Power Platform.


:material-school: __Training and Onboarding__

Train new employees on the OSDU™ platform, offering hands-on experience in a controlled environment.



## Features

| **Feature**            | **Description**                                                                                                    |
|------------------------|--------------------------------------------------------------------------------------------------------------------|
| **Data Partitions**     | Supports a single data partition, named "opendes," for managing and organizing data within the platform.           |
| **Schema Loading**      | Automatically loads Well-Known Schemas for efficient data management and validation.                               |
| **Software Locations**  | Utilizes Flux to direct software loading processes to private GitHub repositories and branches.                    |
| **Ingress**             | Supports both public-facing and private network access points.                                                     |
| **Network Flexibility** | Enables VNet injection and integration with existing networks, allowing for S2S VPN access.                        |
| **Mesh Observability**  | Provides Istio observability through Kiali dashboards to investigate latency, traffic, errors, and saturation.     |
| **Elastic Tools**       | Integrates with Elastic Kibana for advanced dev tools, search capabilities, and user management.                  |
| **Application Logging** | Integrated with Application Insights for detailed service-level logging and metrics monitoring.                    |
| **Initial User**        | Includes initial user setup and configuration for OpenID Connect access.                                           |
| **REST Scripts**        | Includes integrated sample REST scripts for easily executing API calls to test and explore functionality.          |
| **Token Tools**         | Integrates access token tools for easy retrieval of Bearer Access Tokens via Swagger pages and docs.               |



[0]: images/overview_1.png "Overview Diagram"
[1]: images/overview_2.png "Use Cases Diagram"