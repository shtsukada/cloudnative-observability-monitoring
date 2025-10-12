{{- define "cno-mon.name" -}}
monitoring-stack
{{- end }}

{{- define "cno-mon.fullname" -}}
{{ include "cno-mon.name" . }}
{{- end }}

{{- define "cno-mon.labels" -}}
app.kubernetes.io/name: {{ include "cno-mon.fullname" . }}
app.kubernetes.io/part-of: cloudnative-observability
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
