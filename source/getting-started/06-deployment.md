Deployments
===========

Deployments use **replica sets** of one or more pods to host an application. They also support versioning via rollouts and rollbacks.

:::{figure} /_static/images/k8s-deployment.png

Image source: <http://wiki.ciscolinux.co.uk/index.php/Kubernetes/Deployment,_ReplicaSet_and_Pod>
:::

## Example: Multi-pod Nginx deployment

```bash
kubectl create deploy nginx-deployment -r 3 \
--image=nginx:1.27.0-bookworm --port=80 --dry-run=client \
-o yaml | tee nginx-deployment.yaml | yq
```

:::{code-block} yaml
:caption: nginx-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-deployment
    spec:
      containers:
        - image: nginx:1.27.0-bookworm
          name: nginx
          ports:
            - containerPort: 80
          resources: {}
status: {}
:::

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
#highlight metadata/labels/app
#highlight spec/selector/matchLabels/app
#highlight spec/template/metadata/labels/app

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: nginx-deployment
    spec:
      containers:
        - image: nginx:1.27.0-bookworm
          name: nginx
          ports:
            - containerPort: 80
          resources: {}
status: {}
@endyaml
```

## Creating the deployment

```console
$ kubectl create -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
$ kubectl get svc,deploy,rs,pod
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   7h50m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   3/3     3            3           8s

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-d64d454c6   3         3         3       8s

NAME                                   READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-d64d454c6-cc8p7   1/1     Running   0          8s
pod/nginx-deployment-d64d454c6-rzqz2   1/1     Running   0          8s
pod/nginx-deployment-d64d454c6-sw9hh   1/1     Running   0          8s
$ kubectl get deploy nginx-deployment -o yaml | yq -C | less -R
$ kubectl describe deploy nginx-deployment
Name:                   nginx-deployment
Namespace:              default
CreationTimestamp:      Fri, 02 Aug 2024 23:40:54 +0100
Labels:                 app=nginx-deployment
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=nginx-deployment
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx-deployment
  Containers:
   nginx:
    Image:         nginx:1.27.0-bookworm
    Port:          80/TCP
    Host Port:     0/TCP
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deployment-d64d454c6 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  3m5s  deployment-controller  Scaled up replica set nginx-deployment-d64d454c6 to 3
```

## Exposing the deployment

To expose `nginx-deployment`, we can use `kubectl expose` to create a service from the deployment. Then, use `minikube tunnel` to expose the necessary ports:

```console
$ kubectl expose deployment nginx-deployment --type=LoadBalancer --port=8000 --target-port=80
service/nginx-deployment exposed
$ kubectl get svc
NAME               TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
kubernetes         ClusterIP      10.96.0.1     <none>        443/TCP          7h16m
nginx-deployment   LoadBalancer   10.100.8.61   <pending>     8000:32200/TCP   35s
$ minikube tunnel --bind-address "0.0.0.0"
✅  Tunnel successfully started

📌  NOTE: Please do not close this terminal as this process must stay alive for the tunnel to be accessible ...

🏃  Starting tunnel for service nginx-deployment.
```

The service can now be accessed from a the host or a remote machine.

![](/_static/images/minikube-tunnel.png)

## Deleting the service and deployment

```console
$ kubectl delete svc nginx-deployment
service "nginx-deployment" deleted

$ kubectl delete deploy nginx-deployment
deployment.apps "nginx-deployment" deleted

$ kubectl get svc,deploy,rs,pod
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8h
```

All of the ReplicaSets and pods associated with the deployment have also been deleted.