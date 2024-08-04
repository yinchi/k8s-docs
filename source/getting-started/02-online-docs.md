Online Documentation
====================

**Kubernetes**

We use `minikube` as our K8s engine in this demo. Documentation for other K8s engines are also listed below.

- Documentation for the `kubectl` command-line tool: <https://kubernetes.io/docs/reference/kubectl/generated/>
- Documentation for `minikube`: <https://minikube.sigs.k8s.io/docs/commands/>
- Documentation for `kind`: <https://kind.sigs.k8s.io/>
- Documentation for `microk8s`: <https://microk8s.io/docs>

Windows and Mac users can also use the Kubernetes engine and `kubectl` binary bundled with [Docker Desktop](https://docs.docker.com/desktop/kubernetes/).

Cloud services for K8s include [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview) and [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/).

**Command line tools**

- [yq](https://mikefarah.gitbook.io/yq): command-line YAML processor and pretty-printer, also supports JSON and TOML
- [jq](https://jqlang.github.io/jq/): command-line JSON processor and pretty-printer. It can be useful to install `jq` separately from `yq` to avoid having to set command-line flags (i.e. `-p json -o json`)
