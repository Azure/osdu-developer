{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "airflow-dags.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "airflow-dags.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "airflow-dags.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "airflow-dags.labels" -}}
helm.sh/chart: {{ include "airflow-dags.chart" . }}
{{ include "airflow-dags.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "airflow-dags.selectorLabels" -}}
app.kubernetes.io/name: {{ include "airflow-dags.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Search and Replace Configuration
*/}}
{{- define "airflow-dags.searchAndReplace" -}}
[
  {
    "find": "{| K8S_POD_OPERATOR_KWARGS or {} |}",
    "replace": {
      "annotations": {
        "sidecar.istio.io/inject": "false"
      },
      "labels": {
        "aadpodidbinding": "osdu-identity"
      }
    }
  },
  {
    "find": "{| ENV_VARS or {} |}",
    "replace": {
      "AZURE_CLIENT_ID": {{ .Values.clientId | default "" | quote }},
      "AZURE_CLIENT_SECRET": {{ .Values.secrets.airflowSecrets.clientKey | default "" | quote }},
      "AZURE_TENANT_ID": {{ .Values.tenantId | default "" | quote }},
      "KEYVAULT_URI": {{ .Values.keyvaultUri | default "" | quote }},
      "aad_client_id": {{ .Values.clientId | default "" | quote }},
      "appinsights_key": {{ .Values.secrets.airflowSecrets.insightsKey | default "" | quote }},
      "azure_paas_podidentity_isEnabled": "false",
      "file_service_endpoint": "http://file.osdu-core.svc.cluster.local/api/file/v2",
      "partition_service_endpoint": "http://partition.osdu-core.svc.cluster.local/api/partition/v1",
      "schema_service_endpoint": "http://schema.osdu-core.svc.cluster.local/api/schema-service/v1",
      "search_service_endpoint": "http://search.osdu-core.svc.cluster.local/api/search/v2",
      "storage_service_endpoint": "http://storage.osdu-core.svc.cluster.local/api/storage/v2",
      "unit_service_endpoint": "http://unit.osdu-core.svc.cluster.local/api/unit/v2/unit/symbol"
    }
  },
  {
    "find": "{| DAG_NAME |}", 
    "replace": "csv-parser"
  },
  {
    "find": "{| DOCKER_IMAGE |}", 
    "replace": "community.opengroup.org:5555/osdu/platform/data-flow/ingestion/csv-parser/csv-parser-v0-27-0-azure-1:60747714ac490be0defe8f3e821497b3cce03390"
  },
  {
    "find": "{| NAMESPACE |}", 
    "replace": "airflow"
  }
]
{{- end }}