Helm meta-templating
====================

In the previous section, we created `app/templates/deployment.yaml` and `app/templates/service.yaml`. On closer inspection, we find that the `metadata.labels` section of both these files are identical.  We can eliminate this duplication using a [named template](https://helm.sh/docs/chart_template_guide/named_templates/), also known as a *subtemplate*.


```{note}
The files for this section are located at <https://github.com/yinchi/k8s-docs/tree/main/helm-kanban-v2>.
```

## `_helpers.tpl`

Create a `_helpers.tpl` file as follows:

```{code-block} yaml
:caption: templates/_helpers.tpl

{{/*
Global full name of the chart. In case if a variable exceeds 63 characters the remaining part will be cut-off, as some Kubernetes name fields are not allowing for a longer text. 
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
```

In the first portion above, we define `app.fullName` to be either the value of `app.name` if defined, or the release name otherwise. We also apply some operations to the app name to ensure it is no longer than 63 characters.

In the second portion above, we define `app.labels` to contain the template we wish to insert into our deployment and service YAML files.  The new versions of these files are as follows:

```{code-block} yaml
:caption: app/templates/deployment.yaml
:emphasize-lines: 4,6,11,15,18

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app.fullName" . }}
  labels: {{ include "app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.app.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "app.fullName" . }}
  template:
    metadata:
      labels: {{ include "app.labels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ include "app.fullName" . }}
          {{- with .Values.app.container }}
          image: {{ .image }}  
          ports:
            - containerPort: {{ .port }}
          {{- end }}
          {{- if .Values.app.container.env }}
          env:
            {{- range $key, $val := .Values.app.container.env}}
            - name: {{ $key }}
              value: {{ $val | quote }}
            {{- end}}
          {{- else }}
          env: {}
          {{- end }}
```

Here, we:

- replaced `indent` with `nindent`, which adds a newline before including the indented block
- used a `with` directive to avoid repeating long variable prefixes
- used `$key` and `$val` in our range loop to simplify the definition of key-value pairs in our `kanban-backend.yaml` file

```{code-block} yaml
:caption: app/templates/service.yaml
:emphasize-lines: 4,6,10

apiVersion: v1
kind: Service
metadata:
  name: {{ include "app.fullName" . }}
  labels: 
{{ include "app.labels" . | indent 4 }}
spec:
  type: {{ .Values.app.service.type }}
  selector:             
    app: {{ include "app.fullName" . }}
  ports:
    - port: {{ .Values.app.service.port }}       
      targetPort: {{ .Values.app.container.port }}
```

```{code-block} yaml
:caption: kanban-backend.yaml
:emphasize-lines: 4,6,10

app:
  name: kanban-backend
  group: backend
  container:
    image: wkrzywiec/kanban-app:helm-course
    env: 
      DB_SERVER: postgres
      POSTGRES_DB: kanban
      POSTGRES_USER: kanban
      POSTGRES_PASSWORD: kanban
```

## Extra: adding a `NOTES.txt` file

The `NOTES.txt` file is shown if present when installing or upgrading a Helm chart and also supports the Go template syntax.

```{code-block} txt
:caption: NOTES.txt

### 
######

{{ .Release.Name }}, version: {{ .Release.Revision }} has been installed, based on "app" Helm Chart!

Here is a short summary of installed application:

Docker base image: {{ .Values.app.container.image }}
Instances count: {{ .Values.app.replicaCount }}


######

Useful commands:

To list all Kubernetes resources created in this {{ .Release.Name }} Release:

    > kubectl get all --namespace {{ .Release.Namespace }} -l app.kubernetes.io/version={{ .Release.Name }}-{{ .Release.Revision }}

{{- if contains "ClusterIP" .Values.app.service.type }}

To establish connection with your app:

    > kubectl port-forward svc/{{ include "app.fullName" . }} {{ .Values.app.service.port }}:{{ .Values.app.service.port }} --namespace {{ .Release.Namespace }} 

After that, it will be reachable at the address http://localhost:8080

{{- end}}

######
###
```

## Deployment

```console
$ helm upgrade postgres bitnami/postgresql -n kanban \
  --create-namespace --install --values postgres.yaml
Release "postgres" does not exist. Installing it now.
NAME: postgres
LAST DEPLOYED: Tue Aug  6 22:16:35 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: postgresql
CHART VERSION: 15.5.20
APP VERSION: 16.3.0

** Please be patient while the chart is being deployed **

PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    postgres.kanban.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_ADMIN_PASSWORD=$(kubectl get secret --namespace kanban postgres -o jsonpath="{.data.postgres-password}" | base64 -d)

To get the password for "kanban" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace kanban postgres -o jsonpath="{.data.password}" | base64 -d)

To connect to your database run the following command:

    kubectl run postgres-client --rm --tty -i --restart='Never' --namespace kanban --image docker.io/bitnami/postgresql:16.3.0-debian-12-r23 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgres -U kanban -d kanban -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace kanban svc/postgres 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U kanban -d kanban -p 5432

WARNING: The configured password will be ignored on new installation in case when previous PostgreSQL release was deleted through the helm command. In that case, old PVC will have an old password, and setting it through helm won't take effect. Deleting persistent volumes (PVs) will solve the issue.

WARNING: There are "resources" sections in the chart not set. Using "resourcesPreset" is not recommended for production. For production installations, please set the following values according to your workload needs:
  - primary.resources
  - readReplicas.resources
+info https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
```

```console
$ helm upgrade kanban-backend ./app -n kanban \
  --create-namespace --install --values kanban-backend.yaml
Release "kanban-backend" does not exist. Installing it now.
NAME: kanban-backend
LAST DEPLOYED: Tue Aug  6 22:17:05 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
###
######

kanban-backend, version: 1 has been installed, based on "app" Helm Chart!

Here is a short summary of installed application:

Docker base image: wkrzywiec/kanban-app:helm-course
Instances count: 1


######

Useful commands:

To list all Kubernetes resources created in this kanban-backend Release:

    > kubectl get all --namespace kanban -l app.kubernetes.io/version=kanban-backend-1

To establish connection with your app:

    > kubectl port-forward svc/kanban-backend 8080:8080 --namespace kanban

After that it will be reachable at the address http://localhost:8080

######
###
```

```console
$ helm upgrade kanban-frontend ./app -n kanban \
  --create-namespace --install --values kanban-frontend.yaml
Release "kanban-frontend" does not exist. Installing it now.
NAME: kanban-frontend
LAST DEPLOYED: Tue Aug  6 22:17:38 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
###
######

kanban-frontend, version: 1 has been installed, based on "app" Helm Chart!

Here is a short summary of installed application:

Docker base image: wkrzywiec/kanban-ui:helm-course
Instances count: 1


######

Useful commands:

To list all Kubernetes resources created in this kanban-frontend Release:

    > kubectl get all --namespace kanban -l app.kubernetes.io/version=kanban-frontend-1

To establish connection with your app:

    > kubectl port-forward svc/kanban-frontend 8080:8080 --namespace kanban

After that it will be reachable at the address http://localhost:8080

######
###
```

```console
$ kubectl get pods -n kanban
NAME                               READY   STATUS    RESTARTS   AGE
kanban-backend-5b74677597-z8k2h    1/1     Running   0          54s
kanban-frontend-775cb9c6f5-sjcwt   1/1     Running   0          21s
postgres-0                         1/1     Running   0          84s
$ kubectl port-forward svc/kanban-frontend 8081:8080 -n kanban
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
Handling connection for 8081
$ helm uninstall kanban-frontend -n kanban && \
  helm uninstall kanban-backend -n kanban && \
  helm uninstall postgres -n kanban && \
  kubectl delete ns kanban
release "kanban-frontend" uninstalled
release "kanban-backend" uninstalled
release "postgres" uninstalled
namespace "kanban" deleted
```
