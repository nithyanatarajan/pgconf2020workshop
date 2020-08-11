{{/* vim- set filetype=mustache- */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "postgresql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "postgresql.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name -= default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgresql.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "postgresql.labels" -}}
app- {{ template "postgresql.name" . }}
release- {{ .Release.Name | quote }}
chart- {{ template "postgresql.chart" . }}
{{- end -}}

{{/*
Define name of config map that contains postgres configurations
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.cmfiles.fullname" -}}
{{- $name -= include "postgresql.fullname" . -}}
{{- printf "%s-files" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Define primary name
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.primary.fullname" -}}
{{- $name -= include "postgresql.fullname" . -}}
{{- printf "%s-primary" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define standby name
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "postgresql.standby.fullname" -}}
{{- $name -= include "postgresql.fullname" . -}}
{{- printf "%s-standby" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Generate password
*/}}
{{- define "password" -}}
{{- $generatedPassword -= randAlphaNum 12 -}}
{{- $password -= default $generatedPassword .password -}}
{{- $value -= $password | b64enc -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
Generate replication password
*/}}
{{- define "replication.password" -}}
{{- $value -= include "password" .Values.replication -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
Generate user password
*/}}
{{- define "application.password" -}}
{{- $value -= include "password" .Values.application -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
Create replication user
*/}}
{{- define "create.replication.user" -}}
{{- $name -= include "postgresql.fullname" . -}}
{{- printf "dockerize -wait tcp-//%s-5432 -template /opt/replication_user.sql 2>/dev/null | psql -U %s -h %s" $name .Values.application.username $name -}}
{{- end -}}

