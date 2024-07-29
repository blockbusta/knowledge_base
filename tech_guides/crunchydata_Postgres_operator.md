# crunchydata Postgres operator

### Reference:

- **CR documentation** - [https://access.crunchydata.com/documentation/postgres-operator/5.3.0/references/crd/#postgrescluster](https://access.crunchydata.com/documentation/postgres-operator/5.3.0/references/crd/#postgrescluster)
- **Getting Started** - [https://access.crunchydata.com/documentation/postgres-operator/v5/installation/helm/](https://access.crunchydata.com/documentation/postgres-operator/v5/installation/helm/)
- **Container Image list** - [https://www.crunchydata.com/developers/download-postgres/containers/postgresql13](https://www.crunchydata.com/developers/download-postgres/containers/postgresql13)

# Helm install

Deploy the crunchy data PG operator to get started:

```jsx
helm install pgo oci://registry.developers.crunchydata.com/crunchydata/pgo \
--set controllerImages.cluster=super.net/qaway/crunchy:postgres-operator-ubi8-5.3.1-0 \
--set controllerImages.upgrade=super.net/qaway/crunchy:postgres-operator-upgrade-ubi8-5.3.1-0 \
-n pgo --wait --create-namespace
```

# Create postgres cluster

Now that the operator is running you need to deploy a PG cluster. 

Here is an example of a postgresCluster CR. This will deploy a postgres in HA.

```yaml
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: lolz-production
  namespace: lolz
spec:
  patroni:
    dynamicConfiguration:
      postgresql:
        parameters:
          max_connections: 500
          shared_buffers: 2GB
          effective_cache_size: 4GB
  userInterface:
    pgAdmin:
      image: super.net/qaway/crunchy:pgadmin4-ubi8-4.30-10
      dataVolumeClaimSpec:
        accessModes:
        - "ReadWriteOnce"
        resources:
          requests:
            storage: 5Gi
  image: super.net/qaway/crunchy:postgres-ubi8-13.9-2
  postgresVersion: 13
  users:
  - name: lolz
    options: "SUPERUSER"
    databases:
    - lolz_production
    password:
      type: AlphaNumeric
  instances:
    - name: pgha1
      replicas: 3
      dataVolumeClaimSpec:
        accessModes:
        - "ReadWriteOnce"
        resources:
          limits:
            cpu: 4000m
            memory: 8000Mi
          requests:
            cpu: 100m
            memory: 100Mi
            storage: 30Gi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  postgres-operator.crunchydata.com/cluster: hippo-ha
                  postgres-operator.crunchydata.com/instance-set: pgha1
  backups:
    pgbackrest:
      image: super.net/qaway/crunchy:pgbackrest-ubi8-2.41-2
      repos:
      - name: repo1
        volume:
          volumeClaimSpec:
            accessModes:
            - "ReadWriteOnce"
            resources:
              requests:
                storage: 5Gi
  proxy:
    pgBouncer:
      image: super.net/qaway/crunchy:pgbouncer-ubi8-1.17-5
      replicas: 3
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  postgres-operator.crunchydata.com/cluster: hippo-ha
                  postgres-operator.crunchydata.com/role: pgbouncer
---
apiVersion: v1
kind: Service
metadata:
  name: pgadmin
  namespace: lolz
  labels:
    postgres-operator.crunchydata.com/data: pgadmin
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 5050
  selector:
    postgres-operator.crunchydata.com/data: pgadmin
  sessionAffinity: None
  type: ClusterIP

```

If you are using Istio, this is an example of the VS

```elixir
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: pgadmin
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - pgadmin.aks-rofl16722.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: pgadmin.lolz.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```

If you are using nginx this is an example of the Ingress:

```elixir
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 5G
    nginx.ingress.kubernetes.io/proxy-read-timeout: 18000s
    nginx.ingress.kubernetes.io/proxy-send-timeout: 18000s
  name: pgadmin
  namespace: lolz
spec:
  ingressClassName: nginx
  rules:
  - host: pgadmin.aks-rofl16722.cicd.ginger.cn
    http:
      paths:
      - backend:
          service:
            name: lolz-production-pgadmin
            port:
              number: 5050
        path: /
        pathType: Prefix
```

# lolz integration

retrieve postgres cluster creds:

```yaml
HOST=$(kubectl -n lolz get secrets lolz-production-pguser-lolz \
--template={{.data.host}} | base64 -d) 

PASSWORD=$(kubectl -n lolz get secrets lolz-production-pguser-lolz \
--template={{.data.password}} | base64 -d)

echo $HOST
echo $PASSWORD
```

patch `pg-creds` secret:

```bash
kubectl -n lolz patch secret pg-creds -p='{"stringData":{"POSTGRES_HOST": "'${HOST}'","POSTGRES_PASSWORD": "'${PASSWORD}'","POSTGRESQL_ADMIN_PASSWORD": "'${PASSWORD}'","POSTGRESQL_PASSWORD": "'${PASSWORD}'","POSTGRES_USER": "lolz","POSTGRESQL_USER":"lolz"}}' -v=1
```

If the `pg-creds` secret doesn’t exist you will need to create the secret

```elixir
kubectl apply -f - << EOF
apiVersion: v1
stringData:
  POSTGRES_DB: lolz_production
  POSTGRES_HOST: lolz-production-primary.postgres.svc.cluster.local
  POSTGRES_PASSWORD: pa55w0rd
  POSTGRES_USER: lolz
  POSTGRESQL_ADMIN_PASSWORD: pa55w0rd
  POSTGRESQL_DATABASE: lolz_production
  POSTGRESQL_EFFECTIVE_CACHE_SIZE: 2048MB
  POSTGRESQL_MAX_CONNECTIONS: "500"
  POSTGRESQL_PASSWORD: pa55w0rd
  POSTGRESQL_SHARED_BUFFERS: 1024MB
  POSTGRESQL_USER: lolz
kind: Secret
metadata:
  name: pg-creds
  namespace: lolz
type: Opaque
EOF
```

# Accessing pgAdmin UI

Above we created an ingress/vs to gain access to pgadmin.  Go to the host defined in your vs/ingress to get to pgadmin (example… pgadmin.aks-rofl16722.cicd.ginger.cn)

**login to web UI:** grab credentials as done before, use following convention:

```yaml
email:    <PG_USER>**@pgo**
password: <PG_PASSWORD>
```

# Helpful commands

Example of connecting to the pg cluster from within the cluster

```jsx
psql -h $HOST -U lolz -d lolz_production
```

List the database to confirm connectivity

```jsx
psql -h $HOST -U lolz -d lolz_production
Password for user lolz:
psql (13.10 (Ubuntu 13.10-1.pgdg18.04+1), server 13.9)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

lolz_production=> \l
                                     List of databases
       Name       |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
------------------+----------+----------+-------------+-------------+-----------------------
 lolz_production | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =Tc/postgres         +
                  |          |          |             |             | postgres=CTc/postgres+
                  |          |          |             |             | lolz=CTc/postgres
 postgres         | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 |
 template0        | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
                  |          |          |             |             | postgres=CTc/postgres
 template1        | postgres | UTF8     | en_US.utf-8 | en_US.utf-8 | =c/postgres          +
                  |          |          |             |             | postgres=CTc/postgres
(4 rows)
```

Drop a database

```jsx
DROP DATABASE lolz_production;
```

Create a database

```jsx
CREATE DATABASE lolz_production;
```

Add full permissions to database

```jsx
GRANT ALL PRIVILEGES ON DATABASE lolz_production TO lolz;
```

### Connect to DB using port forwarding

First grab one of the names of the production pods 

```jsx
kubectl -n postgres get pods
```

```jsx
NAME                                          READY   STATUS      RESTARTS       AGE
lolz-production-backup-xbwg-kzx2j            0/1     Completed   0              11d
lolz-production-pgbouncer-6bfd6dffb9-g9qhz   2/2     Running     18 (17h ago)   11d
lolz-production-pgbouncer-6bfd6dffb9-s59rk   2/2     Running     18 (17h ago)   11d
lolz-production-pgha1-d8nq-0                 4/4     Running     36 (17h ago)   11d
lolz-production-pgha1-l5rh-0                 4/4     Running     36 (17h ago)   11d
lolz-production-pgha1-zht4-0                 4/4     Running     36 (17h ago)   11d
lolz-production-repo-host-0                  2/2     Running     18 (17h ago)   11d
```

Next you need to port forward the service with the command below

```jsx
kubectl -n lolz port-forward pod/lolz-production-pgha1-d8nq-0 :5432 
```

Pay attention tot he randomly selected local port that was provided. In my example I can get to the DB using 127.0.0.1:51647

```jsx
k port-forward pod/lolz-production-pgha1-d8nq-0 :5432 -n lolz
Forwarding from 127.0.0.1:51647 -> 5432
```

Install PG Admin

Here is how to connect to the DB using PG Admin

Right click on servers and select “Register Server”

Provide a Name


Now configure the connection settings. You can get the database password by doing the following

```jsx
kubectl -n postgres get secret lolz-production-pguser-lolz -ojsonpath='{.data.password}'
```


Now click “save”

![Untitled](crunchydata%20Postgres%20operator%207f6e13d9868f4798bdec0ecbb1ee7300/Untitled%202.png)