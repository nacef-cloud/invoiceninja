{{/*
Expand the name of the chart.
*/}}
{{- define "invoiceninja.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "invoiceninja.fullname" -}}
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
{{- define "invoiceninja.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "invoiceninja.labels" -}}
helm.sh/chart: {{ include "invoiceninja.chart" . }}
{{ include "invoiceninja.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "invoiceninja.selectorLabels" -}}
app.kubernetes.io/name: {{ include "invoiceninja.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "invoiceninja.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "invoiceninja.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database host
*/}}
{{- define "invoiceninja.databaseHost" -}}
{{- if .Values.mysql.enabled }}
{{- printf "%s-mysql" .Release.Name }}
{{- else }}
{{- .Values.database.host }}
{{- end }}
{{- end }}

{{/*
Redis host
*/}}
{{- define "invoiceninja.redisHost" -}}
{{- if .Values.redis.enabled }}
{{- printf "%s-redis-master" .Release.Name }}
{{- else }}
{{- .Values.redis.host }}
{{- end }}
{{- end }}

{{/*
MinIO endpoint
*/}}
{{- define "invoiceninja.minioEndpoint" -}}
{{- if .Values.minio.enabled }}
{{- printf "http://%s-minio:9000" .Release.Name }}
{{- else }}
{{- .Values.storage.s3.endpoint }}
{{- end }}
{{- end }}

{{/*
Gotenberg URL
*/}}
{{- define "invoiceninja.gotenbergUrl" -}}
{{- if .Values.gotenberg.enabled }}
{{- printf "http://%s-gotenberg:3000" (include "invoiceninja.fullname" .) }}
{{- else }}
{{- .Values.pdf.gotenberg.url }}
{{- end }}
{{- end }}
