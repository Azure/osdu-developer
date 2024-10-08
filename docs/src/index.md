# Overview

OSDU Developer is an open-source solution designed to enable the creation of lightweight, personal instances of the [Open Subsurface Data Universe (OSDU™)](https://osduforum.org/osdu-data-platform-primer-1/) platform running on the Azure Public Cloud. These personal instances are tailored specifically for engineers and are integrated with the [Azure Developer CLI (AZD)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) for deployment along with a customized environment setup. The solution allows engineers to explore, integrate services, author applications, or work directly with specific technology prior to the transition to a fully managed service. 

An alternate deployment approach uses a simplified [custom ARM template deployment](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fosdu-developer%2Fmain%2Fazuredeploy.json). This method has a slightly more complicated implmentation of parameters with fewer integrations and automation as compared to the AZD deployment. As a result, it is less suited for a tight development loop but can be affective for quick personal deployments.

!!! Note
    Microsoft recommends using [Azure Data Manager for Energy (ADME)](https://azure.microsoft.com/en-us/products/data-manager-for-energy) for any production workloads and integration testing.

This solution aims to create an environment for efficient inner loop workflows, enabling rapid feedback for engineers. It balances user-friendliness with organizational compliance, offering a flexible pattern to work with for an in-depth exploration or expansion of OSDU™ capabilities. By providing enhanced transparency into the underlying components, it empowers developers to gain deeper insights and troubleshoot more effectively. Personal OSDU™ instances offer developers a unique advantage in early-stage development and integration, allowing for rapid prototyping and testing of OSDU™ based solutions. This approach aligns with modern software development practices, emphasizing the importance of rapid iteration and testing in application prototyping and cloud integration scenarios.

![[0]][0]

- **Observability**: Direct access to the underlying infrastructure and components
- **Faster feedback**: Accelerated development loops with established patterns for service development and rapid iteration
- **Compliant**: Ability to align with specific organizational standards and security requirements
- **Flexible**: Customized environments to suit diverse project needs

??? Tip "Learning Opportunity"
    Learn more about how inner and outer loop concepts can enhance developer productivity by viewing a discussion with Scott Hanselman, VP of Developer Community at Microsoft, on the Planet Argon Podcast: [The Fear Factor in Maintainable Software](https://www.youtube.com/watch?v=V5OhIjn7pJo).

## Personas

The OSDU™ platform serves a diverse range of professionals within the energy industry. Each persona may interacts with personal instances in different and unique ways, leveraging different capabilities and features to meet specific needs or challenges. 

<div class="grid cards" markdown>

-   :fontawesome-solid-code:{ .lg .middle } __Application Developers__

    ---

    Build applications leveraging APIs with the need to debug and interact efficiently.

-   :fontawesome-solid-chart-line:{ .lg .middle } __Data Scientists__

    ---

    Analyze data or explore integration options to derive insights using machine learning and statistical methods.

-   :fontawesome-solid-cloud:{ .lg .middle } __Cloud Architects__

    ---

    Explore alternate designs and implementations for the platform and integrate it with additional cloud services or AI services.

-   :fontawesome-solid-database:{ .lg .middle } __Data Engineers__

    ---

    Ensure proper data preparation and ingestion within the ecosystem to derive patterns for larger production datasets.

-   :fontawesome-brands-git-alt:{ .lg .middle } __DevOps Engineers__

    ---

    Streamline the deployment, monitoring, and maintenance of the platform and applications, ensuring efficient development and operations.


-   :fontawesome-solid-user-tie:{ .lg .middle } __Domain Experts__

    ---

    Utilize their specialized knowledge to develop domain-specific applications or services within the platform.

</div>



## Benefits

:material-eye-outline: **Transparent:** Interact directly with resources and software components within the solution to enhance observability through logs, dashboards, and source code debugging.

:material-cash: **Affordable:** Deploy with minimal resource consumption by omitting costly features like disaster recovery and backups, minimizing operational costs.

:material-swap-horizontal-bold: **Configurable:** The solution provides adaptable infrastructure to meet various organizational needs, including:

=== "Virtual Network Injection"

    Flexible network designs, including site-to-site VPN connections and integration with preexisting networks.

=== "Controlled Access"

    Public or private ingress, with the option to layer custom routing solutions for ingress, such as Azure Firewall or Azure Front Door.

=== "Software Isolation"

    Override and isolate software configurations as well as extend with custom configurations.


## Scenarios

OSDU™ private instances are designed to support a wide range of use cases, catering to various needs within a software development lifecycle. By providing a flexible and customizable environment, it enables developers, engineers, and other professionals to explore and leverage the OSDU™ platform in multiple ways. Here are several key scenarios that illustrate the practical applications of this approach:

<div class="grid cards" markdown>

-   :material-cog:{ .lg .middle } __Service Development__

    ---

    Build, test, debug, and work directly with OSDU™ services and experimental features.

-   :fontawesome-solid-laptop-code:{ .lg .middle } __Application Development__

    ---

    Streamlined development for applications before integration with a managed service offering.

-   :fontawesome-solid-lightbulb:{ .lg .middle } __Technology Innovation__

    ---

    Fork and extend projects to explore deeper integration with various technologies such as Fabric, Co-Pilot, and the Power Platform.

-   :material-school:{ .lg .middle } __Training and Onboarding__

    ---

    Train new employees on the OSDU™ platform, offering hands-on experience in a controlled environment.

</div>

## Feature List

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