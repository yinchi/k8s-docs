The K8s REST API
================

In addition to the `kubectl` command-line tool, K8s provides a JSON-based REST API.

## Install jq and yq

`jq` is a tool for pretty-formatting JSON data in the console, and `yq` is the corresponding tool for YAML. They can also be used to filter and manipulate keys and values within the JSON or YAML document. We install them as follows:

```bash
sudo snap install jq
sudo snap install yq
```

## Accessing the K8s API

Expose the API server as follows:

```bash
kubectl proxy
```

In a seperate shell:

```bash
curl -s http://localhost:8001/version | jq
```

The `-s` flag above suppresses progress information from `curl`, showing only the downloaded content, which is then piped to `jq`.  You should see something like the following:

```json
{
  "major": "1",
  "minor": "30",
  "gitVersion": "v1.30.0",
  "gitCommit": "7c48c2bd72b9bf5c44d21d7338cc7bea77d0ad2a",
  "gitTreeState": "clean",
  "buildDate": "2024-04-17T17:27:03Z",
  "goVersion": "go1.22.2",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

## Client keys and tokens

First, terminate the proxy from above.  In this subsection, we will access the API server using its IP address on the `minikube` network.

````{note}
When using the "docker" engine (the default), Minikube runs as a Docker container on the newly created `minikube` network.

```console
$ docker network ls
NETWORK ID     NAME       DRIVER    SCOPE
0037aa7cdd27   bridge     bridge    local
0f889a755b8e   host       host      local
5f97f356041c   minikube   bridge    local
58197f5f288c   none       null      local

$ # IP address of the minikube container on the `minikube` network
$ docker network inspect minikube | jq '.[].Containers | to_entries[].value.IPv4Address'
"192.168.49.2/24"

$ # IP address of the host machine on the `minikube` network
$ docker network inspect minikube | jq '.[].IPAM.Config[0].Gateway'
"192.168.49.1"
```

````

To authenticate ourselves properly while using the REST API, we examine our K8s configuration:

```bash
kubectl config view | yq
```

Example output:
```yaml
apiVersion: v1
clusters:
  - cluster:
      certificate-authority: /home/yinchi/.minikube/ca.crt
      extensions:
        - extension:
            last-update: Fri, 02 Aug 2024 18:35:48 BST
            provider: minikube.sigs.k8s.io
            version: v1.33.1
          name: cluster_info
      server: https://192.168.49.2:8443
    name: minikube
contexts:
  - context:
      cluster: minikube
      extensions:
        - extension:
            last-update: Fri, 02 Aug 2024 18:35:48 BST
            provider: minikube.sigs.k8s.io
            version: v1.33.1
          name: context_info
      namespace: default
      user: minikube
    name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
  - name: minikube
    user:
      client-certificate: /home/yinchi/.minikube/profiles/minikube/client.crt
      client-key: /home/yinchi/.minikube/profiles/minikube/client.key
```

Save the API server's IP address and authentication file paths to environment variables:

```console
$ cat minikube.sh
export MINIKUBE_SERVER=$(kubectl config view | yq '.clusters[] | select(.name == "minikube") | .cluster.server')
export MINIKUBE_CA=$(kubectl config view | yq '.clusters[] | select(.name == "minikube") | .cluster.certificate-authority')
export MINIKUBE_CLIENT_CERT=$(kubectl config view | yq '.users[] | select(.name == "minikube") | .user.client-certificate')
export MINIKUBE_CLIENT_KEY=$(kubectl config view | yq '.users[] | select(.name == "minikube") | .user.client-key')

$ . minikube.sh
```

Test the above configuration by fetching from the API root:
```bash
curl -s $MINIKUBE_SERVER --cert $MINIKUBE_CLIENT_CERT \
  --key $MINIKUBE_CLIENT_KEY --cacert $MINIKUBE_CA | jq -C | head
```

```json
{
  "paths": [
    "/.well-known/openid-configuration",
    "/api",
    "/api/v1",
    "/apis",
    "/apis/",
    "/apis/admissionregistration.k8s.io",
    "/apis/admissionregistration.k8s.io/v1",
    "/apis/apiextensions.k8s.io",
```

Supplying a `-C` flag to jq in the command above forces color output, which is disabled by default if the output is piped.

````{note}
Without supplying our certificates/keys, we need to supply an `--insecure` or `-k` flag to `curl`. Nevertheless, the above API endpoint will not work:

```bash
$ curl -s $MINIKUBE_SERVER -k | jq
```
```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```
