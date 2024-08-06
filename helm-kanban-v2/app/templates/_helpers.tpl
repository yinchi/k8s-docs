{{/*
Global full name of the chart. In case if a variable exceeds 63 characters the remaining part will
be cut-off, as some Kubernetes name fields are not allowing for a longer text. 
*/}}
{{- define "app.fullName" -}}
{{- default .Release.Name .Values.app.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generic labels for each Kubernetes resource
*/}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.fullName" . }}
app.kubernetes.io/version: {{ .Release.Name }}-{{ .Release.Revision }}
app: {{ include "app.fullName" . }}
group: {{ .Values.app.group }}
{{- end }}