# OSDU Personal Instances

OSDU Developer is an open-source solution to enable easy creation of Personal Instances of OSDU running in the Azure Public Cloud.

## What is it?
 
This Azure Developer CLI (AZD) integrated solution, along with a one-click deployment option, allows engineers to explore authoring applications or work directly on individual or custom OSDU services prior to transitioning to a fully managed service offering like ADME.
 
The primary objective is to offer an environment for use as an inner loop development cycle within an organization’s own cloud tenant while working and exploring with the open-source codebase. This engineering environment is easy to work with and strives to ensure compliance through a flexible infrastructure framework, providing a path to explore the depth of OSDU.

Deploying a personal instance of the OSDU open-source solution on Azure Cloud delivers practical insights into early development and integration processes. It ensures transparency, cost-efficiency, and flexibility, while enabling essential application and cloud developer scenarios.
 
### Key Benefits

- **Observability and Transparency:**  Direct interaction with the resources, software, and components of the solution facilitates enhanced observability through logs, dashboards, and source code debugging, providing transparency crucial for developers.

- **Cost Efficiency:**  By deploying with minimal resources, cluster compute, and omitting costly features like disaster recovery (DR) and backup, consumption costs are minimized.

- **Flexibility:**  Supports scenarios such as:

- **Virtual Network Injection:** Allows for flexible network designs with site-to-site VPN connections and integration with preexisting networks.

- **Controlled Access:** Supports both public and private ingress along with the ability to layer your own routing solutions for ingress, such as Azure Firewall and Azure Front Door.

- **Software Isolation**:** Override and isolate the defined software customizations while extending into additional custom software configurations.

### Scenarios
 
Several scenarios illustrate the practical applications of this approach, such as:

- **Service Development:** Enables engineers to create, update, debug, and work with integrated OSDU services.
Application Development: Allows for easy developer integration with applications being developed for initial testing prior to integration with a managed service offering.

- **Innovate with Azure-Specific Technologies:**  Fork and extend the solution to explore deeper integration with Azure-specific tools and technologies such as Azure Fabric, Co-Pilot, and Power Platform, impacting various Azure integration points.

- **Training and Onboarding:**  Provides a valuable opportunity for training new employees on Azure within the OSDU framework, offering hands-on experience in a controlled environment.
 

## Main features

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

Follow the instructions in the "Quickstart" to quickly bring online a personal instance of OSDU.

