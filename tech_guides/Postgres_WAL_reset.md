# Postgres WAL reset

# intro

During normal operation, PostgreSQL writes all changes to the database to a write-ahead log (WAL) before actually updating the database. This allows for crash recovery and replication. The WAL is a sequence of records containing information about changes made to the database, such as `INSERT`, `UPDATE`, and `DELETE` statements.

When the WAL becomes corrupted or filled up, it can prevent the PostgreSQL instance from starting up or cause other issues. This is where **`pg_resetwal`** comes in.

**`pg_resetwal`** is a utility in PostgreSQL that resets the write-ahead log (WAL) and other control information, allowing the PostgreSQL instance to start up without replaying the old WAL records. It can also be used to recover from other issues such as a damaged system catalog or the inability to start up the PostgreSQL instance due to corruption in the data directory.

Specifically, **`pg_resetwal`** performs the following steps:

1. Resets the WAL control information in the **`pg_control`** file to its initial values.
2. Removes all existing WAL files, as they are no longer useful.
3. Creates a new, empty WAL file.
4. Sets the **`pg_xact`**, **`pg_clog`**, and **`pg_multixact`** directories back to their initial state.
5. Deletes any **`backup_label`** or **`tablespace_map`** files that may have been left over from previous backup or restore operations.

After running **`pg_resetwal`**, the PostgreSQL instance can start up and create a new, empty WAL. However, any data that was not yet written to the database or backed up is lost. Therefore, it is important to have a recent backup of the database before running **`pg_resetwal`**.

# procedure

1. **Backup your data**: Before performing any action, ensure you have a recent backup of your database. You can use tools like **`pg_dump`** or **`pg_basebackup`** to create backups.
2. **Stop the PostgreSQL instance**: Gracefully stop the PostgreSQL instance to prevent any additional writes to the database. You can do this by scaling down the Kubernetes deployment or StatefulSet to zero replicas, or by stopping the pod running PostgreSQL:
    
    ```
    bashCopy code
    kubectl scale --replicas=0 deployment/your-postgres-deployment
    
    ```
    
    or
    
    ```
    arduinoCopy code
    kubectl delete pod your-postgres-pod-name
    
    ```
    
3. **Create a debug container with PostgreSQL tools**: Since the PostgreSQL instance is not running, you need to create a temporary container with the necessary PostgreSQL tools, including **`pg_resetwal`**. Run the following command to create the container:
    
    ```
    kubectl run -i --tty --rm debug-postgres --image=postgres:your-version --restart=Never -- bash
    ```
    
    Replace **`your-version`** with the version of PostgreSQL you're running.
    
4. **Access the corrupted PostgreSQL data directory**: You need to access the data directory of the corrupted PostgreSQL instance. If you're using a Persistent Volume (PV) in Kubernetes, identify the PV and mount it to the temporary container you created:
    
    ```
    bashCopy code
    kubectl cp your-namespace/your-postgres-pod-name:/path/to/pgdata /local/path/to/pgdata
    
    ```
    
    Replace **`your-namespace`**, **`your-postgres-pod-name`**, and **`/path/to/pgdata`** with appropriate values.
    
5. **Run `pg_resetwal`**: Now, you can run the **`pg_resetwal`** command on the copied data directory:
    
    ```
    luaCopy code
    pg_resetwal -D /local/path/to/pgdata
    
    ```
    
6. **Verify the operation**: Check the output of the **`pg_resetwal`** command to ensure there were no errors or issues.
7. **Copy the data directory back**: Once you're confident that the operation was successful, copy the data directory back to the original pod or PV:
    
    ```
    bashCopy code
    kubectl cp /local/path/to/pgdata your-namespace/your-postgres-pod-name:/path/to/pgdata
    
    ```
    
8. **Restart the PostgreSQL instance**: Scale your deployment or StatefulSet back up, or start a new pod:
    
    ```
    bashCopy code
    kubectl scale --replicas=1 deployment/your-postgres-deployment
    
    ```
    
    or
    
    ```
    Copy code
    kubectl apply -f your-postgres-pod-definition.yaml
    
    ```
    
9. **Monitor logs and verify**: Monitor the logs of the restarted PostgreSQL instance and verify that it starts up correctly and without issues:
    
    ```
    Copy code
    kubectl logs -f your-postgres-pod-name
    
    ```
    
10. **Perform checks**: Perform integrity checks on your database using tools like **`pg_dump`** or by running **`SELECT pg_catalog.pg_tablespace_size(oid) FROM pg_catalog.pg_tablespace;`** to ensure the database is functioning correctly.

Remember, running **`pg_resetwal`** should be a last resort when troubleshooting PostgreSQL issues. Always try to recover from a backup or other methods before resorting to this command.