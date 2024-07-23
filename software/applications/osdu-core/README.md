# Software Installation Sequence

```mermaid
flowchart TD
  osdu_developer_base("osdu-developer-base")
  partition("partition")
  osdu_init_partition("osdu-init-partition")
  entitlements("entitlements")
  osdu_init_entitlements("osdu-init-entitlements")
  legal("legal")
  indexer_service("indexer-service")
  indexer_queue("indexer-queue")
  osdu_init_users("osdu-init-users")
  schema_service("schema-service")
  osdu_init_schema("osdu-init-schema")
  storage("storage")
  file("file")
  search("search")

  osdu_developer_base-->partition
  partition-->entitlements
  partition-->osdu_init_partition
  entitlements-->osdu_init_entitlements
  osdu_init_partition-->osdu_init_entitlements
  osdu_init_entitlements-->legal
  legal-->indexer_service
  legal-->indexer_queue
  osdu_init_entitlements-->osdu_init_users
  indexer_service-->schema_service
  indexer_queue-->schema_service
  schema_service-->osdu_init_schema
  schema_service-->storage
  schema_service-->file
  storage-->search
  file-->search
```