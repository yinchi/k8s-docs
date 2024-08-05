Ingress
=======

To get started with the Ingress controller, first enable the addon.

```console
$ minikube addons enable ingress
💡  ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/ingress-nginx/controller:v1.10.1
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.1
    ▪ Using image registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.1
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled
$ kubectl get pods -A
NAMESPACE       NAME                                        READY   STATUS      RESTARTS     AGE
ingress-nginx   ingress-nginx-admission-create-btg2t        0/1     Completed   0            4m12s
ingress-nginx   ingress-nginx-admission-patch-k54gf         0/1     Completed   1            4m12s
ingress-nginx   ingress-nginx-controller-768f948f8f-t2wgt   1/1     Running     0            4m12s
kube-system     coredns-7db6d8ff4d-xvr9l                    1/1     Running     0            8h
kube-system     etcd-minikube                               1/1     Running     0            8h
kube-system     kube-apiserver-minikube                     1/1     Running     0            8h
kube-system     kube-controller-manager-minikube            1/1     Running     0            8h
kube-system     kube-proxy-h2mmg                            1/1     Running     0            8h
kube-system     kube-scheduler-minikube                     1/1     Running     0            8h
kube-system     storage-provisioner                         1/1     Running     1 (8h ago)   8h
```

Note the first three entries, al belonging to the `ingress-nginx` namespace.

Next, create two services:

```console
$ kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
deployment.apps/web created
$ kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0
deployment.apps/web2 created
$ kubectl expose deployment web --type=NodePort --port=8080
service/web exposed
$ kubectl expose deployment web2 --type=NodePort --port=8080
service/web2 exposed
$ kubectl get all
NAME                       READY   STATUS    RESTARTS   AGE
pod/web-56bb54ff6d-kx9zf   1/1     Running   0          34s
pod/web2-d8dcbdf99-ql8jb   1/1     Running   0          24s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          8h
service/web          NodePort    10.99.66.204     <none>        8080:31616/TCP   11s
service/web2         NodePort    10.111.154.113   <none>        8080:30731/TCP   7s

NAME                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web    1/1     1            1           34s
deployment.apps/web2   1/1     1            1           24s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-56bb54ff6d   1         1         1       34s
replicaset.apps/web2-d8dcbdf99   1         1         1       24s
$ minikube service web --url
http://192.168.49.2:31616
$ minikube service web2 --url
http://192.168.49.2:30731
$ curl `minikube service web --url`
Hello, world!
Version: 1.0.0
Hostname: web-56bb54ff6d-kx9zf
$ curl `minikube service web2 --url`
Hello, world!
Version: 2.0.0
Hostname: web2-d8dcbdf99-ql8jb
```

## Creating the ingress

```{code-block} yaml
:caption: fanout.yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fanout-ingress
spec:
  ingressClassName: nginx
  rules:
    - host: minikube
      http:
        paths:
          - path: /v1
            pathType: Prefix
            backend:
              service:
                name: web
                port:
                  number: 8080
          - path: /v2
            pathType: Prefix
            backend:
              service:
                name: web2
                port:
                  number: 8080
```

```console
$ kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
deployment.apps/web created
$ kubectl expose deployment web --type=NodePort --port=8080
service/web exposed
$ kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0
deployment.apps/web2 created
$ kubectl expose deployment web2 --type=NodePort --port=8080
service/web2 exposed
$ kubectl apply -f fanout.yaml
ingress.networking.k8s.io/fanout-ingress created
$ curl --resolve "minikube:80:$( minikube ip )" -i http://minikube/v1
HTTP/1.1 200 OK
Date: Mon, 05 Aug 2024 02:35:21 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 60
Connection: keep-alive

Hello, world!
Version: 1.0.0
Hostname: web-56bb54ff6d-88g6b
$ curl --resolve "minikube:80:$( minikube ip )" -i http://minikube/v2
HTTP/1.1 200 OK
Date: Mon, 05 Aug 2024 02:35:23 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 60
Connection: keep-alive

Hello, world!
Version: 2.0.0
Hostname: web2-d8dcbdf99-ppgg8
```

Finally, we can add `minikube` to our host machine's `/etc/hosts` file:

```console
$ sudo -- bash -c "echo `minikube ip` minikube >> /etc/hosts"
$ curl http://minikube/v1
Hello, world!
Version: 1.0.0
Hostname: web-56bb54ff6d-88g6b
$ curl http://minikube/v2
Hello, world!
Version: 2.0.0
Hostname: web2-d8dcbdf99-ppgg8
```

## Other Ingress controllers

The above setup only works on the host machine, due to the nature of the default bridge network for Minikube's Docker container. To expose our applications to the web, we can instead use the [ngrok ingress controller](https://ngrok.com/blog-post/ngrok-k8s).  However, since the recommended setup involves Helm, we will return to this later.

Other controllers are descibed at <https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/>.