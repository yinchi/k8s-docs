Helmfile
=========

Helmfile is a way to install multiple helm charts easily.  To install, download from <https://github.com/helmfile/helmfile/releases>, extract the archive, and copy helmfile to a directory on your `$PATH`.

An example Helmfile app is at <https://github.com/wkrzywiec/helm-course/tree/5-3>.  First, inspect the `helmfile.yaml`:

```yaml
helmDefaults:
  wait: true
  timeout: 600

repositories:
  - name: helm-app
    url: https://wkrzywiec.github.io/helm-app

  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  - name: kanban-frontend
    namespace: kanban
    chart: ./app
    values:
      - kanban-frontend.yaml

  - name: kanban-backend
    namespace: kanban
    chart: helm-app/app
    values:
      - kanban-backend.yaml
    needs:
      - postgres

  - name: postgres
    namespace: kanban
    chart: bitnami/postgresql
    values:
      - postgres.yaml
```

We see that the three Helm charts required for the app are all defined in the file, with `kanban-backend` listed as requiring `postgres` as a dependency.
All included Helm charts can be installed in one line with `helmfile sync`, and uninstalled with `helmfile destroy`.

Other commands include `helmfile lint` which lints all the charts in the helmfile, and `helmfile show-dag` to show the partial order of chart installation defined by the listed dependencies between charts.

For more information, see <https://helmfile.readthedocs.io/en/latest/>.