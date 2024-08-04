Liveness and Readiness Probes
=============================

## Liveness

Liveness probes can be used to automatically restart a pod that fails.

### Option 1: Run a command on the host

Consider the command:

```bash
touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
```

This creates a temporary file, then deletes it after 30 seconds. The second `sleep` command ensures the pod lives long enough for the liveness probe to detect that the file has gone missing.

:::{code-block} yaml
:caption: liveness.yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: k8s.gcr.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 15
      failureThreshold: 1
      periodSeconds: 5
:::

Here, we specify a liveness check that is first triggered at 15 seconds, then every 5 seconds thereafter:

```{kroki}
:type: plantuml
:caption: Right click > "Open image in new tab" to view full-size.

@startyaml
#highlight spec/containers/0/livenessProbe/
#highlight spec/containers/0/livenessProbe/exec
#highlight spec/containers/0/livenessProbe/initialDelaySeconds
#highlight spec/containers/0/livenessProbe/failureThreshold
#highlight spec/containers/0/livenessProbe/periodSeconds
#highlight spec/containers/0/livenessProbe/exec/command
#highlight spec/containers/0/livenessProbe/exec/command/0
#highlight spec/containers/0/livenessProbe/exec/command/1

apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 15
      failureThreshold: 1
      periodSeconds: 5
@endyaml
```

```{kroki}
:type: plantuml

@startuml
concise "/tmp/healthy" as F
concise "Health check" as H

@0
F is "" #green
H is {-}

@15
H is ""

@15.01
H is {-}

@20
H is ""

@20.01
H is {-}

@25
H is ""

@25.01
H is {-}

@30
F is {hidden}
H is "" #red

@30.01
H is {-}

@35
H is {-}
@enduml
```

Note also that the container is declared unhealthy after a single failed liveness check (default is 3).

Run the pod and watch its status:

```console
$ kubectl create -f liveness.yaml; kubectl get pod liveness-exec -w
pod/liveness-exec created
NAME            READY   STATUS              RESTARTS   AGE
liveness-exec   0/1     ContainerCreating   0          0s
liveness-exec   1/1     Running             0          3s
liveness-exec   1/1     Running             1 (2s ago)   67s
liveness-exec   1/1     Running             2 (2s ago)   2m12s
```

```console
$ kubectl describe pod liveness-exec
Name:             liveness-exec
...
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  3m14s                default-scheduler  Successfully assigned default/liveness-exec to minikube
  Normal   Pulled     3m12s                kubelet            Successfully pulled image "busybox" in 2.151s (2.151s including waiting). Image size: 4261574 bytes.
  Normal   Pulled     2m8s                 kubelet            Successfully pulled image "busybox" in 1.001s (1.001s including waiting). Image size: 4261574 bytes.
  Normal   Pulling    64s (x3 over 3m14s)  kubelet            Pulling image "busybox"
  Normal   Created    63s (x3 over 3m12s)  kubelet            Created container liveness
  Normal   Started    63s (x3 over 3m12s)  kubelet            Started container liveness
  Normal   Pulled     63s                  kubelet            Successfully pulled image "busybox" in 1.013s (1.013s including waiting). Image size: 4261574 bytes.
  Warning  Unhealthy  29s (x3 over 2m39s)  kubelet            Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
  Normal   Killing    29s (x3 over 2m39s)  kubelet            Container liveness failed liveness probe, will be restarted
```

Note that only the most recent restart (starting at age=64s) is fully described.

### Option 2: HTTP GET request

An example of a liveness probe yaml entry is as follows. Any non-200 response or lack of response is treated as the application being unhealthy:

```yaml
spec:
  containers:
    - livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
          httpHeaders:
          - name: X-Custom-Header
            value: Awesome
        initialDelaySeconds: 15
        periodSeconds: 5
```

(Note that only the relevant fields in the pod declaration are shown above; the same applies to the remaining YAML definitions in this seection.)

### Other options

For other options and more information on liveness probes, see <https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/>.

## Readiness

A readiness probe does not trigger a restart upon failure, but prevents requests from being sent. This is useful for services with dependencies, for example a database dependency.

```yaml
spec:
  containers:
    - readinessProbe:
      exec:
          command:
          - cat
          - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

## Startup

The startup probe repeats until *N* failures or the first sucessful response (upon which the probe terminates and the liveness probe, if any, takes over).

```yaml
spec:
  containers:
    - ports:
      - name: liveness-port
        containerPort: 8080
      
      livenessProbe:
        httpGet:
          path: /healthz
          port: liveness-port
        failureThreshold: 1
        periodSeconds: 10
      
      startupProbe:
        httpGet:
          path: /healthz
          port: liveness-port
        failureThreshold: 30
        periodSeconds: 10
      ...
```