mlflow
======

[MLFlow](https://mlflow.org/) is an open source platform specialized in tracking ML experiments, and packaging and deploying ML models.


Current chart version is `1.0.0`

---

## Install Chart

To install the MLFlow chart in your Kubernetes cluster, please run the following commands: 

Create the K8s namespace:
```bash
kubectl create namespace mlflow
```

Install the MLFlow tracking server:

```bash
helm -n mlflow_namespace upgrade mlflow helm/mlflow \
  -f helm/mlflow/values.yaml \
  --install \
  --atomic \
  --wait \
  --timeout 300s \
```

After the installation succeeds, you can get the Chart's status via:

```bash
helm status mlflow -n mlflow
```

Also, you can check if your MLFlow pods have a running state by executing the following command :
```bash
kubectl get pods --field-selector=status.phase=Running -n mlflow
```

You can delete/uninstall MLFlow anytime by using the following command:

```bash
helm delete --purge mlflow
```
or
```bash
helm uninstall mlflow -n mlflow
```


## Known limitations and issues

The following capabilities have been left out of the Chart:
- Provisioning / usage of persistent volumes as backend store
- SQLServer compatibility
- Batch jobs can't be completed if you are using Linkerd Proxy (Linkerd is injecting the Linkerd Proxy into k8s job's pod and therefore, the job will never be completed ). For more details, check [this](https://linkerd.io/2.10/tasks/graceful-shutdown/) and [this](https://github.com/kubernetes/kubernetes/issues/25908)
- No initContainers for the database on this version.

## Local vs. Remote backend stores

By default, MLFlow will store data and artifacts in the local filesystem. If you're deploying a production-ready MLFlow cluster, I would recommend you to point your backend store to a remote database.

At the moment, the only database engine supported by this Chart is Postgres. This means you can add the following values:

```yaml
mlflowBackend:
  connections:
    username: my_user
    password: my_password
    host: my_host
    port: 5342
    database: my_db
```

## Create MLFlow database using AWS RDS Aurora (MySql or PgSQL) as backendStore  :
## Prerequisite :
Install Secrets Store CSI Driver on your K8s Cluster:

[AWS Secrets Store CSI Driver documentation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html)
[Secrets Store CSI Driver Documentation](https://secrets-store-csi-driver.sigs.k8s.io/introduction.html)

```bash
helm repo add secrets-store-csi-driver https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/master/charts
helm install -n kube-system csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true
```
Modify the following values (example : create the mlflow database on mysql):
```yaml
database:
  enabled: true 
  engine:
    postgres: {} #psql
    mysql: mysql+pymysql

mlflowBackend:
  filepath: {}

  connections:
    db_host: "your_mysql_db_host"
    db_master_user: "admin_user"
    db_user: "mlflow"
    db_name: "mlflow"
    db_port: "3306"

```


## Service Accounts / RBAC

By default, this Chart creates a new ServiceAccount and runs the deployment under it. You can disable this behavior setting `serviceAccount.create = false`.


## Ingress controller

By default, the ingress controller is disabled. You can, however, instruct the Chart to create an Ingress resource for you with the values you specify.

## MLFlow Server arguments :
[MLFlow Documentation](https://www.mlflow.org/docs/latest/index.html)
[MLFlow Tracking Server CLI] (https://www.mlflow.org/docs/latest/cli.html#mlflow-server)
If you use --gunicorn-opts "multiple gunicorn settings", please check gunicorn official documentation [here](https://docs.gunicorn.org/en/stable/settings.html)

## Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling | object | `{}` | Autoscaling options for your MLFlow pod : HPA |
| affinity | object | `{}` |  |
| database.enabled | bool | false | Enable this if you want to use MLFlow with a database backend store |
| database.engine.postgres | string | `nil` |  Set it to psql (used by connection string) if you are using a postgres database |
| database.engine.mysql | string | `nil` | Set it to mysql+pymysql if you are using a mysql database |
| defaultArtifactRoot | string | `nil` | A local or remote filepath (e.g. s3://my-bucket). It is mandatory when specifying a database backend store |
| extraArgs | object | `{}` | A map of arguments and values to pass to the `mlflow server` command |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ursuciprian/mlflow-kubernetes"` | The fully qualified name of the docker image to use |
| image.tag | string | `nil` | The tag for the repository (e.g. 'v1') |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `nil` | https://kubernetes.io/docs/concepts/services-networking/ingress/ | 
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths | list | `[]` | A list of objects. Each object should contain a `path` key, and may contain a `serviceNameOverride` and a `servicePortOverride` key. If you do not specify any overrides, the Chart will use the ones for the service it creates automatically. We allow overrides to allow advanced behavior like SSL redirection on the AWS ALB Ingress Controller. |
| ingress.tls | list | `[]` |  |
| mlflow.initContainers | object | Check values.yaml | If .values.database.enabled: true, a container will be initiated on your mlflow pod just to check if the connectivity with the database can be established |
| mlflowBackend | object | `{"filepath":null,"postgres":null}` | Either a filepath, a database or the default value. At present, postgres is the only database engine supported by the official image. Should you want to connect to any other database, please refer to the README. |
| mlflowBackend.filepath | string | `nil` | A local or remote filesystem path (e.g. /mnt/persistent-disk) |
| mlflowBackend.connections | string | `nil` | A map with the values for (username, password, host, port and database). |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| secrets.store.enabled | bool | `false` | Enable the usage of the secrets created with Secrets Store CSI Driver |
| secrets.store.provider | string | `aws` | Default value : aws, but you can pick up any secrets provider from Azure, GC or Hashicorp Vault | 
| securityContext | object | `{}` |  |
| service.port | int | `5000` |  |
| service.type | string | `"NodePort"` |  |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a service account should be created |
| serviceAccount.name | string | `nil` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| prometheus.expose | bool | `false` | Path to the directory where metrics will be stored. If the directory doesn’t exist, it will be created. Activate prometheus exporter to expose metrics on /metrics endpoint |
| tolerations | list | `[]` |  |
