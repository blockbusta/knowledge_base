## Create PostgreSQL database

create ns
```bash
kubectl create ns testdb
```


create file `runai_db_init.sql` with the DB init script:
```sql
CREATE DATABASE backend;

CREATE ROLE test_b WITH LOGIN PASSWORD 'test_b_123';

GRANT ALL PRIVILEGES ON DATABASE backend TO test_b;
```



save it as a secret:
```bash
kubectl -n testdb create secret generic \
runai-db-init \
--from-file=runai_db_init.sql=runai_db_init.sql
```


add the helm repo:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```


install the postgresql helm chart:

```bash
helm -n testdb install postgresql bitnami/postgresql \
--set primary.initdb.scriptsSecret=runai-db-init \
--set global.postgresql.auth.postgresPassword=dbadmin123456 \
--set image.tag=16.6.0-debian-12-r2 \
--debug
```

> helm chart: https://artifacthub.io/packages/helm/bitnami/postgresql 

note i used the tag for the 16.6 postgres version, as i needed to use 16.6 exact version. you can remove that flag and use the latest if it doesn’t matter.

check the pod is running and no errors in logs:
```bash
k -n testdb logs postgresql-0 -f
```

## Test database connection

create pod for testing connection to DB:
```bash
kubectl -n runai-backend run pgdebugger --image=postgres:16.6 --command -- sleep infinity
```

> matching the version 16.6 of postgres used in the helm chart

exec into pod:
```bash
kubectl -n runai-backend exec -it pgdebugger -- bash
```

test DB connection from pod for all users:

backend:

```bash
PGPASSWORD="test_b_123" psql -h postgresql.testdb.svc.cluster.local -p 5432 -U test_b -d backend
```

postgres (admin)
```bash
PGPASSWORD="dbadmin123456" psql -h postgresql.testdb.svc.cluster.local -p 5432 -U postgres -d backend
```


```
      password: test_b_123
      username: test_b
      database: backend
      scheme: backend
      port: 5432
      host: postgresql.testdb.svc.cluster.local
```
