Volumes
=======

Volume types are described at <https://kubernetes.io/docs/concepts/storage/volumes/>

- An ephemeral volume is linked to a pod and has the same lifespan as the pod, but is preserved across container restarts. One example of this is the `empty` volume type.
- The `hostPath` volume type shares a directory between the host and the pod, similar to a bind mount in Docker.
- A config map is a section of a YAML file that is mounted into the pod.

Note that many of the volume types listed in the link above are deprecated in favor of the Container Storage Interface (CSI).

## HostPath Example

First, since Minikube is running in a Docker container, we need to mount our own filesystem into the Docker container:

```console
$ minikube mount $HOME:/hosthome
📁  Mounting host path /home/yinchi into VM as /hosthome ...
    ▪ Mount type:   9p
    ▪ User ID:      docker
    ▪ Group ID:     docker
    ▪ Version:      9p2000.L
    ▪ Message Size: 262144
    ▪ Options:      map[]
    ▪ Bind Address: 192.168.49.1:36877
🚀  Userspace file server: ufs starting
✅  Successfully mounted /home/yinchi to /hosthome

📌  NOTE: This process must stay alive for the mount to be accessible ...
```

Next, we define the paths for mounting from Minikube into our deployment's pod:

```{code-block} yaml
:caption: mydocs.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: mydocs
  name: mydocs
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mydocs
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: mydocs
    spec:
      volumes:
      - name: vol
        hostPath:
          path: /hosthome/k8s-docs/build/html
          type: Directory
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: vol
```

```{kroki}
:type: plantuml

@startuml
rectangle "Host machine" {
  folder "$HOME/k8s-docs/build/html" as home
  rectangle "Minikube Docker container" {
    folder "/hosthome/k8s-docs/build/html" as hosthome
    rectangle Node {
      rectangle Pod {
        folder "/usr/share/nginx/html" as pod
      }
    }
  }
}
home <--> hosthome : "  (minikube mount)"
hosthome <--> pod
@enduml
```

Finally, in a new terminal, apply the deployment, expose it as a service, and forward the appropiate port:

```console
$ kubectl create -f mydocs.yaml
deployment.apps/mydocs created
$ kubectl expose deploy mydocs --type=NodePort
service/mydocs exposed
$ kubectl port-forward --address 0.0.0.0,:: svc/mydocs 8000:80
Forwarding from 0.0.0.0:8000 -> 80
Forwarding from [::]:8000 -> 80
```

![](/_static/images/volumeMounts.png)

To verify that changes in the host filesystem are reflected in the pod, we can delete our files:

```console
(.venv)$ make clean
Removing everything under 'build'...
```

Reloading the site now should result in an error.