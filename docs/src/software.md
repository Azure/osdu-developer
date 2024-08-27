# Software Management

### Stamp Layout

In our software architecture design, we define two primary software Kustomizations that describe a **stamp**. A Kustomization is a Flux resource representing a set of defined manifests that Flux should reconcile to the cluster, with dependencies between them. Structuring our Kustomizations this way ensures clarity and separation of concerns, making it easier to manage and organize both components and applications.

1. **Components**: Middleware layers that provide essential services to the platform, necessary to support OSDU Services.
2. **Applications**: The OSDU platform services themselves, organized into logical groups of capabilities.


```mermaid
flowchart TD
  FluxSystemComponents("flux-system-components")
  FluxSystemApplications("flux-system-applications")
  FluxSystemComponents-->FluxSystemApplications
```

```bash
├── applications
│   └── kustomize.yaml
└── components
    └── kustomize.yaml
```

 

### Component Structure

The Components directory is organized to facilitate the management of various middleware layers essential for our infrastructure. Below is the layout:

Components are organized to facilitate the logical understanding of the middleware software installations.  Components have dependency structures in the sequence of configuration.  A naming pattern is used to help facilitate understanding.

```mermaid
flowchart TD
  FluxSystemComponents("flux-system-components")
  Certs("component-certs")
  CertsCA("component-certs-ca")
  CertsCAIssuer("component-certs-ca-issuer")
  OSDUSystem("component-osdu-system")
  Cache("component-cache")
  Database("component-database")
  Postgresql("component-postgresql")
  Airflow("component-airflow")
  Elastic("component-elastic")
  ElasticStorage("component-elastic-storage")
  ElasticSearch("component-elastic-search")
  Mesh("component-mesh")
  MeshIngress("component-mesh-ingress")
  Observability("component-observability")

  FluxSystemComponents-->Certs
  Certs-->CertsCA
  CertsCA-->CertsCAIssuer
  CertsCAIssuer-->OSDUSystem
  OSDUSystem-->Cache
  OSDUSystem-->Mesh
  Mesh-->MeshIngress
  MeshIngress-->Observability
  OSDUSystem-->Elastic
  Elastic-->ElasticStorage
  ElasticStorage-->ElasticSearch
  OSDUSystem-->Database
  Database-->Postgresql
  Postgresql-->Airflow
```

```bash
── components
    ├── certs
    │   ├── namespace.yaml
    │   ├── release.yaml
    │   └── source.yaml
    ├── certs-ca
    │   └── certificate.yaml
    ├── certs-ca-issuer
    │   └── issuer.yaml
    ├── database
    │   ├── namespace.yaml
    │   ├── postgresql.yaml
    │   └── vault-secrets.yaml
    ├── elastic-search
    │   ├── elastic-job.yaml
    │   ├── elastic-search.yaml
    │   ├── kibana.yaml
    │   ├── namespace.yaml
    │   └── vault-secrets.yaml
    ├── elastic-storage
    │   └── storage-class.yaml
    ├── mesh-ingress
    │   └── gateway.yaml
    ├── observability
    │   ├── grafana.yaml
    │   ├── jaeger.yaml
    │   ├── kiali.yaml
    │   ├── loki.yaml
    │   ├── prometheus.yaml
    │   └── subnet_monitoring.yaml
    └── osdu-system
        ├── airflow.yaml
        ├── cache.yaml
        ├── database.yaml
        ├── elastic.yaml
        ├── mesh.yaml
        ├── namespace.yaml
        └── reloader.yaml
```

__Applications Structure__

The Applications directory is organized to facilitate the management of applications that are installed in the platform. 

```mermaid
flowchart TD
  FluxSystemApplications("flux-system-applications")
  Podinfo("application-podinfo")
  OSDUCore("application-osdu-core")
  OSDUReference("application-osdu-reference")
  OSDUAuth("application-osdu-auth")

  FluxSystemApplications-->Podinfo
  FluxSystemApplications-->OSDUCore
  FluxSystemApplications-->OSDUReference
  FluxSystemApplications-->OSDUAuth
```


```bash
── applications
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

__OSDU Core Structure__

The OSDU Core application is organized to facilitate the management of the OSDU core platform services. Below is the layout:

```mermaid
flowchart TD
  base("base")
  partition("partition")
  partition_init("partition-init")
  entitlements("entitlements")
  entitlements_init("entitlements-init")
  legal("legal")
  indexer("indexer")
  indexer_queue("indexer-queue")
  user_init("user-init")
  schema("schema")
  schema_init("schema-init")
  storage("storage")
  file("file")
  search("search")

  base-->partition
  partition-->entitlements
  partition-->partition_init
  entitlements-->entitlements_init
  entitlements_init-->user_init
  partition-->legal
  legal-->indexer
  legal-->indexer_queue
  legal-->schema
  schema-->schema_init
  indexer_queue-->storage
  indexer_queue-->file
  indexer_queue-->search
```

```bash
── osdu-core
   ├── base.yaml
   ├── entitlements.yaml
   ├── file.yaml
   ├── indexer.yaml
   ├── legal.yaml
   ├── namespace.yaml
   ├── partition.yaml
   ├── schema.yaml
   ├── search.yaml
   ├── storage.yaml
   └── user-init.yaml
```

__OSDU Reference Structure__

The OSDU Reference application is organized to facilitate the management of the OSDU reference platform services. Below is the layout:

```mermaid
flowchart TD
  base("base")
  unit("unit")
  crs-catalog("crs-catalog")
  crs-conversion("crs-conversion")

  base-->unit
  base-->crs-catalog
  base-->crs-conversion
```

```bash
── osdu-reference
   ├── base.yaml
   ├── crs-catalog.yaml
   ├── crs-conversion.yaml
   ├── namespace.yaml
   └── unit.yaml
```