# Redis backup & restore

# Redis Backup
    
2. Get redis password from `redis-creds` secret:
    
    ```jsx
    REDIS_PASS=$(kubectl -n lolz get secret redis-creds -o yaml | \
    grep lolz_REDIS_PASSWORD -m 1 | awk '{print $2}');
    echo $REDIS_PASS
    ```
    
    <aside>
    ℹ️ redis-cli uses the base64 **encoded** password, no need to decode
    
    </aside>
    
3. Create redis dump:
    
    ```bash
    kubectl -n lolz exec -it deploy/redis -- bash -c \
    "redis-cli -a ${REDIS_PASS} save; ls -lah /data/dump.rdb"
    ```
    
    <aside>
    ℹ️ **OPTIONAL**: print all keys saved in redis, save aside for later comparision:
    
    ```bash
    kubectl -n lolz exec -it deploy/redis -- bash -c \
    "redis-cli -a ${REDIS_PASS} KEYS *" \
    > redis_all_keys_pre-migration.txt
    ```
    
    </aside>
    

1. Copy redis dump file locally
    
    ```jsx
    REDIS_POD=$(kubectl -n lolz get pods -l=app=redis \
    -o jsonpath='{.items[0].metadata.name}');
    kubectl -n lolz cp $REDIS_POD:/data/dump.rdb dump.rdb;
    ls -lah dump.rdb
    ```
    

# Redis Restore

1. Copy `dump.rdb` to new Redis pod
    
    ```jsx
    REDIS_POD=$(kubectl -n lolz get pods -l=app=redis \
    -o jsonpath='{.items[0].metadata.name}');
    kubectl -n lolz cp dump.rdb $REDIS_POD:/data/dump.rdb
    ```
    
2. Change the name of the AOL file to `.old` 
    
    ```jsx
    kubectl -n lolz exec -it $REDIS_POD -- \
    mv /data/appendonly.aof /data/appendonly.aof.old;
    kubectl -n lolz exec -it $REDIS_POD -- \
    ls -lah /data/appendonly.aof.old;
    ```
    

1. Grab the current `redis.conf` from `redis-creds` secret, decode it and change its `appendonly` value from `yes` to `no`
    
    ```jsx
    kubectl -n lolz get secret redis-creds -o yaml \
    | grep "redis.conf" -m 1 | awk '{print $2}' \
    | base64 -d | sed -e 's/yes/no/g' > tmp-redis-secret;
    cat tmp-redis-secret
    ```
    

1. Encode the value back to base64:
    
    ```bash
    ENCODED_REDIS_SECRET=$(cat tmp-redis-secret | base64 -w 0);
    echo $ENCODED_REDIS_SECRET
    ```
    
    for macos (???)
    
    ```bash
    ENCODED_REDIS_SECRET=$(cat tmp-redis-secret | base64 -b 0);
    echo $ENCODED_REDIS_SECRET
    ```
    

1. Then patch the secret with the new value:
    
    ```yaml
    kubectl -n lolz patch secret redis-creds --type=merge \
    -p '{"data": {"redis.conf": "'${ENCODED_REDIS_SECRET}'"}}'
    ```
    

1. Verify the `appendonly` value is set to `no` after patching the secret:
    
    ```jsx
    kubectl -n lolz get secret redis-creds -o yaml \
    | grep "redis.conf" -m 1 | awk '{print $2}'| base64 -d
    ```
    
2. Delete redis pod to trigger a restore:
    
    ```jsx
    kubectl -n lolz delete pod $REDIS_POD
    ```
    

1. Verify new redis pod is up and running:
    
    ```jsx
    kubectl -n lolz get pods -l=app=redis
    ```
    
    <aside>
    ℹ️ **OPTIONAL**: verify the restoration of the old dump by comparing file from before:
    
    ```bash
    kubectl -n lolz exec -it deploy/redis -- bash -c \
    "redis-cli -a ${REDIS_PASS} KEYS *" \
    > redis_all_keys_post-migration.txt
    ```
    
    </aside>
        

# Additional notes

## print out all keys sizes

grab encoded password:

```yaml
kubectl -n lolz get secret redis-creds -o yaml | \
grep lolz_REDIS_PASSWORD -m 1
```

replace the value in `redis_cmd` with actual password and run:

```yaml
human_size() {
        awk -v sum="$1" ' BEGIN {hum[1024^3]="Gb"; hum[1024^2]="Mb"; hum[1024]="Kb"; for (x=1024^3; x>=1024; x/=1024) { if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x]; break; } } if (sum<1024) print "1kb"; } '
}

redis_cmd='redis-cli -a **lolz_REDIS_PASSWORD** '

# get keys and sizes
for k in `$redis_cmd keys "*"`; do key_size_bytes=`$redis_cmd debug object $k | perl -wpe 's/^.+serializedlength:([\d]+).+$/$1/g'`; size_key_list="$size_key_list$key_size_bytes $k\n"; done

# sort the list
sorted_key_list=`echo -e "$size_key_list" | sort -n`

# print out the list with human readable sizes
echo -e "$sorted_key_list" | while read l; do
    if [[ -n "$l" ]]; then
        size=`echo $l | perl -wpe 's/^(\d+).+/$1/g'`; hsize=`human_size "$size"`; key=`echo $l | perl -wpe 's/^\d+(.+)/$1/g'`; printf "%-10s%s\n" "$hsize" "$key";
    fi
done
```