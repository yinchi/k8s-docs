Creating a Custom Helm Chart
============================

We want to create the following resources:

{emphasize-lines="4,6,12,16,20,38,44"}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kanban-app
  labels:
    app: kanban-app
    group: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kanban-app
  template:
    metadata:
      labels:
        app: kanban-app
        group: backend
    spec:
      containers:
        - name: kanban-app
          image: wkrzywiec/kanban-app:helm-course
          ports:
            - containerPort: 8080
          env:
            - name: DB_SERVER
              value: postgres
            - name: POSTGRES_DB
              value: kanban
            - name: POSTGRES_USER
              value: kanban
            - name: POSTGRES_PASSWORD
              value: kanban

---
apiVersion: v1
kind: Service
metadata:
  name: kanban-app
  labels: 
    group: backend
spec:
  type: ClusterIP
  selector:
    app: kanban-app
  ports:
    - port: 8080
      targetPort: 8080
```

Note the repetitiveness of the YAML specification above.  Helm provides a way to declare resources using **templates**, thus allowing us to insert values into our YAML manifests.

First, create an new Helm chart:

```console
$ helm create app
Creating app
$ ls app
$ tree
.
├── Chart.yaml
├── charts
├── templates
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests
│       └── test-connection.yaml
└── values.yaml

4 directories, 10 files
$ rm -rf templates/
$ rm -rf charts/
$ tree
.
├── Chart.yaml
└── values.yaml

1 directory, 2 files
```

## Template files

```{code-block} yaml
:caption: app/templates/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
    app.kubernetes.io/name: {{ .Values.app.name }}
    app.kubernetes.io/version: {{ .Release.Name }}-{{ .Release.Revision }}
    group: {{ .Values.app.group }}
spec:
  replicas: {{ .Values.app.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
        group: {{ .Values.app.group }}
    spec:
      containers:
        - name: {{ .Values.app.name }}
          image: {{ .Values.app.container.image }}  
          ports:
            - containerPort: {{ .Values.app.container.port }}
          env:
            {{- range .Values.app.container.env}}
            - name: {{ .key}}
              value: {{ .value}}
            {{- end}}

```

```{code-block} yaml
:caption: app/templates/service.yaml

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
    app.kubernetes.io/name: {{ .Values.app.name }}
    app.kubernetes.io/version: {{ .Release.Name }}-{{ .Release.Revision }}
    group: {{ .Values.app.group }}
spec:
  type: {{ .Values.app.service.type }}
  selector:             
    app: {{ .Values.app.name }}
  ports:
    - port: {{ .Values.app.service.port }}       
      targetPort: {{ .Values.app.container.port }}    
```

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
<style>
    .g {
      BackGroundColor #ff8888
    }
</style>
#highlight metadata/name
#highlight metadata/labels/app
#highlight metadata/labels/app.kubernetes.io∕name
#highlight spec/selector/matchLabels/app
#highlight spec/template/metadata/labels/app
#highlight spec/template/spec/containers/0/name

#highlight metadata/labels/group <<g>>
#highlight spec/template/metadata/labels/group<<g>>

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
    app.kubernetes.io∕name: {{ .Values.app.name }}
    app.kubernetes.io∕version: {{ .Release.Name }}-{{ .Release.Revision }}
    group: {{ .Values.app.group }}
spec:
  replicas: {{ .Values.app.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Values.app.name }}
  template:
    metadata:
      labels:
        app: {{ .Values.app.name }}
        group: {{ .Values.app.group }}
    spec:
      containers:
        - name: {{ .Values.app.name }}
          image: {{ .Values.app.container.image }}  
          ports:
            - containerPort: {{ .Values.app.container.port }}
          env:
            {{- range .Values.app.container.env}}
            - name: {{ .key}}
              value: {{ .value}}
            {{- end}}
@endyaml
```
Note the leading dashes in the `range` and matching `end` directives are for trimming the whitespace surrounding the range output in case it is empty.

```{note}
The notation shown above is Go template notation.  For more information about its use in Helm, see the [official guide](https://helm.sh/docs/chart_template_guide/getting_started/).
```

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
<style>
    .g {
      BackGroundColor #ff8888
    }
</style>
#highlight metadata/name
#highlight metadata/labels/app
#highlight metadata/labels/app.kubernetes.io∕name
#highlight spec/selector/app

#highlight metadata/labels/group <<g>>

apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.app.name }}
  labels:
    app: {{ .Values.app.name }}
    app.kubernetes.io∕name: {{ .Values.app.name }}
    app.kubernetes.io/version: {{ .Release.Name }}-{{ .Release.Revision }}
    group: {{ .Values.app.group }}
spec:
  type: {{ .Values.app.service.type }}
  selector:             
    app: {{ .Values.app.name }}
  ports:
    - port: {{ .Values.app.service.port }}       
      targetPort: {{ .Values.app.container.port }}
@endyaml
```

## Providing default values

Here we provide default values for the template variables (prefix `.Values`) in the above chart files:

```{code-block} yaml
:caption: app/values.yaml

