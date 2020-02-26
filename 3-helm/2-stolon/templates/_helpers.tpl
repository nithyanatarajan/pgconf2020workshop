{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "stolon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "stolon.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
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
{{- define "stolon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Default labels
*/}}
{{- define "stolon.labels" -}}
{{ include "stolon.selectorLabels" . }}
heritage: {{ .Release.Service | quote }}
chart: {{ template "stolon.chart" . }}
{{- end -}}

{{/*
Default selector labels
*/}}
{{- define "stolon.selectorLabels" -}}
app: {{ template "stolon.fullname" . }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "exporter.fullname" -}}
{{- $name := include "stolon.fullname" . -}}
{{- printf "%s-exporter" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "keeper.fullname" -}}
{{- $name := include "stolon.fullname" . -}}
{{- printf "%s-keeper" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "sentinel.fullname" -}}
{{- $name := include "stolon.fullname" . -}}
{{- printf "%s-sentinel" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "proxy.fullname" -}}
{{- $name := include "stolon.fullname" . -}}
{{- printf "%s-proxy" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Get the Stolon cluster name. It can be namespaced if needed by setting .Values.stolon.namespaced
*/}}
{{- define "stolonctl.clustername" -}}
{{- $name := include "stolon.fullname" . -}}
{{- if .Values.stolon.namespaced -}}
    {{- printf "%s-%s" $name .Release.Namespace -}}
{{- else -}}
    {{- printf "%s" $name -}}
{{- end -}}
{{- end -}}

{{/*
Store backend
*/}}
{{- define "store.backend" -}}
{{- printf "%s" .Values.store.backend.type -}}
{{- end -}}

{{/*
Store endpoint
*/}}
{{- define "store.endpoint" -}}
{{- $name := required "Provide a store endpoint" .Values.store.backend.endpoint -}}
{{- printf "%s" $name -}}
{{- end -}}

{{/*
Store backend health URL
*/}}
{{- define "store.backend.healthURL" -}}
{{- $backend := include "store.backend" . -}}
{{- $endpoint :=  include "store.endpoint" . -}}
{{- if eq $backend "consul" -}}
    {{- printf "%s/v1/status/leader" $endpoint -}}
{{- else if eq $backend "etcdv3" -}}
    {{- printf "%s/health" $endpoint -}}
{{- else if eq $backend "etcdv2" -}}
    {{- printf "%s/health" $endpoint -}}
{{- else if eq $backend "etcd" -}}
    {{- printf "%s/health" $endpoint -}}
{{- end -}}
{{- end -}}


{{/*
Get cluster specification
*/}}
{{- define "cluster.specification.json" -}}
{{- $clusterSpecification := .Values.stolon.clusterSpecification -}}
{{- if .Values.standby.enabled -}}
    {{- $remoteHost := required "Provide remote host address" .Values.standby.remoteHost -}}
    {{- $primarySlotName := required "Provide primary replication slot name" .Values.standby.primarySlotName -}}
    {{- $remoteReplUser := required "Provide remote replication username" .Values.postgres.replication.username -}}
    {{- $remoteReplPassword := required "Provide remote replication password" .Values.postgres.replication.password -}}
    {{- $passwordFilePath := include "standby.passwordfile.path" . -}}

    {{- $standBySpecTemplate := "" }}
    {{- $standBySpecAsJson := "" }}

    {{- $standBySpecTemplate = .Files.Get "files/standby-spec.json" }}
    {{- $standBySpecAsJson = printf $standBySpecTemplate $passwordFilePath "%d" $remoteHost $remoteReplUser $primarySlotName $remoteHost $remoteReplUser $remoteReplPassword $primarySlotName -}}

    {{- if $clusterSpecification -}}
        {{- $extraSpecAsMap := $clusterSpecification | toJson | fromJson -}}
        {{- $standBySpecAsMap := fromJson $standBySpecAsJson -}}
        {{- merge $standBySpecAsMap $extraSpecAsMap | toJson -}}
    {{- else -}}
        {{- $standBySpecAsJson -}}
    {{- end -}}
{{- else if $clusterSpecification -}}
    {{- toJson $clusterSpecification -}}
{{- end -}}
{{- end -}}


{{/*
Get cluster specification on initializations
*/}}
{{- define "cluster.init-specification.json" -}}
    {{- $initModeSpecMap := fromJson "{\"initMode\":\"new\"}" -}}
    {{- $clusterSpecification := include "cluster.specification.json" . -}}
    {{- if $clusterSpecification -}}
        {{- $clusterSpecificationMap := fromJson $clusterSpecification -}}
        {{- merge $clusterSpecificationMap $initModeSpecMap | toJson -}}
    {{- else -}}
        {{- toJson $initModeSpecMap -}}
    {{- end -}}
{{- end -}}

{{/*
Generate password
*/}}
{{- define "password" -}}
{{- $generatedPassword := randAlphaNum 12 -}}
{{- $password := default $generatedPassword .password -}}
{{- $value := $password | b64enc -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
Generate replication password
*/}}
{{- define "replication.password" -}}
{{- $value := include "password" .Values.postgres.replication -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
Generate user password
*/}}
{{- define "application.password" -}}
{{- $value := include "password" .Values.postgres.application -}}
{{- printf "%s" $value -}}
{{- end -}}

{{/*
pg_basebackup password file location
*/}}
{{- define "standby.passwordfile.path" -}}
{{- printf "/home/stolon/standbypassword" -}}
{{- end -}}

{{/*
pg_basebackup password file content
*/}}
{{- define "standby.passwordfile.content" -}}
{{- printf "%s:%d:*:%s:%s" .Values.standby.remoteHost 5432 .Values.postgres.replication.username .Values.postgres.replication.password | b64enc -}}
{{- end -}}

{{/*
Generate db connection string
*/}}
{{- define "application.connectionString" -}}
{{- $host := include "stolon.fullname" . -}}
{{- printf "postgresql://%s:%s@%s:%s/%s?sslmode=%s" .Values.postgres.application.username .Values.postgres.application.password $host "5432" .Values.postgres.application.dbname "disable" | b64enc -}}
{{- end -}}
