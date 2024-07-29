# Zalando Postgres Operator

### Install:

add repos

```bash
helm repo add postgres-operator-charts [https://opensource.zalando.com/postgres-operator/charts/postgres-operator](https://opensource.zalando.com/postgres-operator/charts/postgres-operator);
helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui;
```

install the **postgres-operator**

```bash
helm install -n zalando-pgo --create-namespace postgres-operator \
postgres-operator-charts/postgres-operator --debug
```

install the **postgres-operator-ui**

```bash
helm install -n zalando-pgo postgres-operator-ui \
postgres-operator-ui-charts/postgres-operator-ui \
--debug
```

### create vs for operator UI:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: postgres-operator-ui
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - postgres-operator-ui.aks-rofl16435.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: postgres-operator-ui.zalando-pgo.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```

### create object storage secret:

create dummy secret:

```bash
apiVersion: v1
data:
  WAL_S3_BUCKET: em9vYnk=
  AWS_ACCESS_KEY_ID: em9vYnk=
  AWS_SECRET_ACCESS_KEY: em9vYnk=
  AWS_ENDPOINT: em9vYnk=
kind: Secret
metadata:
  name: pg-backup-object-storage
  namespace: zalando-pgo
type: Opaque
```

then patch it with clear text values:

```bash
kubectl -n zalando-pgo patch secret pg-backup-object-storage \
-p='{"stringData":{"WAL_S3_BUCKET": "lolz-postgres-backups","AWS_ACCESS_KEY_ID": "f9824h9vGSDFG74gj94MKCOS84V0a7f2a0fnZa","AWS_SECRET_ACCESS_KEY": "WZHu00yVPQNiGIs104ZIHprWx5Qgvog23EzPIs2x6qQvBdp/Koo2EMkg2EzmHhb1BUvtFpKTdAKD9r4uI7xRnw==","AWS_ENDPOINT": "http://minio-standalone.aks-rofl16435.cicd.ginger.cn:80"}}' -v=1
```

### create new PG cluster:

```yaml
apiVersion: acid.zalan.do/v1
kind: postgresql
metadata:
  labels:
    team: acid
  name: lolz
  namespace: zalando-pgo
spec:
  env:
  - name: WAL_S3_BUCKET
    valueFrom:
      secretKeyRef:
        name: pg-backup-object-storage
        key: WAL_S3_BUCKET
  - name: AWS_ACCESS_KEY_ID
    valueFrom:
      secretKeyRef:
        name: pg-backup-object-storage
        key: AWS_ACCESS_KEY_ID
  - name: AWS_SECRET_ACCESS_KEY
    valueFrom:
      secretKeyRef:
        name: pg-backup-object-storage
        key: AWS_SECRET_ACCESS_KEY
  - name: AWS_ENDPOINT
    valueFrom:
      secretKeyRef:
        name: pg-backup-object-storage
        key: AWS_ENDPOINT
  allowedSourceRanges: null
  databases:
    lolz_production: lolz
  numberOfInstances: 3
  postgresql:
    version: '13'
  resources:
    limits:
      cpu: 4000m
      memory: 8000Mi
    requests:
      cpu: 100m
      memory: 100Mi
  teamId: acid
  users:
    lolz:
    - superuser
    - createdb
  volume:
    size: 20Gi
```

the new PG cluster object will be deployed in the `zalando-pgo` namespace,

and will create an STS named `lolz`, creating 3 pods:

```yaml
lolz-0
lolz-1
lolz-2
```

and 3 matching PVC’s for replication:

```yaml
pgdata-lolz-0
pgdata-lolz-1
pgdata-lolz-2
```

### edit operator UI deployment

add following env vars to allow backups via UI

```yaml
        - name: SPILO_S3_BACKUP_BUCKET
          valueFrom:
            secretKeyRef:
              key: WAL_S3_BUCKET
              name: pg-backup-object-storage
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              key: AWS_ACCESS_KEY_ID
              name: pg-backup-object-storage
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              key: AWS_SECRET_ACCESS_KEY
              name: pg-backup-object-storage
        - name: AWS_ENDPOINT
          valueFrom:
            secretKeyRef:
              key: AWS_ENDPOINT
              name: pg-backup-object-storage
        - name: WALE_S3_ENDPOINT
          value: http+path://minio-standalone.aks-rofl16435.cicd.ginger.cn:80
        - name: SPILO_S3_BACKUP_PREFIX
          value: spilo/
        - name: TARGET_NAMESPACE
          value: '*'
```

### connect postgres DB to lolz:

**username** remains as is

**host**:

```bash
lolz.zalando-pgo.svc.cluster.local
```

**password**:

```bash
kubectl -n zalando-pgo get secret postgres.lolz.credentials.postgresql.acid.zalan.do -o yaml
```

**kubectl patch for automation:**

```yaml
PGPASS=$(echo $(kubectl -n zalando-pgo get secret postgres.lolz.credentials.postgresql.acid.zalan.do --template={{.data.password}}) | base64 -d)
```

```bash
kubectl -n lolz patch secret pg-creds \
-p='{"stringData":{"POSTGRES_HOST": "lolz.zalando-pgo.svc.cluster.local","POSTGRES_PASSWORD": "'${PGPASS}'","POSTGRESQL_ADMIN_PASSWORD": "'${PGPASS}'","POSTGRESQL_PASSWORD": "'${PGPASS}'"}}' -v=1
```

### postgresql.conf

zalando default configuration

```bash
MAX_CONNECTIONS: 266
SHARED_BUFFERS: 1600MB
EFFECTIVE_CACHE_SIZE: 4GB
```

lolz default configuration

```bash
MAX_CONNECTIONS: 500
SHARED_BUFFERS: 1024MB
EFFECTIVE_CACHE_SIZE: 2048MB
```

### connection pooler

need to go over all options:

[https://opensource.zalando.com/postgres-operator/docs/reference/cluster_manifest.html#connection-pooler](https://opensource.zalando.com/postgres-operator/docs/reference/cluster_manifest.html#connection-pooler)

to see if we miss any HA feature using the default config:

```bash
  numberOfInstances: 1
  enableMasterLoadBalancer: false
  enableReplicaLoadBalancer: false
  enableConnectionPooler: false
  enableReplicaConnectionPooler: false
  enableMasterPoolerLoadBalancer: false
  enableReplicaPoolerLoadBalancer: false
```

### backups

has native support for cloud buckets (AWS S3, GCP GCS, Azure BlobStorage)

 **env vars for storage:**

[https://github.com/zalando/spilo/blob/master/ENVIRONMENT.rst](https://github.com/zalando/spilo/blob/master/ENVIRONMENT.rst)

**tested with minio storage (defined as aws s3)**

backups were automatically created once credentials were provided

**base backup (single)**


**wal logs (continuous)**


**backups page in UI**


### restore from backups

test cloning a cluster, from an existing backup in the object storage bucket

### edit operator CRD

```bash
kubectl -n zalando-pgo edit OperatorConfiguration postgres-operator
```

get all possible params:

```bash
kubectl -n zalando-pgo edit crd operatorconfigurations.acid.zalan.do
```

### options to check

```yaml
BACKUP_SCHEDULE:
cron schedule for doing backups via WAL-E (if WAL-E is enabled, '00 01 * * *' by default)

WALE_BACKUP_THRESHOLD_MEGABYTES:
maximum size of the WAL segments accumulated after the base backup to consider WAL-E restore instead of pg_basebackup.

WALE_BACKUP_THRESHOLD_PERCENTAGE:
maximum ratio (in percents) of the accumulated WAL files to the base backup to consider WAL-E restore instead of pg_basebackup.
```