Scaling, updates, and rollbacks
===============================

## Scaling

To scale an existing deployment, use `kubectl scale`.

```console
$ kubectl create -f nginx-deployment.yaml
deployment.apps/nginx-deployment created
$ kubectl get deploy
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           11s
$ kubectl scale deploy nginx-deployment --replicas=1
deployment.apps/nginx-deployment scaled
$ kubectl get deploy
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   1/1     1            1           58s
```

## Rollout history

```console
$ kubectl rollout status deploy nginx-deployment
deployment "nginx-deployment" successfully rolled out
$ kubectl rollout history deploy nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
$ kubectl rollout history deploy nginx-deployment --revision=1
deployment.apps/nginx-deployment with revision #1
Pod Template:
  Labels:       app=nginx-deployment
        pod-template-hash=d64d454c6
  Containers:
   nginx:
    Image:      nginx:1.27.0-bookworm
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
  Node-Selectors:       <none>
  Tolerations:  <none>
```

## Changing the deployed image

```console
$ kubectl set image deploy nginx-deployment nginx=nginx:1.27.0-alpine \
  && kubectl annotate deploy/nginx-deployment kubernetes.io/change-cause="image changed to 1.27.0-alpine"
deployment.apps/nginx-deployment image updated
deployment.apps/nginx-deployment annotated

$ kubectl get svc,deploy,rs,pod
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   10h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   1/1     1            1           19m

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-55458c4fc   1         1         0       2s
replicaset.apps/nginx-deployment-d64d454c6   1         1         1       19m

NAME                                   READY   STATUS              RESTARTS   AGE
pod/nginx-deployment-55458c4fc-g5zxg   0/1     ContainerCreating   0          2s
pod/nginx-deployment-d64d454c6-nhgnv   1/1     Running             0          19m
```

After a few seconds:

```console
$ kubectl get svc,deploy,rs,pod
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   10h

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-deployment   1/1     1            1           20m

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-deployment-55458c4fc   1         1         1       55s
replicaset.apps/nginx-deployment-d64d454c6   0         0         0       20m

NAME                                   READY   STATUS    RESTARTS   AGE
pod/nginx-deployment-55458c4fc-g5zxg   1/1     Running   0          55s
$ kubectl rollout history deploy nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         image changed to 1.27.0-alpine
$ kubectl rollout history deploy nginx-deployment --revision=2
deployment.apps/nginx-deployment with revision #2
Pod Template:
  Labels:       app=nginx-deployment
        pod-template-hash=55458c4fc
  Annotations:  kubernetes.io/change-cause: image changed to 1.27.0-alpine
  Containers:
   nginx:
    Image:      nginx:1.27.0-alpine
    Port:       80/TCP
    Host Port:  0/TCP
    Environment:        <none>
    Mounts:     <none>
  Volumes:      <none>
  Node-Selectors:       <none>
  Tolerations:  <none>
```

Note that the old replica set is still present, but with zero pods.  The number of old replica sets retained is determined by the `.spec.revisionHistoryLimit` field of the deployment if present(default 10).

## Reverting to a previous rollout

```console
$ kubectl create -f nginx-deployment.yaml
deployment.apps/nginx-deployment created

$ kubectl set image deploy nginx-deployment nginx=nginx:1.24.0-alpine \
  && kubectl annotate deploy/nginx-deployment \
  kubernetes.io/change-cause="image changed to 1.24.0-alpine"
deployment.apps/nginx-deployment image updated
deployment.apps/nginx-deployment annotated
$ kubectl set image deploy nginx-deployment nginx=nginx:1.25.0-alpine \
  && kubectl annotate deploy/nginx-deployment \
  kubernetes.io/change-cause="image changed to 1.25.0-alpine"
deployment.apps/nginx-deployment image updated
deployment.apps/nginx-deployment annotated
$ kubectl set image deploy nginx-deployment nginx=nginx:1.26.0-alpine \
  && kubectl annotate deploy/nginx-deployment \
  kubernetes.io/change-cause="image changed to 1.26.0-alpine"
deployment.apps/nginx-deployment image updated
deployment.apps/nginx-deployment annotated
$ kubectl set image deploy nginx-deployment nginx=nginx:1.27.0-alpine \
  && kubectl annotate deploy/nginx-deployment \
  kubernetes.io/change-cause="image changed to 1.27.0-alpine"
deployment.apps/nginx-deployment image updated
deployment.apps/nginx-deployment annotated
$ kubectl rollout history deploy nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         image changed to 1.24.0-alpine
3         image changed to 1.25.0-alpine
4         image changed to 1.26.0-alpine
5         image changed to 1.27.0-alpine
```

Here we rollback to Revision #3:

```console
$ kubectl rollout undo deploy/nginx-deployment --to-revision=3
deployment.apps/nginx-deployment rolled back
$ kubectl rollout history deploy nginx-deployment
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         image changed to 1.24.0-alpine
4         image changed to 1.26.0-alpine
5         image changed to 1.27.0-alpine
6         image changed to 1.25.0-alpine
```

Note that Revision 3 has disappeared, which can be confusing; it may be preferable to simply reapply the changes associated with the original revision instead.  This is because revisions are associated with replica sets, and we are re-using the replica set associated with the `nginx:1.25.0-alpine` image.