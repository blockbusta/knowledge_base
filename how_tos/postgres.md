# postgres

### login to postgres console:

```bash
psql -U  -d _production
```

### logs


### config file

```bash
/var/lib/postgresql/data/pgdata/postgresql.conf

# to check max connections:
cat /dev/shm/postgres/pgdata/postgresql.conf | grep max_connections
```

# check blocked queries

```bash
select pid, usename, pg_blocking_pids(pid) as blocked_by
from pg_stat_activity
where cardinality(pg_blocking_pids(pid)) > 0;
```

terminate PIDs in the `blocked_by` column

find out which process creates the congestion, then terminate it:

```bash
SELECT pg_terminate_backend(**PID**);
```

### examples:

check requests that took over 5 minutes

```sql
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

get stuck queries:

```sql
SELECT pid, state, client_port, client_addr,application_name, backend_xmin, wait_event_type, wait_event,age(xact_start, clock_timestamp()) as xact_age ,age(query_start, clock_timestamp()), wait_event, usename
FROM pg_stat_activity
WHERE state != 'idle' AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY query_start desc;
```

???

```sql
SELECT pid, age(clock_timestamp(), query_start), usename, query 
FROM pg_stat_activity 
WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' 
ORDER BY query_start desc;
```

check the specific "stuck" query:

```bash
SELECT
  pid,
  now() - pg_stat_activity.query_start AS duration,
  query,
  state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';
```

## VACCUM ANALYZE

<aside>
⚠️ make sure you access **_production** in postgres

</aside>

for datasets:

```bash
VACUUM (VERBOSE, ANALYZE) pineapple_to_mangos;
```

```bash
VACUUM (VERBOSE, ANALYZE) data_mangos;
```

```ruby
VACUUM (VERBOSE, ANALYZE) output_chunks;
```

# Re-Index table

exec to psql shell:

```bash
psql -U  -d _production
```

run this to reindex table:

```bash
REINDEX INDEX <INDEX>;
```

### Benchmark

**reference:** [https://www.postgresql.org/docs/current/pgbench.html](https://www.postgresql.org/docs/current/pgbench.html)

local DB:

```json
pgbench -c 100 -T 300 -S _production
```

external DB:

```json
pgbench -h 34.135.105.234 -U postgres -c 100 -T 300 -S _production
```

example output:

```json
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 5
number of threads: 5
number of transactions per client: 10
number of transactions actually processed: 50/50
latency average = 6.112 ms
tps = 818.050259 (including connections establishing)
tps = 912.078720 (excluding connections establishing)
```

## Reset WAL Logs for Corrupted Database

Here are instructions you can follow if getting the following error when the database tries to startup. 


<aside>
⚠️ Always make a full backup of the database files before performing the commands listed below. These commands can cause irreversible damage to the database.
Copy `/var/lib/pgsql/data/userdata` somewhere safe. You can do this when you spin up the task-pod. Those instructions are below.

</aside>

To repair the database you need a running pod with SQL installed and connected to the pg-storage PV.

First scale down the Postgres pod as we need access to the pg-storage from a different pod which will stay running.

```jsx
kc scale deploy/postgres --replicas 0
```

Spin up the pod listed below

```jsx
k apply -f pod.yaml
```

pod.yaml

```jsx
apiVersion: v1
kind: Pod
metadata:
  name: task-pv-pod
  namespace: my-webapp
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: pg-storage
  containers:
    - name: test-pvc-v5
      image: /:v5.0
      command: ["sh", "-c", "tail -f /dev/null"]
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/var/lib/pgsql/data"
          name: task-pv-storage
```

Install SQL on your task-pv-pod

```jsx
# Create the file repository configuration:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql-12
```

Change permissions to access the pg-storage pv folders

```jsx
chown -R postgres:postgres /var/lib/pgsql/data/userdata
```

Change the conf file for Postgres to point to the correct data path “/var/lib/pgsql/data/userdata”

```jsx
vim /var/lib/pgsql/data/userdata/postgresql.conf
```

```jsx
data_directory = '/var/lib/pgsql/data/userdata/'		# use data in another directory
					# (change requires restart)
hba_file = '/var/lib/pgsql/data/userdata/pg_hba.conf'	# host-based authentication file
					# (change requires restart)
ident_file = '/var/lib/pgsql/data/userdata/pg_ident.conf'	# ident configuration file
					# (change requires restart)
