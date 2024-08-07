Home 
=======

This website describes the setup and deployment of a simple single-node Kubernetes (k8s) cluster.

The instructions assume a **Ubuntu** host machine; however, except for the installation stage most commands will be similar.  Ubuntu 24.04 was used to create this documentation.

**Contents**

- [Intro to Kubernetes](getting-started/01-installation.md)
- [Intro to Helm](helm/01-setup.md)
- Intro to Traefik
- Backend with FastAPI, SQLModel, and SQLAlchemy-JSON
- Task scheduling with Argos Workflow
- Frontend with Plotly Dash

:::{toctree}
:hidden:
:numbered:
:caption: Intro to K8s
:glob:

getting-started/*
:::

:::{toctree}
:hidden:
:numbered:
:caption: Intro to Helm
:glob:

helm/*
:::