app:
  name: default-app-name
  group: default-app-group
  replicaCount: 1
  container:
    image: add-image-here
    port: 8080
    env: []
  service:
    type: ClusterIP
    port: 8080
```

## Using the `app` chart

To create an app based on the `app` chart, we take `app/values.yaml` as a basis and take only those values we want to override:

```{code-block} yaml
:caption: kanban-frontend.yaml

app:
  name: kanban-frontend
  group: frontend
  container:
    image: wkrzywiec/kanban-ui:helm-course
    port: 80
```

```{code-block} yaml
:caption: kanban-backend.yaml

app:
  name: kanban-backend
  group: backend
  container:
    image: wkrzywiec/kanban-app:helm-course
    env: 
      - key: DB_SERVER
        value: postgres
      - key: POSTGRES_DB
        value: kanban
      - key: POSTGRES_USER
        value: kanban
      - key: POSTGRES_PASSWORD
        value: kanban
```

## Providing a PostgreSQL backend for the app

Let us use the `bitnami/postgresql` Helm chart.  Since the README file is difficult to read in Markdown form, let us render it as HTML:

```bash
sudo apt install pandoc
helm show readme bitnami/postgresql | pandoc > postgres.README.html
xdg-open postgres.README.html
```

Scroll down to the Section titled `PostgreSQL common parameters`. We see that we need to edit the following parameters in the `auth` section. Let us also rename our deployment to "postgres":

```{code-block} yaml
:caption: postgres.yaml

fullnameOverride: "postgres"

auth:
  postgresPassword: "postgres"
  username: "kanban"
  password: "kanban"
  database: "kanban"
```

![](/_static/images/postgres-values.png)

## Files for this section

The files in this section are located at <https://github.com/yinchi/k8s-docs/tree/main/helm-kanban>.

## Deployment

### PostgreSQL

```console
$ helm upgrade postgres bitnami/postgresql -n kanban \
  --create-namespace --install \
  --values postgres.yaml
  Release "postgres" does not exist. Installing it now.
NAME: postgres
LAST DEPLOYED: Tue Aug  6 16:01:51 2024
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

### Backend and frontend

```console
$ helm upgrade kanban-backend ./app -n kanban \
  --create-namespace --install --values kanban-backend.yaml
Release "kanban-backend" does not exist. Installing it now.
NAME: kanban-backend
LAST DEPLOYED: Tue Aug  6 16:04:16 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

```console
$ helm upgrade kanban-frontend ./app -n kanban \
  --create-namespace --install --values kanban-frontend.yaml
Release "kanban-frontend" does not exist. Installing it now.
NAME: kanban-frontend
LAST DEPLOYED: Tue Aug  6 16:05:18 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

```console
$ kubectl get pods -n kanban
NAME                               READY   STATUS    RESTARTS   AGE
kanban-backend-7ccb67b4f6-w77vt    1/1     Running   0          80s
kanban-frontend-6d6f594768-4hkb6   1/1     Running   0          19s
postgres-0                         1/1     Running   0          3m45s
```

### Port-forwarding and final result

```console
$ kubectl port-forward svc/kanban-frontend 8081:8080 -n kanban
```

![](/_static/images/kanban.png)

```console
$ helm list -n kanban
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
kanban-backend  kanban          1               2024-08-06 16:04:16.951780019 +0100 BST deployed        app-0.1.0               0.1.0
kanban-frontend kanban          1               2024-08-06 16:05:18.574512032 +0100 BST deployed        app-0.1.0               0.1.0
postgres        kanban          1               2024-08-06 16:01:51.937806153 +0100 BST deployed        postgresql-15.5.20      16.3.0
$ kubectl get svc,pod -n kanban
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/kanban-backend    ClusterIP   10.96.92.143   <none>        8080/TCP   8m58s
service/kanban-frontend   ClusterIP   10.96.3.72     <none>        8080/TCP   7m57s
service/postgres          ClusterIP   10.96.33.122   <none>        5432/TCP   11m
service/postgres-hl       ClusterIP   None           <none>        5432/TCP   11m

NAME                                   READY   STATUS    RESTARTS   AGE
pod/kanban-backend-7ccb67b4f6-w77vt    1/1     Running   0          8m58s
pod/kanban-frontend-6d6f594768-4hkb6   1/1     Running   0          7m57s
pod/postgres-0                         1/1     Running   0          11m
```

## Cleanup

```console
$ helm uninstall kanban-frontend -n kanban && \
  helm uninstall kanban-backend -n kanban && \
  helm uninstall postgres -n kanban
release "kanban-frontend" uninstalled
release "kanban-backend" uninstalled
release "postgres" uninstalled
$ helm list -n kanban
NAME    NAMESPACE       REVISION        UPDATED STATUS  CHART   APP VERSION
$ kubectl get svc,pod -n kanban
No resources found in kanban namespace.
$ kubectl delete ns kanban
namespace "kanban" deleted
```