Installation
============

## Docker

To install Docker, follow the [official instructions](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository) for setting up the apt repository and installing the required packages.

Verify the installation by running an example container:

:::{code-block} bash
docker run hello-world
:::

You should see the following output:

:::{code-block} text
Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
:::

## Kubectl

`kubectl` is the command-line client for K8s. To install `kubectl`:

:::{code-block} bash
sudo snap install kubectl --classic
:::

As we do not have a running K8s cluster yet, there should be no available contexts for K8s at the moment:

:::{code-block} console
$ kubectl config get-contexts

CURRENT   NAME   CLUSTER   AUTHINFO   NAMESPACE
:::

We will create a cluster in the following steps.

## Minikube

Obtain the Minikube `.deb` package using `curl`:

:::{code-block} bash
# fetch
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb

# install
sudo dpkg -i minikube_latest_amd64.deb
:::

In the above code, `-LO` tells `curl` to resolve any redirects, and to save the file using the same filename as in the URL path.

### Starting Minikube

:::{code-block} console
$ minikube start
😄  minikube v1.33.1 on Ubuntu 24.04
✨  Automatically selected the docker driver. Other choices: kvm2, virtualbox, ssh, none
📌  Using Docker driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.44 ...
🔥  Creating docker container (CPUs=2, Memory=7800MB) ...
🐳  Preparing Kubernetes v1.30.0 on Docker 26.1.1 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
:::

### Multiple nodes

Note that we could start multiple nodes on the same host. Such a setup could be used for testing networking setups locally before deploying to multiple physical nodes. For an example, see <https://pet2cattle.com/2021/01/multinode-minikube>.

```bash
minikube start -n 2 -p multinode-demo
```