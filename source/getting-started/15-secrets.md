Secrets
========

## Secrets as environment variables

```console
$ echo -n mypassword > password.txt
$ kubectl create secret generic my-password --from-file=password.txt
secret/my-password created
```

```{warning}
If storing your projects on GitHub/GitLab/etc., make sure your `.gitignore` file is set up to avoid exposing any secrets you create.
```

Let us create a pod that consumes this secret:

```{code-block} yaml
:caption: secret-env.yaml

apiVersion: v1
kind: Pod
metadata:
  name: secret-env
spec:
  containers:
    - image: busybox
      name: secret-env
      command: ["/bin/sh", "-c", "env"]
      env:
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-password
              key: password.txt
  restartPolicy: Never
```

```console
$ kubectl create -f secret-env.yaml
pod/secret-env created
$ kubectl get pod
NAME         READY   STATUS              RESTARTS   AGE
secret-env   0/1     ContainerCreating   0          2s
$ kubectl logs pod/secret-env | grep PASSWORD
PASSWORD=mypassword
```

For more details, we can inspect the secret created in `kubectl`:

```console
kubectl get secret/my-password -o yaml | yq
apiVersion: v1
data:
  password.txt: bXlwYXNzd29yZA==
kind: Secret
metadata:
  creationTimestamp: "2024-08-04T21:05:59Z"
  name: my-password
  namespace: default
  resourceVersion: "13654"
  uid: ccc1422e-30c6-49e3-95fc-bfe8d2a42302
type: Opaque
```

We can see that the secret was stored using base64 encoding.

```{warning}
base64 encoding is not encryption.
```

## Secrets as volumes

```{code-block} yaml
:caption: secret-vol.yaml

apiVersion: v1
kind: Pod
metadata:
  name: secret-vol
spec:
  containers:
    - image: busybox
      name: secret-vol
      command: ["/bin/sh", "-c", "cat /secrets/password.txt"]
      volumeMounts:
        - name: secret-volume
          mountPath: "/secrets"
          readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: my-password
  restartPolicy: Never
```

Our secret will thus be mounted at `secrets/password.txt`.

```console
$ kubectl create -f secret-vol.yaml
pod/secret-vol created
$ kubectl logs pod/secret-vol; echo
mypassword
$ kubectl delete pod/secret-vol
pod "secret-vol" deleted
$ kubectl delete secret/my-password
secret "my-password" deleted
```