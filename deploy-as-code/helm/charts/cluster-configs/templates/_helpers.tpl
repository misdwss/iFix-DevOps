{{/*
Generate certificates when the secret doesn't exist
*/}}
{{- define "elasticsearch.gen-certs" -}}

{{- $ns := .namespace -}}
{{- $name := .Values.cluster-config.secrets.elasticsearch-certificate.name -}}
{{- $esService := .Values.cluster-config.secrets.elasticsearch-certificate.esService -}}
{{- $esNamespace := .Values.cluster-config.secrets.elasticsearch-certificate.esNamespace -}}

{{- $certs := lookup "v1" "Secret" $ns ( printf "%s-certs" $name ) -}}
{{- if $certs -}}
tls.crt: {{ index $certs.data "tls.crt" }}
tls.key: {{ index $certs.data "tls.key" }}
ca.crt: {{ index $certs.data "ca.crt" }}
{{- else -}}
{{- $altNames := list $esService ( printf "%s.%s" $esService $esNamespace ) ( printf "%s.%s.svc" $esService $esNamespace ) -}}
{{- $ca := genCA "elasticsearch-ca" 365 -}}
{{- $cert := genSignedCert $esService nil $altNames 365 $ca -}}
tls.crt: {{ $cert.Cert | toString | b64enc }}
tls.key: {{ $cert.Key | toString | b64enc }}
ca.crt: {{ $ca.Cert | toString | b64enc }}
{{- end -}}
{{- end -}}
