# redis

## manually shutdown redis service from container (without killing pod)

grab redis password from secret:

```yaml
kc get secret redis-creds -o yaml | grep REDIS_PASSWORD
```

grab the base64 encoded password (do not decode it)

exec into redis pod:

```yaml
kc exec -it redis -- bash
```

enter redis console:

```yaml
redis-cli
```

inside redis console, provide the password to authenticate:

```bash
127.0.0.1:6379> auth <PASSWORD>
OK
```

shutdown the service:

```yaml
shutdown
```

this should also delete the `appendonly.aof` file inside redis pvc