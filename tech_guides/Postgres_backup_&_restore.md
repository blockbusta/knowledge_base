# Postgres backup & restore

# Backup to file (source env)    

1. define PG pod name & exec into it:
    
    ```bash
    POSTGRES=$(kubectl get pods -l=app=postgres -nlolz -o jsonpath='{.items[0].metadata.name}')
    kubectl -n lolz exec -it ${POSTGRES} -- bash
    ```
    

1. backup the `lolz_production` database into file:
    
    <aside>
    ⚠️ consider running on a dedicated VM in a detached tmux session, as this might take some time depending on DB size.
        
    </aside>
    
    <aside>
    ℹ️ if prompted for password, try using `POSTGRES_PASSWORD` instead.
    
    </aside>
    
    ```bash
    export PGPASSWORD=$POSTGRESQL_PASSWORD;
    pg_dump -h postgres -U lolz -d lolz_production \
    -Fc -v -f lolz-db-backup.sql
    ```
    
    **optional**: check the size of the backup file grows:
    
    ```yaml
    kubectl -n lolz exec -it ${POSTGRES} bash
    watch ls -lah --block-size=M lolz-db-backup.sql
    ```
    

1. copy backup file locally:
    
    ```bash
    kubectl -n lolz cp ${POSTGRES}:/opt/app-root/src/lolz-db-backup.sql ./lolz-db-backup.sql;
    ls -lah lolz-db-backup.sql
    ```
    

# Restore from file (target env)

1. define PG pod name
    
    ```bash
    POSTGRES=$(kubectl get pods -l=app=postgres -nlolz -o jsonpath='{.items[0].metadata.name}')
    ```
    
1. copy backup file to postgres pod:
    
    ```bash
    kubectl -n lolz cp lolz-db-backup.sql ${POSTGRES}:/opt/app-root/src
    ```
    

1. exec into PG pod:
    
    ```bash
    kubectl -n lolz exec -it ${POSTGRES} bash
    ```
    
2. prepare database for data restoration:
    
    <aside>
    ⚠️ this is only if you are restoring to a PG pod that already launched and seeded
    
    </aside>
    
    enter PG console
    
    ```yaml
    psql
    ```
    
    make sure the command line shows this:
    
    ```yaml
    postgres=#
    ```
    
    <aside>
    ⛔ **do not run from the** `lolz_production` **database!** it will refuse connections
    
    </aside>
    
    then run the following one-by-one:
    
    ```sql
    UPDATE pg_database SET datallowconn = 'false' WHERE datname = 'lolz_production';
    ALTER DATABASE lolz_production CONNECTION LIMIT 0;
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'lolz_production';
    DROP DATABASE lolz_production;
    \l
    CREATE DATABASE lolz_production;
    \l
    ```
    
    <aside>
    ℹ️ list databases using `\l`
    
    </aside>
    
    then exit the PG console
    

```jsx
\q 
```

1. restore DB from backup file:
**to local PG:**
    
    ```bash
    export PGPASSWORD=$POSTGRESQL_PASSWORD;
    pg_restore -h postgres -p 5432 -U lolz -d lolz_production \
    -j 8 --verbose -x --no-owner lolz-db-backup.sql
    ```
    
    **to a remote PG instance:**
    
    define vars:
    
    ```bash
    export PG_USER="<external_pg_username>";
    export PGPASSWORD="<external_pg_password>";
    export PG_ENDPOINT="<external_pg_endpoint>";
    ```
    
    create the database:
    
    ```bash
    psql -h ${PG_ENDPOINT} -p 5432 -U ${PG_USER}
    CREATE DATABASE lolz_production;
    \l
    ```
    
    restore:
    
    ```bash
    pg_restore -h ${PG_ENDPOINT} -p 5432 -U ${PG_USER} -d lolz_production --verbose -x --no-owner lolz-db-backup.sql
    ```
        
    a correct restore process will look like this, ending with the last line:
    
    ```bash
    pg_restore: processing data for table "public.table2"
    ...
    ...
    pg_restore: finished main parallel loop
    ```
    
check the app is running, and that you are able to access all old projects/datasets & able to create new ones as well.

## Times for psql processes

took this database for example:

```yaml
List of databases
-[ RECORD 1 ]-----+-------------------------------------------
Name              | lolz_production
Owner             | postgres
Encoding          | UTF8
Collate           | en_US.utf8
Ctype             | en_US.utf8
Access privileges |
Size              | 10 GB
Tablespace        | pg_default
Description       |
```

size per table:

