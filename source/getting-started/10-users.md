Adding another user
===================

First, create a new namespace:

```console
$ kubectl create ns foo-ns
namespace/foo-ns created
```

Next, create a new user:

```console
$ sudo useradd -s /bin/bash -m foo
$ sudo passwd foo
New password:
Retype new password:
passwd: password updated successfully
$ sudo mkdir -p /home/foo/.kube /home/foo/.minikube /home/foo/rbac
```

## Authenticating the new user

Generate keys and certificates for the new user:

```console
$ openssl genrsa -out foo.key 2048
$ openssl req -new -key foo.key -out foo.csr -subj "/C=GB/CN=foo/L=Cambridge/O=YinChi_Test"
$ cat > signing-request.yaml <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: foo-csr
spec:
  groups:
  - system:authenticated
  request: $(cat foo.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - digital signature
    - key encipherment
    - client auth
EOF
$ kubectl create -f signing-request.yaml
certificatesigningrequest.certificates.k8s.io/foo-csr created
$ kubectl certificate approve foo-csr
certificatesigningrequest.certificates.k8s.io/foo-csr approved
$ kubectl get csr foo-csr -o jsonpath='{.status.certificate}' | base64 -d > foo.crt
$ kubectl config set-credentials foo --client-certificate=foo.crt --client-key=foo.key
User "foo" set.
```

View the new signing request:
```console
$ kubectl describe csr foo-csr
Name:               foo-csr
Labels:             <none>
Annotations:        <none>
CreationTimestamp:  Sat, 03 Aug 2024 19:19:26 +0100
Requesting User:    minikube-user
Signer:             kubernetes.io/kube-apiserver-client
Status:             Approved,Issued
Subject:
         Common Name:    foo
         Serial Number:
         Organization:   YinChi_Test
         Country:        GB
         Locality:       Cambridge
Events:  <none>
```

## Seting permissions

Authorize pod read access to the new user `foo` in the `foo-ns` namespace, using the context `foo-context`:

```console
$ kubectl config set-context foo-context --cluster=minikube --namespace=foo-ns --user=foo
Context "foo-context" created.
$ cat > role.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: foo-ns
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
EOF
$ kubectl create -f role.yaml
role.rbac.authorization.k8s.io/pod-reader created
$ cat > rolebinding.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-read-access
  namespace: foo-ns
subjects:
- kind: User
  name: foo
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF
$ kubectl create -f rolebinding.yaml
rolebinding.rbac.authorization.k8s.io/pod-read-access created
$ kubectl -n foo-ns get roles,rolebindings -o wide
NAME                                        CREATED AT
role.rbac.authorization.k8s.io/pod-reader   2024-08-03T18:24:53Z

NAME                                                    ROLE              AGE     USERS   GROUPS   SERVICEACCOUNTS
rolebinding.rbac.authorization.k8s.io/pod-read-access   Role/pod-reader   4m38s   foo
```

Finally, create a new deployment in the `foo-ns` namespace, and check that our user `foo` can get the list of pods created:

```console
$ kubectl -n foo-ns create deployment nginx --image=nginx:alpine
deployment.apps/nginx created
$ kubectl --context=foo-context get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6f564d4fd9-q9c6r   1/1     Running   0          10m
```

## Copying files to the new user's home directory

```console
$ sudo cp * /home/foo/rbac
$ sudo cp ~/.kube/config /home/foo/.kube/config
$ sudo cp ~/.minikube/ca.crt /home/foo/.minikube/ca.crt
$ sudo vim /home/foo/.kube/config
```

Edit `/home/foo/.kube/config` as follows:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /home/foo/.minikube/ca.crt
    extensions:
    - extension:
        last-update: Sat, 03 Aug 2024 18:50:04 BST
        provider: minikube.sigs.k8s.io
        version: v1.33.1
      name: cluster_info
    server: https://192.168.49.2:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    namespace: foo-ns
    user: foo
  name: foo-context
current-context: foo-context
kind: Config
preferences: {}
users:
- name: foo
  user:
    client-certificate: /home/foo/rbac/foo.crt
    client-key: /home/foo/rbac/foo.key
```

Finally, set the owner of all the newly created files to the `foo` user:

```console
$ sudo chown -R foo:foo /home/foo/
```

## Testing the new user `foo`

Log in as the user `foo`.

```
foo@mymachine$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
nginx-6f564d4fd9-q9c6r   1/1     Running   0          51m

foo@mymachine$ kubectl get svc,deploy,rs,ds
Error from server (Forbidden): services is forbidden: User "foo" cannot list resource "services" in API group "" in the namespace "foo-ns"
Error from server (Forbidden): deployments.apps is forbidden: User "foo" cannot list resource "deployments" in API group "apps" in the namespace "foo-ns"
Error from server (Forbidden): replicasets.apps is forbidden: User "foo" cannot list resource "replicasets" in API group "apps" in the namespace "foo-ns"
Error from server (Forbidden): daemonsets.apps is forbidden: User "foo" cannot list resource "daemonsets" in API group "apps" in the namespace "foo-ns"
```

The user `foo` can get the list of pods in the `foo-ns` namespace, but none of the other object types.

## Undoing our changes

```console
$ kubectl config delete-context foo-context
deleted context foo-context from /home/yinchi/.kube/config
$ kubectl config delete-user foo
deleted user foo from /home/yinchi/.kube/config
$ kubectl delete ns foo-ns
namespace "foo-ns" deleted
$ kubectl delete csr foo-csr
certificatesigningrequest.certificates.k8s.io "foo-csr" deleted
$ sudo userdel -r foo
```

Note that since our role and rolebinding created above were associated with the now-deleted `foo-ns` namespace, they have also been deleted.