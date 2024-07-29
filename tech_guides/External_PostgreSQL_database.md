# External PostgreSQL database

# Create the remote database

**AWS RDS:** [https://docs.aws.amazon.com/rds/index.html](https://docs.aws.amazon.com/rds/index.html)

**GCP CloudSQL:** [https://cloud.google.com/sql/docs](https://cloud.google.com/sql/docs)

**Azure Database for PostgreSQL:** [https://learn.microsoft.com/en-us/azure/postgresql/](https://learn.microsoft.com/en-us/azure/postgresql/)

### general guidelines:

- user should be `postgres`
- instance should have more resources than the current limit we set for our integrated PG
    
    ```ruby
    resources:
              limits:
                cpu: "12"
                memory: 32Gi
    ```
    
    so a recommended resource amount would be at least **12 CPU 32GB memory**
    

# Preparing the new instance

After the External PostgreSQL instance is up and running, we need to prepare it for integration:

<aside>
😊 to run `psql` commands, use the network debugger image:

```bash
kc run -i --tty network-debug --image=lolz/network-debugger:latest -- bash
```

</aside>

1. make sure the instance has an empty database named `lolz_production` beforehand
    
    ```sql
    psql -h <PG_HOST> -U <USERNAME>
    \list
    ```
    
    if not, create it:
    
    ```sql
    CREATE DATABASE lolz_production;
    \list
    ```
    

1. make sure your’e able to telnet the PG instance using port `5432`
from wherever it should be accessed, i.e app pod or one of the ctrl plain nodes)  
    
    ```yaml
    telnet PG_HOST 5432
    ```
  

### **Define credentials in secret:**

set vars:

```bash
POSTGRES_HOST="foo"
POSTGRES_USER="bar"
POSTGRES_PASSWORD="foobar"
```

patch the secret:

```bash
kubectl -n lolz patch secret pg-creds \
-p='{"stringData":{"POSTGRES_HOST": "'${POSTGRES_HOST}'","POSTGRES_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_ADMIN_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRESQL_PASSWORD": "'${POSTGRES_PASSWORD}'","POSTGRES_USER": "'${POSTGRES_USER}'","POSTGRESQL_USER":"'${POSTGRES_USER}'"}}' -v=1
```

after saving the secret, print it back using the following command:

```bash
kubectl -n lolz get secret pg-creds -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

verify the host/user/password values are correct.
there should be no line breaks between each line, a correct output would look like this:

```bash
POSTGRESQL_ADMIN_PASSWORD: **<DB_PASSWORD>**
POSTGRESQL_DATABASE: lolz_production
POSTGRESQL_EFFECTIVE_CACHE_SIZE: 2048MB
POSTGRESQL_MAX_CONNECTIONS: 500
POSTGRESQL_PASSWORD: **<DB_PASSWORD>**
POSTGRESQL_SHARED_BUFFERS: 1024MB
POSTGRESQL_USER: lolz
POSTGRES_DB: lolz_production
POSTGRES_HOST: postgres
POSTGRES_PASSWORD: **<DB_PASSWORD>**
POSTGRES_USER: lolz
```

### Verify connectivity:

check if theres a PG deploy

```bash
kubectl -n lolz get deploy | grep postgres
```

if so, scale down pg deployment, and delete the pg pod if it remains.

```bash
kubectl -n lolz scale deployment postgres --replicas=0
```

if its a fresh database, check seeder was able to populate the DB scheme:

```bash
kubectl -n lolz logs deploy/app -c seeder
```

if its an existing database, check lolz-app container connected to it:

```bash
kubectl -n lolz logs deploy/app -c lolz-app
```

# other notes

example for plain text values for all keys:

```
POSTGRESQL_ADMIN_PASSWORD: **<DB_PASSWORD>**
POSTGRESQL_DATABASE: lolz_production
POSTGRESQL_EFFECTIVE_CACHE_SIZE: 2048MB
POSTGRESQL_MAX_CONNECTIONS: 500
POSTGRESQL_PASSWORD: **<DB_PASSWORD>**
POSTGRESQL_SHARED_BUFFERS: 1024MB
POSTGRESQL_USER: **<DB_USERNAME>**
POSTGRES_DB: lolz_production
POSTGRES_HOST: **<DB_ENDPOINT>**
POSTGRES_PASSWORD: **<DB_PASSWORD>**
POSTGRES_USER: **<DB_USERNAME>**
```

<aside>
⛔ make sure you encode all values to base64, using echo with the `-n` flag.
it prevents adding any additional characters to the encoded string, which will cause issues when trying to connect using those values.

</aside>

```bash
echo -n "blablabla" | base64
```