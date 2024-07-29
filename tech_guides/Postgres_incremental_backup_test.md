# Postgres incremental backup test

# **Continuous Archiving and Point-in-Time Recovery (PITR)**

<aside>
ℹ️ according to official docs for current version 12.5: [https://www.postgresql.org/docs/12/continuous-archiving.html](https://www.postgresql.org/docs/12/continuous-archiving.html)

</aside>

### **Setting Up WAL Archiving**

**cluster data directory:**

```bash
/var/lib/pgsql/data/userdata
```

**postgres config file:**

```bash
/var/lib/pgsql/data/userdata/postgresql.conf
```

To enable WAL archiving, set the following in PG config: 

`wal_level` to **replica** or higher

`archive_mode` to **on**

`archive_command` specify the shell command to use

```bash
archive_command = 'test ! -f /var/lib/pgsql/data/backups/%f && cp %p /var/lib/pgsql/data/backups/%f'
```

this command uses the `backups` folder path i chose under the PVC mount path in PG pod:

```bash
/var/lib/pgsql/data/backups
```

After the `%p` and `%f` parameters have been replaced, the actual command executed might look like this:

```bash
test ! -f /var/lib/pgsql/data/backups/00000001000000A900000065 && cp pg_wal/00000001000000A900000065 /var/lib/pgsql/data/backups/00000001000000A900000065
```

A similar command will be generated for each new file to be archived.

# `pg_basebackup` command:

**params:**

- `-h` host
- `-U` username

*no need to state database param, can’t pick specific database*

- `-v` verbose
- `-P` show progress
- `-F` output format (`p`lain (default), `t`ar)
- `-z` compress tar output using gzip
- `-D` output directory (will be created if doesn’t exist, must be empty)

### tar output format example:

command:

```bash
export PGPASSWORD=$POSTGRESQL_PASSWORD;
pg_basebackup -h postgres -U lolz -v -P -F tar -z -D /var/lib/pgsql/data/jackson-test
```

`base.tar.gz` **file size**: 14MB (13% of original size)

```bash
bash-4.2$ ls -lah /var/lib/pgsql/data/jackson-test

total 14M
drwx--S--- 2 postgres postgres 4.0K Feb  8 12:20 .
drwxrwsr-x 5 root     postgres 4.0K Feb  8 12:20 ..
-rw------- 1 postgres postgres  14M Feb  8 12:20 base.tar.gz
-rw------- 1 postgres postgres  17K Feb  8 12:20 pg_wal.tar.gz
```

### default output format example:

command:

```bash
export PGPASSWORD=$POSTGRESQL_PASSWORD;
pg_basebackup -h postgres -U lolz -v -P -D /var/lib/pgsql/data/jackson-test
```

directory size:

```bash
bash-4.2$ du -hs /var/lib/pgsql/data/jackson-test

107M	/var/lib/pgsql/data/jackson-test
```

directory content:

```bash
bash-4.2$ ls -lah /var/lib/pgsql/data/jackson-test

total 136K
drwx--S--- 20 postgres postgres 4.0K Feb  8 12:16 .
drwxrwsr-x  5 root     postgres 4.0K Feb  8 12:16 ..
-rw-------  1 postgres postgres    3 Feb  8 12:16 PG_VERSION
-rw-------  1 postgres postgres  226 Feb  8 12:16 backup_label
drwx------  6 postgres postgres 4.0K Feb  8 12:16 base
-rw-------  1 postgres postgres   30 Feb  8 12:16 current_logfiles
drwx------  2 postgres postgres 4.0K Feb  8 12:16 global
drwx------  2 postgres postgres 4.0K Feb  8 12:16 log
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_pineapple_ts
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_dynshmem
-rw-------  1 postgres postgres 4.9K Feb  8 12:16 pg_hba.conf
-rw-------  1 postgres postgres 1.6K Feb  8 12:16 pg_ident.conf
drwx------  4 postgres postgres 4.0K Feb  8 12:16 pg_logical
drwx------  4 postgres postgres 4.0K Feb  8 12:16 pg_multixact
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_notify
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_replslot
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_serial
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_snapshots
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_stat
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_stat_tmp
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_subtrans
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_tblspc
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_twophase
drwx------  3 postgres postgres 4.0K Feb  8 12:16 pg_wal
drwx------  2 postgres postgres 4.0K Feb  8 12:16 pg_xact
-rw-------  1 postgres postgres   88 Feb  8 12:16 postgresql.auto.conf
-rw-------  1 postgres postgres  27K Feb  8 12:16 postgresql.conf
```