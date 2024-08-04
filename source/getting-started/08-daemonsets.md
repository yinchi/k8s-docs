Daemon sets
===========

A daemonset is similar to a deployment but is restricted to one replica per node.  First, let us create a multinode cluster:

```console
$ minikube start -n 3
😄  minikube v1.33.1 on Ubuntu 24.04
✨  Automatically selected the docker driver. Other choices: kvm2, virtualbox, ssh
📌  Using Docker driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.44 ...
🔥  Creating docker container (CPUs=2, Memory=2600MB) ...
🐳  Preparing Kubernetes v1.30.0 on Docker 26.1.1 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass

👍  Starting "minikube-m02" worker node in "minikube" cluster
🚜  Pulling base image v0.0.44 ...
🔥  Creating docker container (CPUs=2, Memory=2600MB) ...
🌐  Found network options:
    ▪ NO_PROXY=192.168.49.2
🐳  Preparing Kubernetes v1.30.0 on Docker 26.1.1 ...
    ▪ env NO_PROXY=192.168.49.2
🔎  Verifying Kubernetes components...

👍  Starting "minikube-m03" worker node in "minikube" cluster
🚜  Pulling base image v0.0.44 ...
🔥  Creating docker container (CPUs=2, Memory=2600MB) ...
🌐  Found network options:
    ▪ NO_PROXY=192.168.49.2,192.168.49.3
🐳  Preparing Kubernetes v1.30.0 on Docker 26.1.1 ...
    ▪ env NO_PROXY=192.168.49.2
    ▪ env NO_PROXY=192.168.49.2,192.168.49.3
🔎  Verifying Kubernetes components...
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
$ kubectl get nodes -o wide
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
minikube       Ready    control-plane   83s   v1.30.0   192.168.49.2   <none>        Ubuntu 22.04.4 LTS   6.8.0-39-generic   docker://26.1.1
minikube-m02   Ready    <none>          62s   v1.30.0   192.168.49.3   <none>        Ubuntu 22.04.4 LTS   6.8.0-39-generic   docker://26.1.1
minikube-m03   Ready    <none>          53s   v1.30.0   192.168.49.4   <none>        Ubuntu 22.04.4 LTS   6.8.0-39-generic   docker://26.1.1
```

We can see Minikube's internal DaemonSets using the `-A` flag:

```console
kubectl get ds -A
NAMESPACE     NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   kindnet      3         3         3       3            3           <none>                   98s
kube-system   kube-proxy   3         3         3       3            3           kubernetes.io/os=linux   99s
```

To see pod details for the `kindnet` DaemonSet:

```console
$ kubectl get pod -o wide --selector=app=kindnet -A
NAMESPACE     NAME            READY   STATUS    RESTARTS   AGE     IP             NODE           NOMINATED NODE   READINESS GATES
kube-system   kindnet-7pdfx   1/1     Running   0          9m18s   192.168.49.2   minikube       <none>           <none>
kube-system   kindnet-b4n7g   1/1     Running   0          9m4s    192.168.49.4   minikube-m03   <none>           <none>
kube-system   kindnet-r9hsh   1/1     Running   0          9m13s   192.168.49.3   minikube-m02   <none>           <none>
```

We can confirm that one `kindnet` pod is running on each node.

## Example YAML file

[fluentd](https://www.fluentd.org/architecture) is a tool for data log aggregation and processing.

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-agent
  namespace: default
  labels:
    k8s-app: fluentd-agent
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-agent
  template:
    metadata:
      labels:
        k8s-app: fluentd-agent
    spec:
      containers:
      - name: fluentd
        image: quay.io/fluentd_elasticsearch/fluentd:v4.9.0
```

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
#highlight metadata/labels/k8s-app
#highlight spec/selector/matchLabels/k8s-app
#highlight spec/template/metadata/labels/k8s-app

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-agent
  namespace: default
  labels:
    k8s-app: fluentd-agent
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-agent
  template:
    metadata:
      labels:
        k8s-app: fluentd-agent
    spec:
      containers:
      - name: fluentd
        image: quay.io/fluentd_elasticsearch/fluentd:v4.9.0
@endyaml
```