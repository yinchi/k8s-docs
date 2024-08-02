Pods
=====

Pods are the smallest unit of computing in Kubernetes. A pod contains one or more containers with shared storage and network resources.

## Example: a Nginx pod

The following YAML file defines a Nginx pod:

```bash
kubectl run nginx-pod --image=nginx:1.27.0-bookworm --port=80 \
--dry-run=client -o yaml | tee nginx-pod.yaml | yq
```

:::{code-block} yaml
:caption: nginx-pod.yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx-pod
  name: nginx-pod
spec:
  containers:
    - image: nginx:1.27.0-bookworm
      name: nginx-pod
      ports:
        - containerPort: 80
      resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
:::

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx-pod
  name: nginx-pod
spec:
  containers:
    - image: nginx:1.27.0-bookworm
      name: nginx-pod
      ports:
        - containerPort: 80
      resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
@endyaml
```

## Launching the pod

We can create the `nginx-pod` using `kubectl create` or `kubectl apply`.

```{list-table}
* - **Command**
  - **Object does not exist**
  - **Object exists**
* - `create`
  - Creates new object
  - *Error*
* - `apply`
  - Creates new object (needs complete spec)
  - Configure object (accepts partial spec)
* - `replace`
  - *Error*
  - Delete object; create new object
```


```console
$ kubectl create -f nginx-pod.yaml
pod/nginx-pod created
```

We can also use `kubectl` to inspect the newly created pod:

```console
$ kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
nginx-pod   1/1     Running   0          21s

$ kubectl get pod nginx-pod -o yaml | yq -C | less -R  # force color with CLI flags

$ kubectl describe pod nginx-pod | grep "Events:" -A 15
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  5m51s  default-scheduler  Successfully assigned default/nginx-pod to minikube
  Normal  Pulling    5m50s  kubelet            Pulling image "nginx:1.27.0-bookworm"
  Normal  Pulled     5m45s  kubelet            Successfully pulled image "nginx:1.27.0-bookworm" in 5.019s (5.019s including waiting). Image size: 187603368 bytes.
  Normal  Created    5m45s  kubelet            Created container nginx-pod
  Normal  Started    5m45s  kubelet            Started container nginx-pod
```

## Port forwarding

To access our new `nginx-pod` server:

```console
$ kubectl port-forward --address 0.0.0.0,:: pod/nginx-pod 8000:80
Forwarding from 0.0.0.0:8000 -> 80
Forwarding from [::]:8000 -> 80
Handling connection for 8000
```

:::{image} /_static/images/nginx-example.png
:width: 67%
:::

Note that the `--address` flag is only needed if remote access is desired (default is `localhost`).

## Deleting the pod

```console
$ kubectl delete pod nginx-pod
pod "nginx-pod" deleted
```
