# copy corrupt postgres table to new table

enter PG console:

```bash
psql -U db_admin -d db_production
```

check record count in current table:

```sql
SELECT count(*) FROM test;
```

create the new table with all of the indexes and columns of the old one:

```sql
CREATE TABLE test_copy ( LIKE test INCLUDING ALL);
```

run loop in PG:

```sql
DO
$$DECLARE
   c CURSOR FOR SELECT * FROM test;
   r test;
   cnt bigint := 0;
BEGIN
   OPEN c;

   LOOP
      cnt := cnt + 1;

      /* block to start a subtransaction for each row */
      BEGIN
         FETCH c INTO r;

         EXIT WHEN NOT FOUND;
      EXCEPTION
         WHEN OTHERS THEN
            /* there was data corruption fetching the row */
            RAISE WARNING 'skipped corrupt data, at row number: %', cnt;

            MOVE c;

            CONTINUE;
      END;

      /* row is good, salvage it */
      INSERT INTO test_copy VALUES (r.*);
   END LOOP;
END;$$;
```

check record count in new table:

```sql
SELECT count(*) FROM test_copy;
```

change current table name to old:

```sql
ALTER TABLE test RENAME TO test_old;
```

and new table to original table name:

```sql
ALTER TABLE test_copy RENAME TO test;
```