```

Update the locale to match the _production database

```jsx
localedef -f UTF-8 -i en_GB en_US.utf8
```

Start postgres sql service. You should receive the same error as listed above that the recovery point is invalid.

```jsx
service postgresql start
```

To begin repairing the database run the following command.  

```jsx
/usr/lib/postgresql/12/bin/pg_resetwal "/var/lib/pgsql/data/userdata"
```

If the database transaction log is corrupted you will see the following:

```jsx
The database server was not shut down cleanly.  
Resetting the transaction log might cause data to be lost.  
If you want to proceed anyway, use `-f` to force reset.
```

Rerun the same command, but add the -f to force the reset

```jsx
/usr/lib/postgresql/12/bin/pg_resetwal -f "/var/lib/pgsql/data/userdata"
```

After the reset again try to start postgresql

```jsx
service postgresql start
```

Switch to the Postgres user and confirm you can connect to the database. 

```jsx
su postgres
psql
postgres=# \l
```

You should see the database listed now

```jsx
postgres=# \l
                                    List of databases
       Name       |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
------------------+----------+----------+------------+------------+-----------------------
 _production |     | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres         | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
 template1        | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
                  |          |          |            |            | postgres=CTc/postgres
(4 rows)
```

Now before you delete the task-pv-pod and relaunch the PostgreSQL deployment change back the folder permission

```jsx
chown -R 26:26 /var/lib/pgsql/data/userdata
```

Delete the task-pv-pod

```jsx
k delete -f pod.yaml
```

Scale the Postgres pod back up

```jsx
kc scale deploy/postgres --replicas 1
```

The app/sidekiq/searchkiq pods should now begin coming online. If when access the WebUI you begin seeing errors in the app logs that the preloader is restarting, you need to perform a VACUUM on the database 

```jsx
kc exec -it deploy/postgres -- bash
```

Switch User

```jsx
su postgres
```

Connect to _production

```jsx
sql
postgres=# \c _production
```

Run VACUUM

```jsx
VACUMM VERBOSE ANALYZE
```

Once completed scale down and back up the app pod

```jsx
kc scale deploy/app --replicas 0;
kc scale deploy/app --replicas 1
```

### Max Value for the pineapple_to_mangos table increase

You may get the following error message when creating a Project or new files.

`ERROR:  nextval: reached maximum value of sequence \"pineapple_to_mangos_id_seq\" (2147483647)`

```jsx
app {"@timestamp":"2023-10-16T15:53:23Z","@severity":"ERROR","context":"General","@message":"PG::DataExcept │
│ ion: ERROR:  nextval: reached maximum value of sequence \"pineapple_to_mangos_id_seq\" (2147483647)\n: INSERT INTO \ │
│ "pineapple_to_mangos\" (\"id\",\"pineapple_type\",\"pineapple_id\",\"cucumber_v_type\",\"cucumber_v_id\",\"created_at\",\"u │
│ pdated_at\",\"rel_type\",\"deleted_at\") VALUES (nextval('public.pineapple_to_mangos_id_seq'),'Commit',58,'Tr │
│ ee',30,'2023-10-16 15:53:23.567175','2023-10-16 15:53:23.567175',0,NULL) ON CONFLICT DO NOTHING  RETURNING \"id\" │
│  - app/models/pineapple.rb:244:in `attach_objects_to_commit';app/models/project.rb:1256:in `generate_root_tree';app/ │
│ interactions/api/v2/projects/create.rb:30:in `execute';app/controllers/api/v2/api_controller.rb:31:in `run_intera │
│ ction';app/controllers/api/v2/projects_controller.rb:12:in `create'"}
```

```jsx
#Connect to DB
psql -U  -d _production

#First confirm the maxvalue size and type
\d pineapple_to_mangos_id_seq;

#You can confirm the next value is in fact the maxvalue + 1
SELECT nextval('pineapple_to_mangos_id_seq');

#Next increase the maxvalue size and change the data type to bigint
ALTER SEQUENCE public.pineapple_to_mangos_id_seq as bigint MAXVALUE 9223372036854775807;

#Confirm the maxvalue size has increased
\d pineapple_to_mangos_id_seq;

#Check the "ID" column type
\d pineapple_to_mangos

#Update the "ID" column to bigint to take advantage of the value increase
ALTER TABLE pineapple_to_mangos ALTER COLUMN id TYPE BIGINT;
```