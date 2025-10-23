{{/*
Name helpers (monitoring-stack.*)
*/}}
{{- define "monitoring-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "monitoring-stack.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "monitoring-stack.name" . -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "monitoring-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Standard labels (monitoring-stack.*)
*/}}
{{- define "monitoring-stack.labels" -}}
app.kubernetes.io/name: {{ include "monitoring-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: cloudnative-observability
helm.sh/chart: {{ include "monitoring-stack.chart" . }}
{{- end -}}

{{/*
Backward-compatible aliases (cno-mon.*) — map to monitoring-stack.*
*/}}
{{- define "cno-mon.name" -}}
{{- include "monitoring-stack.name" . -}}
{{- end -}}

{{- define "cno-mon.fullname" -}}
{{- include "monitoring-stack.fullname" . -}}
{{- end -}}

{{- define "cno-mon.labels" -}}
{{- include "monitoring-stack.labels" . -}}
{{- end -}}
