# Overview

Personal OSDU™ instances offer flexibility in service deployments. Latest master is deployed by default although users have the option to select milestone releases.

<div class="grid cards" markdown>
- :material-source-branch: __Master Branch__ - Current code
- :material-tag-outline: __Release Branches__ - Milestone code
</div>


!!! tip "Deploy Milestones"
    Use Feature Flag _`SOFTWARE_VERSION`_ to deploy release branches.
    
    For available releases, see [OSDU Milestones](https://community.opengroup.org/osdu/platform/-/milestones).


## Core Services

| **Name**                                                                               | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Partition Service](https://community.opengroup.org/osdu/platform/system/partition)             | Manages data partitions to ensure efficient data management and scalability.                    |
| [Entitlement Service](https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements) | Provides access control and permissions management for data within the OSDU platform. |
| [Legal Service](https://community.opengroup.org/osdu/platform/security-and-compliance/legal)   | Ensures that data compliance and legal requirements are met, including data privacy and governance. |
| [Indexer Service](https://community.opengroup.org/osdu/platform/system/indexer-service)        | Indexes and categorizes data to enable efficient search and retrieval.                           |
| [Indexer Queue](https://community.opengroup.org/osdu/platform/system/indexer-queue)            | Manages the queue for processing indexing tasks, ensuring data is indexed in a timely manner.    |
| [Schema Service](https://community.opengroup.org/osdu/platform/system/schema-service)          | Manages and provides access to data schemas that define the structure and format of data.        |
| [Storage Service](https://community.opengroup.org/osdu/platform/system/storage)                | Provides scalable storage solutions for managing and retrieving large volumes of data.           |
| [Search Service](https://community.opengroup.org/osdu/platform/system/search-service)          | Facilitates searching and querying across data stored within the OSDU platform.                  |
| [File Service](https://community.opengroup.org/osdu/platform/system/file)                      | Handles file operations such as storage, retrieval, and management of data files.                |
| [Workflow Service](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-workflow/)  | Initiates business processes within the system. During the prototype phase, it facilitates CRUD operations on workflow metadata and triggers workflows in Apache Airflow. Additionally, the service manages process startup records, acting as a wrapper around Airflow functions.. |

## Reference Services

| **Name**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Unit Service](https://community.opengroup.org/osdu/platform/system/reference/unit-service)    | Provides dimension/measurement and unit definitions.                                             |
| [CRS Catalog Service](https://community.opengroup.org/osdu/platform/system/reference/crs-catalog-service) | Provides API endpoints to work with geodetic reference data, allowing developers to retrieve CRS definitions, select appropriate CRSs for data ingestion, and search for CRSs based on various constraints. |
| [CRS Conversion Service](https://community.opengroup.org/osdu/platform/system/reference/crs-conversion-service)  | Enables the conversion of coordinates from one coordinate reference system (CRS) to another. |

## Airflow DAGS

| **Name**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Manifest Ingestion DAG](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-dags)    | Used for ingesting single or multiple metadata artifacts about datasets into OSDU.                                             |
| [CSV Parser DAG:](https://community.opengroup.org/osdu/platform/data-flow/ingestion/csv-parser/csv-parser)    | Helps in parsing CSV files into a format for ingestion and processing.                                             |

## Experimental Software

OSDU offers various experimental capabilities that are either very new or community contributions. These services are not yet fully mature but are available for early adopters to test and provide feedback. This solution supports the concept of experimental software through opt-in feature flags, allowing users to selectively enable and test these new features.

!!! note
    Experimental software is often less stable and contains less documentation.

| **Name**                                                                   | **Description**                                                                                 |
|-------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| [Admin UI](https://community.opengroup.org/osdu/ui/admin-ui-group/admin-ui-totalenergies/admin-ui-totalenergies)    | A community supported Angular Administration UI for OSDU.                        