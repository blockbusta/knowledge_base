# Postgres not accepting connections

when PG pod is in `crashloopbackoff`, and the pod logs show:

```sql
...
server not accepting connections
```

this error appears after postgres pod gets terminated abruptly, usually after the nodes underlying hardware been forcefully shutdown, either manually or due to a power outage in the data center.

to fix that, we’ll need to mount the database PVC onto an additional deployment, then start the server, and reset connections.

first, scale down ctrl plain:

```ruby
kubectl -n lolz scale deploy \
lolz-operator app sidekiq searchkiq systemkiq scheduler \
--replicas=0
```

then scale down postgres deployment

```ruby
kubectl -n lolz scale deploy postgres --replicas=0
```

create the deployment:

```ruby
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-debugger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ubuntu-machine
  template:
    metadata:
      labels:
        app: ubuntu-machine
    spec:
      volumes:
        - name: cool-vol
          persistentVolumeClaim:
            claimName: pg-storage
      containers:
      - name: ubuntu
        image: lolz/network-debugger:1.4
        command: ["/bin/sleep", "36500d"]
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: "/pg-data"
          name: cool-vol
        resources:
          limits:
            cpu: "1"
            memory: 2G
          requests:
            cpu: "1"
            memory: 2G
      restartPolicy: Always
```

once the pod is running, exec into it:

```ruby
kc exec -it deploy/postgres-debugger -- bash
```

configure postgres to use the data path where the PG PVC is mounted:

```sql
vim /etc/postgresql/12/main/postgresql.conf
```

change to this and save:

```sql
data_directory = '/pg-data/userdata'
```

change the postgres user ID to the ID of the user who initially created the DB

```sql
usermod -u 26 postgres
```

change the owner of the config and log files to postgres user

```sql
chown postgres:postgres /etc/postgresql/12/main/postgresql.conf
chown postgres:postgres /var/log/postgresql/postgresql-12-main.log
```

start the postgres server:

```sql
service postgresql start
```

### The solution:

enter PG console:

```bash
psql -h localhost -p 5432 -U lolz lolz_production
```

allow connections on **all** databases:

```sql
ALTER DATABASE postgres ALLOW_CONNECTIONS true;
ALTER DATABASE lolz_production ALLOW_CONNECTIONS true;
ALTER DATABASE template0 ALLOW_CONNECTIONS true;
ALTER DATABASE template1 ALLOW_CONNECTIONS true;
```

then exit, scale this deployment down

```bash
kubectl -n lolz scale deploy postgres-debugger --replicas=0
```

and scale postgres pod back up:

```bash
kubectl -n lolz scale deploy postgres --replicas=0
```

after verifying that postgres pod is up and running, scale the ctrl plain back up:

```bash
kubectl -n lolz scale deploy \
lolz-operator app sidekiq searchkiq systemkiq scheduler \
--replicas=1
```

**optional thing that resolved another issue:**

change `listen_address` from '`localhost'` to `'0.0.0.0'` within `postgresql.conf`

```bash
listen_address = '0.0.0.0'
```

# create empty lolz database

change user to postgres:

```yaml
su postgres
```

edit postgres config, change to volume data dir, uncomment `listen_address` and set to all:

```bash
sed -i "s|^data_directory = '/var/lib/postgresql/12/main'|data_directory = '/data'|" /etc/postgresql/12/main/postgresql.conf
sed -i "s|^#listen_addresses = 'localhost'|listen_addresses = '*'|" /etc/postgresql/12/main/postgresql.conf
```

copy data from default data dir to volume:

```yaml
cp -r /var/lib/postgresql/12/main/* /data/
```

change the owner of data dir & config/log files to postgres user:

```sql
chown -R postgres:postgres /data
chown postgres:postgres /etc/postgresql/12/main/postgresql.conf
chown postgres:postgres /var/log/postgresql/postgresql-12-main.log
```

add trusted host to HBA file:

```bash
echo "host    lolz_production postgres       10.0.0.0/8           trust" >> /etc/postgresql/12/main/pg_hba.conf
```

change permissions to data dir:

```yaml
chmod 0700 /data
```

start the postgres server:

```sql
service postgresql start
```

create database:

```bash
psql
CREATE DATABASE lolz_production;
```

to access from another pod for test:

```bash
psql -h pg2nd4test -U postgres -d lolz_production
```

patch the pg-creds secret to work with this DB:

```bash
POSTGRES_HOST="pg2nd4test";
POSTGRES_USER="postgres";
POSTGRES_PASSWORD="";

kubectl -n lolz patch secret pg-creds \
-p='{"stringData":{"POSTGRES_HOST": "'${POSTGRES_HOST}'","POSTGRES_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_ADMIN_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRES_USER": "'${POSTGRES_USER}'","POSTGRESQL_USER":"'${POSTGRES_USER}'"}}' -v=1
```

after saving the secret, print it back using the following command:

```bash
kubectl -n lolz get secret pg-creds \
-o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```