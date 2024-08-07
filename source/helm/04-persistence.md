Data persistence
================

```{note}
The files for this section are located at <https://github.com/yinchi/k8s-docs/tree/main/helm-kanban-v2>.
```

To persist data in the PostgreSQL database in the kanban app (see the previous two sections), we need to define a **persistent volume**.  Before we do so, we also need to restart our K8s cluster with a bind mount between our host system and the K8s node:

```{code-block} yaml
:caption: db.yaml

kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /home/yinchi/k8s-docs/helm-kanban-v2/mnt/bitnami/postgresql
    containerPath: /bitnami/postgresql
```

```{note}
We are using the default database location for the PostgreSQL Helm chart for our `containerPath`.  This is controlled by the `primary.persistence.mountPath`. If we had a multinode setup, we would also need to configure `readReplicas.persistence.mountPath`. 
```

We provide the above configuration when starting up our Kind cluster:

```console
$ kind create cluster --config db.yaml
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.30.0) 🖼
 ✓ Preparing nodes 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```

## The persistent volume and claim

Create the following YAML file:

```{code-block} yaml
:caption: pv-volume.yaml
:emphasize-lines: 14

apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-volume
  labels:
    type: local
spec:
  storageClassName: ""
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/bitnami/postgresql"
  claimRef:
    name: pv-claim
    namespace: kanban
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-claim
  namespace: kanban
spec:
  storageClassName: ""
  volumeName: pv-volume
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

Note that the `claimRef` and `volumeName` above are designed to ensure that the PersistentVolumeClaim and PersistentVolume can only claim/be claimed by each other. Apply the above file to the cluster:

```console
$ kubectl create ns kanban
namespace/kanban created
$ kubectl apply -f pv-volume.yaml -n kanban
persistentvolume/pv-volume configured
persistentvolumeclaim/pv-claim created
```

## Modifications to `postgres.yaml`

We supply some additional values to `postgres.yaml`:

```{code-block} yaml
:caption: postgres.yaml

fullnameOverride: "postgres"

auth:
  postgresPassword: "postgres"
  username: "kanban"
  password: "kanban"
  database: "kanban"

primary:
  persistence:
    existingClaim: "pv-claim"

volumePermissions:
  enabled: true
```

```console
$ helm upgrade postgres bitnami/postgresql -n kanban \
  --install --values postgres.yaml --wait --timeout 60s
Release "postgres" does not exist. Installing it now.
NAME: postgres
LAST DEPLOYED: Wed Aug  7 19:35:15 2024
NAMESPACE: kanban
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES: <remainder of output omitted>
```

The `primary.persistence.existingClaim` value links our database to our mounted directory on disk, while the `volumePermissions.enabled` value (`true`) sets grants read/write permissions for our directory to the PostgreSQL pod (which operates with user ID 1001 by default). We can check this by entering this command on our host machine:

```console
$ ls -lah mnt/bitnami/postgresql/
total 12K
drwxrwxr-x  3   1001 libvirtd 4.0K Aug  7 19:09 .
drwxrwxr-x  3 yinchi yinchi   4.0K Aug  7 18:09 ..
drwx------ 19   1001 libvirtd 4.0K Aug  7 19:10 data
```

Launch the backend and frontend as in previous sections:

```console
$ helm upgrade kanban-backend ./app -n kanban \
  --install --values kanban-backend.yaml
$ helm upgrade kanban-frontend ./app -n kanban \
  --install --values kanban-frontend.yaml
$ kubectl port-forward svc/kanban-frontend 8081:8080 -n kanban
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
```

Our kanban app should now be available as before.  Create a kanban with several tasks.  Next, try uninstalling and reinstalling the kanban app, but do not delete the namespace or persistent volume/volume claim:

```console
$ helm uninstall kanban-frontend kanban-backend postgres -n kanban
release "kanban-frontend" uninstalled
release "kanban-backend" uninstalled
release "postgres" uninstalled
$ helm upgrade postgres bitnami/postgresql -n kanban \
  --install --values postgres.yaml --wait --timeout 60s
$ helm upgrade kanban-backend ./app -n kanban \
  --install --values kanban-backend.yaml
$ helm upgrade kanban-frontend ./app -n kanban \
  --install --values kanban-frontend.yaml
$ kubectl port-forward svc/kanban-frontend 8081:8080 -n kanban
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
```

Your kanbans should be in the same state as before reinstalling the app.

## Lifecycle of a persistent volume

Our PersistentVolume has a policy of `Retain`, meaning its resources are kept even after the PersistentVolume is deleted:

```console
$ kubectl get pv
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-volume   10Gi       RWO            Retain           Bound    kanban/pv-claim                  <unset>                          5m46s
```

We can confirm this by destroying our app and checking the state of the files on disk:

```console
$ helm uninstall kanban-frontend kanban-backend postgres -n kanban
release "kanban-frontend" uninstalled
release "kanban-backend" uninstalled
release "postgres" uninstalled
$ kubectl delete ns/kanban
namespace "kanban" deleted
$ kubectl delete pv/pv-volume
persistentvolume "pv-volume" deleted
$ kind delete cluster
Deleting cluster "kind" ...
Deleted nodes: ["kind-control-plane"]
$ sudo ls mnt/bitnami/postgresql/data/ -1
base
global
pg_commit_ts
pg_dynshmem
pg_ident.conf
pg_logical
pg_multixact
pg_notify
pg_replslot
pg_serial
pg_snapshots
pg_stat
pg_stat_tmp
pg_subtrans
pg_tblspc
pg_twophase
PG_VERSION
pg_wal
pg_xact
postgresql.auto.conf
postmaster.opts
```

Our database files are still present. Recreate everything we need (output omitted for brevity):

```bash
kind create cluster
kubectl create ns kanban
kubectl apply -f pv-volume.yaml
helm upgrade postgres bitnami/postgresql -n kanban \
  --create-namespace --install --values postgres.yaml --wait --timeout 60s
helm upgrade kanban-backend ./app -n kanban --install --values kanban-backend.yaml
helm upgrade kanban-frontend ./app -n kanban --install --values kanban-frontend.yaml
kubectl port-forward svc/kanban-frontend 8081:8080 -n kanban
```

We can see our previously created kanbans in the app.