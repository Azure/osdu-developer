{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "osdu-developer-init.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "osdu-developer-init.fullname" -}}
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
{{- define "osdu-developer-init.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "osdu-developer-init.labels" -}}
helm.sh/chart: {{ include "osdu-developer-init.chart" . }}
{{ include "osdu-developer-init.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "osdu-developer-init.selectorLabels" -}}
app.kubernetes.io/name: {{ include "osdu-developer-init.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Determine if the installation type is enabled
*/}}
{{- define "osdu-developer-init.isEnabled" -}}
  {{- $installationType := .Values.installationType | default "osduCore" -}}
  {{- if eq $installationType "osduReference" -}}
    {{- if hasKey .Values "osduReferenceEnabled" -}}
      {{- if eq .Values.osduReferenceEnabled "true" }}1{{else}}0{{end -}}
    {{- else -}}
      {{- 0 -}}
    {{- end -}}
  {{- else if eq $installationType "osduCore" -}}
    {{- if hasKey .Values "osduCoreEnabled" -}}
      {{- if eq .Values.osduCoreEnabled "true" }}1{{else}}0{{end -}}
    {{- else -}}
      {{- 0 -}}
    {{- end -}}
  {{- else -}}
    {{- 0 -}}
  {{- end -}}
{{- end }}