
# Seperate test instance for PostgreSQL
## Goal
Create a separate postgres deployment and PVC, for test purposes, keeping main postgres instance intact.


## Create test instance
1. apply yaml:
    ```bash
    kubectl apply -f deploy_pvc.yaml
    ```
2. exec to pod:
    ```bash
    kubectl exec -it deploy/pg2nd4test -- bash
    ```
## Create backup file from main postgres instance
4. in root user, grab the postgres password:
    
    ```bash
    env | grep -i pass
    ```
5. create backup file (you'll be prompted for password)
    
    ```bash
    pg_dump -h postgres -U dbuser -d production_db -Fc -v -f db-backup.sql
    ```
6. verify file size and location:
    ```bash
    ls -lah db-backup.sql;
    pwd
    ```
## Create empty database in test instance
1. start server:
    
    ```bash
    service postgresql start
    ```
        
2. switch user:
    
    ```bash
    su - postgres
    ```
3. enter pg console:
    
    ```bash
    psql
    ```
 3. create database:
    
    ```bash
    CREATE DATABASE production_db;
    ```
 2. list databases to check:
    
    ```bash
    \l
    ```
## Restore database from backup file in test instance
1. switch user:
    
    ```bash
    su - postgres
    ```
1. run restore process (provide exact location of backup file)
    ```bash
    pg_restore -d production_db -j 8 --verbose -x --no-owner /db-backup.sql
    ```
2. after restore is finished, enter console:
    ```bash
    psql -d production_db
    ```
2. list some random table (`users` in this case) to verify data existence:
    ```bash
    SELECT * FROM users;
    ```

## Create fresh new database and start postgres service

change user to postgres:

```bash
su postgres
```

edit postgres config, change to volume data dir, uncomment `listen_address` and set to all:

```bash
sed -i "s|^data_directory = '/var/lib/postgresql/12/main'|data_directory = '/data'|" /etc/postgresql/12/main/postgresql.conf
sed -i "s|^#listen_addresses = 'localhost'|listen_addresses = '*'|" /etc/postgresql/12/main/postgresql.conf
```

copy data from default data dir to volume:

```bash
cp -r /var/lib/postgresql/12/main/* /data/
```

change the owner of data dir & config/log files to postgres user:

```bash
chown -R postgres:postgres /data
chown postgres:postgres /etc/postgresql/12/main/postgresql.conf
chown postgres:postgres /var/log/postgresql/postgresql-12-main.log
```

add trusted host to HBA file:

```bash
echo "host    production_db postgres       10.0.0.0/8           trust" >> /etc/postgresql/12/main/pg_hba.conf
```

change permissions to data dir:

```bash
chmod 0700 /data
```

start the postgres server:

```bash
service postgresql start
```

create database:

```bash
psql
CREATE DATABASE production_db;
```

to access from another pod for test:

```bash
psql -h pg2nd4test -U postgres -d production_db
```

patch the pg-creds secret to work with this DB:

```bash
POSTGRES_HOST="pg2nd4test";
POSTGRES_USER="postgres";
POSTGRES_PASSWORD="";

kubectl patch secret pg-creds \
-p='{"stringData":{"POSTGRES_HOST": "'${POSTGRES_HOST}'","POSTGRES_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_ADMIN_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRES_USER": "'${POSTGRES_USER}'","POSTGRESQL_USER":"'${POSTGRES_USER}'"}}' -v=1
```

after saving the secret, print it back using the following command:

```bash
kubectl get secret pg-creds \
-o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```