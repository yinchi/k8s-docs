ConfigMaps
==========

ConfigMaps can be used to decouple a container's configuration from its image specification.

## ConfigMap as environment variables

First, create the ConfigMap:

```console
$ cat > my-config-map.txt <<EOF
  key1=value1
  key2=value2
  EOF
$ kubectl create configmap my-config --from-env-file=my-config-map.txt
configmap/my-config created
$ kubectl get cm
NAME               DATA   AGE
kube-root-ca.crt   1      176m
my-config          2      70s
$ kubectl get cm my-config -o yaml | yq
apiVersion: v1
data:
  key1: value1
  key2: value2
kind: ConfigMap
metadata:
  creationTimestamp: "2024-08-04T19:30:11Z"
  name: my-config
  namespace: default
  resourceVersion: "8903"
  uid: f1829248-7f5d-42b2-9b38-f41ab8f420ba
```

Then, create the pod:

```{code-block} yaml
:caption: config-map.yaml

apiVersion: v1
kind: Pod
metadata:
  name: config-env
spec:
  containers:
    - image: busybox
      name: config-env
      command: ["/bin/sh", "-c", "env"]
      envFrom:
        - configMapRef:
            name: my-config
  restartPolicy: Never
```

This pod will write the environment variables to its output, then quit

```console
$ kubectl create -f config-map.yaml
pod/config-env created
$ kubectl get pod
NAME                     READY   STATUS      RESTARTS   AGE
config-env               0/1     Completed   0          24s
$ kubectl logs pod/config-env | grep key
key1=value1
key2=value2
$ kubectl delete pod/config-env
pod "config-env" deleted
```

Note the use of `kubectl logs` to get the output of a completed pod.

## ConfigMaps as volumes

Let us define two `index.html` files:

```{code-block} text
:caption: green/index.html

<html>
    <head>
        <title>Welcome to GREEN App!</title>
        <style>
            body {
                width: 35em;
                margin: 0 auto;
                font-family: Arial, sans-serif;
                background-color: #009900;
            }
        </style>
    </head>
    <body>
        <h1 style=\"text-align: center;\">Welcome to GREEN App!</h1>
    </body>
</html>
```

Note that the above file is not a true HTML file; the double quotes have been escaped.

```console
$ kubectl create cm green-web-cm --from-file=green/index.html
configmap/green-web-cm created
$ kubectl describe cm/green-web-cm
Name:         green-web-cm
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
index.html:
----
<html>
    <head>
        <title>Welcome to GREEN App!</title>
        <style>
            body {
                width: 35em;
                margin: 0 auto;
                font-family: Arial, sans-serif;
                background-color: #009900;
            }
        </style>
    </head>
    <body>
        <h1 style=\"text-align: center;\">Welcome to GREEN App!</h1>
    </body>
</html>


BinaryData
====

Events:  <none>
```

```{code-block} yaml
:caption: green-web.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: green-web
  name: green-web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: green-web
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: green-web
    spec:
      volumes:
      - name: web-config
        configMap:
          name: green-web-cm
      containers:
      - image: nginx
        name: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: web-config
```

```console
$ kubectl apply -f green-web.yaml
deployment.apps/green-web created
$ kubectl expose deploy/green-web --type=NodePort
service/green-web exposed
$ kubectl port-forward --address 0.0.0.0,:: svc/green-web 8000:80
Forwarding from 0.0.0.0:8000 -> 80
Forwarding from [::]:8000 -> 80
```

In another window, use `sed` to replace "blue with "green" in the two files, and deploy another service:

```console
$ sed 's/green/blue/g' green-web.yaml > blue-web.yaml
$ mkdir blue
$ sed 's/GREEN/BLUE/g' green/index.html | sed 's/009900/000099/' > blue/index.html
$ kubectl create cm blue-web-cm --from-file=blue/index.html
$ kubectl get cm
NAME               DATA   AGE
blue-web-cm        1      5s
green-web-cm       1      14m
kube-root-ca.crt   1      3h38m
my-config          2      43m
$ kubectl apply -f blue-web.yaml
deployment.apps/blue-web created
$ kubectl expose deploy/blue-web --type=NodePort
service/blue-web exposed
$ kubectl port-forward --address 0.0.0.0,:: svc/blue-web 8080:80
Forwarding from 0.0.0.0:8080 -> 80
Forwarding from [::]:8080 -> 80
```

![](/_static/images/configmap-as-volumes.png)

```{note}
Templating tools, e.g., [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/), can be used to manage the generation of similar resource declarations like the two we just made.  For examples, see: <https://dev.to/stack-labs/kustomize-the-right-way-to-do-templating-in-kubernetes-3ohp>.
```