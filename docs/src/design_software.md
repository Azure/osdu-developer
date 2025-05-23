# Software

The OSDU™ private instance design utilizes a stamp-based pattern for software deployment, complementing the infrastructure design. This approach enables adheres to the principles of independent deployment of stamps with varying software configurations.

## Key Concepts

<div class="grid cards" markdown>

- :material-view-grid-outline:{ .lg .middle } __Stamp__: A complete, independent softwaredeployment of the OSDU platform
- :material-puzzle-outline:{ .lg .middle } __Components__: Middleware layers providing essential services to support OSDU Services
- :material-application-brackets:{ .lg .middle } __Applications__: OSDU platform services organized into logical groups of capabilities

</div>

## Software Layout

In our software architecture design, we define three primary software Kustomizations that describe the **stamp**. A Kustomization is a Flux resource representing a set of defined manifests that Flux should reconcile to the cluster, with dependencies between them.

```mermaid
flowchart TD
  FluxSystemComponents("flux-system-components")
  FluxSystemApplications("flux-system-applications")
  FluxSystemExperimental("flux-system-experimental")
  FluxSystemComponents-->FluxSystemApplications
  FluxSystemApplications-->FluxSystemExperimental
```

```bash
├── applications
│   └── kustomize.yaml
├── components
│   └── kustomize.yaml
└── experimental
    └── kustomize.yaml
```

## Components Structure

The Components directory is organized to facilitate the management of various middleware layers essential for our infrastructure. Components have dependency structures in the sequence of configuration, and a naming pattern is used to help facilitate understanding.

```mermaid
flowchart TD
  FluxSystemComponents("flux-system-components")
  Certs("component-certs")
  CertsCA("component-certs-ca")
  CertsCAIssuer("component-certs-issuer")
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
    ├── airflow
    │   ├── namespace.yaml
    │   ├── pvc.yaml
    │   ├── release.yaml
    │   ├── source.yaml
    │   └── vault-secrets.yaml
    ├── certs
    │   ├── namespace.yaml
    │   ├── release.yaml
    │   └── source.yaml
    ├── certs-ca
    │   └── certificate.yaml
    ├── certs-issuer
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

## Applications Structure

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

## OSDU Core Structure

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
  workflow("workflow")

  base-->partition
  partition-->entitlements
  partition-->partition_init
  entitlements-->entitlements_init
  entitlements_init-->user_init
  partition-->legal
  legal-->indexer
  legal-->indexer_queue
  legal-->schema
  legal-->workflow
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
   └── workflow.yaml
```

## OSDU Reference Structure

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


## Experimental Features

The Experimental directory is organized to facilitate the management of experimental features.

```mermaid
  flowchart TD
    FluxSystemExperimental("flux-system-experimental")
    ExperimentalBase("experimental-base")
    AdminUI("experimental-admin-ui")

    FluxSystemExperimental-->ExperimentalBase
    ExperimentalBase-->AdminUI
```

```bash
── experimental
   ├── admin-ui
   │   ├── README.md
   │   ├── ingress.yaml
   │   └── release.yaml
   └── experimental-base
       ├── namespace.yaml
       ├── osdu-base.yaml
       └── vault-secrets.yaml
```