```yaml
schema_name     |                             relname                             |    size    | table_size
--------------------+-----------------------------------------------------------------+------------+------------
 public             | table4                                                      | 1527 MB    | 1600978944
 public             | table1                                                      | 1444 MB    | 1513619456
 public             | table9                                                      | 972 MB     | 1019674624
```

**dump: no compression**

```yaml
pg_dump -h postgres -d lolz_production \
-Z 0 -Fc -v -f lolz-db-backup_nocomp.sql

real	1m37.072s
user	0m4.204s
sys	0m10.720s

-rw-r--r-- 1 postgres postgres 5.7G Dec 27 14:31 lolz-db-backup_nocomp.sql
```

**dump: default compression** (no compression flag set, level = 6)

```yaml
pg_dump -h postgres -d lolz_production \
-Fc -v -f lolz-db-backup_def-comp-6.sql

real	1m31.752s
user	1m16.312s
sys	0m4.057s

-rw-r--r-- 1 postgres postgres 554M Dec 27 14:55 lolz-db-backup_def-comp-6.sql
```

**dump: max compression**

```yaml
pg_dump -h postgres -d lolz_production \
-Z 9 -Fc -v -f lolz-db-backup_nocomp.sql

real	6m1.198s
user	5m44.798s
sys	0m6.318s

-rw-r--r-- 1 postgres postgres 506M Dec 27 14:51 lolz-db-backup_comp-9.sql
```

**restore (from the default compression dump file)**

```yaml
pg_restore -h postgres -p 5432 -d lolz_production \
-j 8 --verbose -x --no-owner lolz-db-backup_def-comp-6.sql

00:06:30 total
```

## helpful commands

show records in tabular format:

```sql
\x auto
```

show databases:

```yaml
\l
```

show databases with size:

```yaml
\l+
```

show all tables:

```sql
\dt *.*
```

show last few records from table:

```bash
SELECT * FROM mangos LIMIT 10;
```

show all tables with size:

```sql
SELECT
  schema_name,
  relname,
  pg_size_pretty(table_size) AS size,
  table_size

FROM (
       SELECT
         pg_catalog.pg_namespace.nspname           AS schema_name,
         relname,
         pg_relation_size(pg_catalog.pg_class.oid) AS table_size

       FROM pg_catalog.pg_class
         JOIN pg_catalog.pg_namespace ON relnamespace = pg_catalog.pg_namespace.oid
     ) t
WHERE schema_name NOT LIKE 'pg_%'
ORDER BY table_size DESC;
```

example output:

```yaml
 schema |             relname              |    size    | table_size
--------------------+----------------------+------------+------------
 public | pineapple_changes                   | 1527 MB    | 1600978944
 public | pineapple_to_mangos          | 1444 MB    | 1513619456
 public | chart_chunks                     | 972 MB     | 1019674624
 public | pineapple_to_cucumber_indexing          | 832 MB     |  872251392
 public | index_pineapple_changes_on_fullpath | 604 MB     |  633397248
...
```

# **verifying row count**

if its a very sensitive/large database, we can take an extra safety measure by checking the total amount of rows in the database: once before creating the backup, and another after restoration.

run this in psql, before backup, and after restore.

```sql
create or replace function 
count_rows(schema text, tablename text) returns integer
as
$body$
declare
  result integer;
  query varchar;
begin
  query := 'SELECT count(1) FROM ' || schema || '.' || tablename;
  execute query into result;
  return result;
end;
$body$
language plpgsql;

\o /opt/app-root/src/lolzdb_count.txt

select 
  table_schema,
  table_name, 
  count_rows(table_schema, table_name)
from information_schema.tables
where 
  table_schema not in ('pg_catalog', 'information_schema') 
  and table_type='BASE TABLE'
order by 3 desc;

\o
```

will create the following file `lolzdb_count.txt`

```bash
table_schema  |             table_name              | count_rows
--------------+-------------------------------------+------------
 public       | mangos                       |      14562
 public       | output_chunks                       |       7062
 public       | resource_stats_chunks               |       5937
 public       | stats_chunks                        |       2900
 public       | pineapple_to_mangos             |       1258
 public       | chart_chunks                        |       1044
...
(167 rows)
```

then we can runn diff on the two files to verify they are identical

```bash
diff lolzdb_count_backup.txt lolzdb_count_restore.txt
```

[Using network debugger pod](Postgres%20backup%20&%20restore%20745425f342144cc2a739b6ad3a69c99d/Using%20network%20debugger%20pod%202cfd6b7b7a134ac7a3caea840827910a.md)