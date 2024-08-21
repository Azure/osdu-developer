# Software Management with a GitOps Approach

In this workspace, we utilize a **GitOps** approach for efficient and reliable software management. This method leverages this Git repository as the source of truth for defining and updating the software configurations and deployments within our infrastructure.

## GitOps Configuration

Our GitOps configuration resides in this Git repository and employs a customized [repo-per-team](https://fluxcd.io/flux/guides/repository-structure/#repo-per-team) pattern. This repository includes:

- **Configuration Files**: YAML files that define the desired state of our components and applications.
  
- **Charts**: Helm charts used for defining, installing, and upgrading Kubernetes applications.

## Advantages of GitOps

- **Consistency and Standardization**: Ensures consistent configurations across different environments, minimizing discrepancies.
  
- **Audit Trails**: Every change is recorded in Git, providing a clear audit trail for accountability and traceability.
  
- **Rollbacks and Recovery**: Allows for easy rollbacks to previous configurations in case of errors or issues.
  
- **Enhanced Security**: Changes are reviewed through pull requests, increasing security and promoting collaboration among team members.

## Simplified Deployment Process

Our GitOps approach simplifies the process of deploying and managing software, making it easier to maintain and update configurations. It also provides a configurable way to leverage other software configurations by pointing to alternate repositories that host additional configurations. This extensibility ensures our deployments can include not only the default software load but also any additional components required by our architecture.

## Kustomizations

In our software architecture design, we have two primary Kustomizations that describe a **stamp**:

1. **Components**: This includes middleware layers that provide essential services to the platform. Examples of components are:
   - Certificate Manager
   - Istio
   - Operators

2. **Applications**: This category encompasses the code that functions as applications within the OSDU developer platform. Notable examples include:
   - OSDU Core Services
   - OSDU Reference Services

### Stamp Layout

The stamp layout is organized as follows:

```bash
├── applications
│   └── kustomize.yaml
└── components
    └── kustomize.yaml
```

- applications/kustomize.yaml: This file defines the Kustomization for the various applications that run on the platform.

- components/kustomize.yaml: This file specifies the Kustomization for the middleware components that support the applications.

By structuring our Kustomizations in this manner, we ensure clarity and separation of concerns, making it easier to manage and scale separately both components and applications.

### Components Structure

The Components directory is organized to facilitate the management of various middleware layers essential for our infrastructure. Below is the layout:

```bash
└── components
    ├── README.md
    ├── certs
    │   ├── namespace.yaml
    │   ├── release.yaml
    │   └── source.yaml
    ├── certs-ca
    │   └── certificate.yaml
    ├── certs-ca-issuer
    │   └── issuer.yaml
    ├── elastic-storage
    │   └── storage-class.yaml
    ├── mesh-ingress
    │   └── gateway.yaml
    ├── observability
    │   ├── grafana.yaml
    │   ├── jaeger.yaml
    │   ├── kiali.yaml
    │   ├── loki.yaml
    │   ├── prometheus.yaml
    │   └── subnet_monitoring.yaml
    ├── osdu-config
    │   └── release.yaml
    └── osdu-system
        ├── airflow.yaml
        ├── cache.yaml
        ├── database.yaml
        ├── elastic.yaml
        ├── mesh.yaml
        ├── namespace.yaml
        └── reloader.yaml
```

__Directory Breakdown__

- certs: Contains YAML files for managing certificates, including:
- namespace.yaml: Defines the namespace for the certificate resources.
- release.yaml: Specifies the release configuration for the certificates.
- source.yaml: Outlines the source for certificate generation.
- certs-ca: Contains the configuration for Certificate Authority certificates:
- certificate.yaml: Defines the CA certificate.
- certs-ca-issuer: Contains the issuer configuration for certificates:
- issuer.yaml: Specifies the issuer details.
- elastic-storage: Contains the configuration for ElasticSearch storage:
- storage-class.yaml: Defines the storage class for ElasticSearch.
- mesh-ingress: Contains the configuration for ingress routing:
- gateway.yaml: Defines the gateway configuration for the service mesh.
- observability: Includes configurations for observability tools:
- grafana.yaml, jaeger.yaml, kiali.yaml, loki.yaml, prometheus.yaml, subnet_monitoring.yaml: Define settings for various observability tools.
- osdu-config: Contains configuration files for OSDU services:
- release.yaml: Specifies the release configuration for OSDU.
- osdu-system: Contains configurations for the OSDU system components:
- Includes files for airflow, cache, database, elastic, mesh, namespace, and reloader, each defining the necessary configurations for those services.

__Applications Structure__

The Applications directory is organized to manage various applications within the OSDU developer platform. Below is the layout:

```bash
── applications
│   ├── elastic-search
│   │   ├── elastic-job.yaml
│   │   ├── elastic-search.yaml
│   │   ├── kibana.yaml
│   │   ├── namespace.yaml
│   │   └── vault-secrets.yaml
│   ├── osdu-auth
│   │   ├── namespace.yaml
│   │   └── release.yaml
│   ├── osdu-core
│   │   ├── README.md
│   │   ├── base.yaml
│   │   ├── entitlements.yaml
│   │   ├── file.yaml
│   │   ├── indexer.yaml
│   │   ├── legal.yaml
│   │   ├── namespace.yaml
│   │   ├── partition.yaml
│   │   ├── schema.yaml
│   │   ├── search.yaml
│   │   ├── storage.yaml
│   │   └── user-init.yaml
│   ├── osdu-reference
│   │   ├── base.yaml
│   │   ├── crs-catalog.yaml
│   │   ├── crs-conversion.yaml
│   │   ├── namespace.yaml
│   │   └── unit.yaml
│   └── podinfo
│       ├── ingress.yaml
│       ├── namespace.yaml
│       ├── release.yaml
│       └── source.yaml
```

- dev-sample: Contains sample application configurations:
- httpbin.yaml: Configuration for the HTTP Bin sample application.
- namespace.yaml: Defines the namespace for the sample application resources.
- release.yaml: Specifies the release configuration for the sample application.
- elastic-search: Includes configurations for the ElasticSearch application:
- elastic-job.yaml: Defines a job for ElasticSearch.
- elastic-search.yaml: Configuration for the ElasticSearch deployment.
- kibana.yaml: Configuration for Kibana, the visualization tool.
- namespace.yaml: Defines the namespace for ElasticSearch resources.
- vault-secrets.yaml: Contains the secrets required by ElasticSearch.
- osdu-auth: Contains configurations for OSDU authentication services:
- namespace.yaml: Defines the namespace for authentication resources.
- release.yaml: Specifies the release configuration for the authentication service.
- osdu-core: Includes configurations for core OSDU services:
- Contains multiple YAML files for defining the service configurations, including:
- base.yaml, entitlements.yaml, file.yaml, indexer.yaml, legal.yaml, namespace.yaml, partition.yaml, schema.yaml, search.yaml, storage.yaml, user-init.yaml.
- osdu-reference: Contains configurations for reference services in OSDU:
- Includes base.yaml, crs-catalog.yaml, crs-conversion.yaml, namespace.yaml, and unit.yaml.
- podinfo: Contains configurations for the Podinfo application:
- ingress.yaml: Defines ingress rules for the Podinfo application.
- namespace.yaml: Defines the namespace for Podinfo resources.
- release.yaml: Specifies the release configuration for Podinfo.
- source.yaml: Contains the source configuration for Podinfo.