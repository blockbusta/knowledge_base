# prometheus

## query prometheus endpoint using CURL

**using cleartext user/pass:**

```bash
curl -u **<USER>**:**<PASS>** \
**<PROMETHEUS_URL>**/api/v1/query?query=**<QUERY>**
```

to run in app pod using existing env vars for authentication:

```bash
BASE64_USER_PASS=$(echo -n "$PROMETHEUS_USER:$PROMETHEUS_PASS" | base64);
echo $BASE64_USER_PASS

curl -H "Authorization: Basic $BASE64_USER_PASS" \
$PROMETHEUS_URL/api/v1/query?query=**<QUERY>**
```

```bash
curl -u $PROMETHEUS_USER:$PROMETHEUS_PASS \
$PROMETHEUS_URL/api/v1/query?query=<QUERY>
```

**using bearer token:**

```ruby
curl -H "Authorization: Bearer **<TOKEN>**" \
**<PROMETHEUS_URL>**/api/v1/query?query=**<QUERY>**
```

to run in app pod:

```bash
curl --insecure -H "Authorization: Bearer $PROMETHEUS_TOKEN" \
$PROMETHEUS_URL/api/v1/query?query=<QUERY>
```

<aside>
⚠️ a token can be either the basic auth credentials, encoded to base64:
given username `` and password `xxxxxxxyyyyyyy`

```bash
echo -n ":xxxxxxxyyyyyyy" | base64
```

or a token from a serviceaccount that has permissions for prometheus:

```bash
oc -n openshift-monitoring sa get-token prometheus-k8s
```

</aside>

### test “up” query

<aside>
⚠️ if successful = will return JSON in response
if failed = will return HTML of login page

</aside>

**basic auth (user+pass)**

template

```bash
curl --insecure -u <USER>:<PASS> <PROMETHEUS_URL>/api/v1/query?query=up
```

example

```bash
curl --insecure -u internal:password https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=up
```

**token**

template

```bash
curl --insecure -H "Authorization: Bearer <TOKEN>" <PROMETHEUS_URL>/api/v1/query?query=up
```

example

```bash
curl --insecure -H "Authorization: Bearer <INSERT_TOKEN>" https://prometheus-k8s.openshift-monitoring.svc:9091/api/v1/query?query=up
```