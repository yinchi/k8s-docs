Labels and seleectors
=====================

Labels are key-value pairs used to append metadata to a K8s object.

First, let's view the labels for an internal K8s service:

```console
$ kubectl get svc kube-dns -n kube-system -o yaml | yq '.metadata.labels'
k8s-app: kube-dns
kubernetes.io/cluster-service: "true"
kubernetes.io/name: CoreDNS
```

Now we know that `k8s-app` is a label key commonly used by internal K8s objects, let us observe which objects also contain this key:

```console
$ kubectl get svc,ds,rs,pods -A -L k8s-app
NAMESPACE              NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE     K8S-APP
default                service/kubernetes                  ClusterIP   10.96.0.1       <none>        443/TCP                  9m17s
kube-system            service/kube-dns                    ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP   9m16s   kube-dns
kube-system            service/metrics-server              ClusterIP   10.96.1.164     <none>        443/TCP                  9m9s    metrics-server
kubernetes-dashboard   service/dashboard-metrics-scraper   ClusterIP   10.102.193.25   <none>        8000/TCP                 9m4s    dashboard-metrics-scraper
kubernetes-dashboard   service/kubernetes-dashboard        ClusterIP   10.99.142.68    <none>        80/TCP                   9m4s    kubernetes-dashboard

NAMESPACE     NAME                        DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE     K8S-APP
kube-system   daemonset.apps/kube-proxy   1         1         1       1            1           kubernetes.io/os=linux   9m16s   kube-proxy

NAMESPACE              NAME                                                  DESIRED   CURRENT   READY   AGE    K8S-APP
kube-system            replicaset.apps/coredns-7db6d8ff4d                    1         1         1       9m2s   kube-dns
kube-system            replicaset.apps/metrics-server-c59844bb4              1         1         1       9m2s   metrics-server
kubernetes-dashboard   replicaset.apps/dashboard-metrics-scraper-b5fc48f67   1         1         1       9m2s   dashboard-metrics-scraper
kubernetes-dashboard   replicaset.apps/kubernetes-dashboard-779776cb65       1         1         1       9m2s   kubernetes-dashboard

NAMESPACE              NAME                                            READY   STATUS    RESTARTS   AGE     K8S-APP
kube-system            pod/coredns-7db6d8ff4d-kbfcv                    1/1     Running   0          9m2s    kube-dns
kube-system            pod/etcd-minikube                               1/1     Running   0          9m16s
kube-system            pod/kube-apiserver-minikube                     1/1     Running   0          9m16s
kube-system            pod/kube-controller-manager-minikube            1/1     Running   0          9m16s
kube-system            pod/kube-proxy-rcrrb                            1/1     Running   0          9m2s    kube-proxy
kube-system            pod/kube-scheduler-minikube                     1/1     Running   0          9m16s
kube-system            pod/metrics-server-c59844bb4-pnl69              1/1     Running   0          9m2s    metrics-server
kube-system            pod/storage-provisioner                         1/1     Running   0          9m15s
kubernetes-dashboard   pod/dashboard-metrics-scraper-b5fc48f67-nmncw   1/1     Running   0          9m2s    dashboard-metrics-scraper
kubernetes-dashboard   pod/kubernetes-dashboard-779776cb65-p6qms       1/1     Running   0          9m2s    kubernetes-dashboard
```

Change the `-L` to `-l` (lowercase) to filter out a certain label value:

```
$ kubectl get svc,ds,rs,pods -A -l k8s-app=kube-dns
NAMESPACE     NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-system   service/kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   11m

NAMESPACE     NAME                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-7db6d8ff4d   1         1         1       11m

NAMESPACE     NAME                           READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-7db6d8ff4d-kbfcv   1/1     Running   0          11m
```

For more information, see <https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors>.