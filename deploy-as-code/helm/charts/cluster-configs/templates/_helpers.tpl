{{/*
Generate certificates when the secret doesn't exist
*/}}
{{- define "elasticsearch.gen-certs" -}}

{{- $name := index $.Values "cluster-configs" "secrets" "elasticsearch-certificate" "name" -}}
{{- $esService := index $.Values "cluster-configs" "secrets" "elasticsearch-certificate" "esService" -}}
{{- $esNamespace := index $.Values "cluster-configs" "secrets" "elasticsearch-certificate" "esNamespace" -}}

{{- $certs := lookup "v1" "Secret" $esNamespace $name -}}
{{- if $certs -}}
# Secret already exists, using existing certificates
tls.crt: {{ index $certs.data "tls.crt" | quote }}
tls.key: {{ index $certs.data "tls.key" | quote }}
ca.crt: {{ index $certs.data "ca.crt" | quote }}
{{- else -}}
# Secret doesn't exist, generating new certificates
{{- $altNames := list $esService ( printf "%s.%s" $esService $esNamespace ) ( printf "%s.%s.svc" $esService $esNamespace ) -}}
{{- $ca := genCA "elasticsearch-ca" 365 -}}
{{- $cert := genSignedCert $esService nil $altNames 365 $ca -}}
tls.crt: {{ $cert.Cert | toString | b64enc | quote }}
tls.key: {{ $cert.Key | toString | b64enc | quote }}
ca.crt: {{ $ca.Cert | toString | b64enc | quote }}
{{- end -}}
{{- end -}}
