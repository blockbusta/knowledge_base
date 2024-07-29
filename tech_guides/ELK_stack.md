# ELK stack

<aside>
ℹ️ in the following instructions, we will use the `mvr` namespace.

</aside>

`elk-values.yaml`

```bash
---
# Use Elasticsearch 7.10.2
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:7.10.2
  # ...
# Use Logstash 7.10.2
logstash:
  image: docker.elastic.co/logstash/logstash:7.10.2
  # ...
# Use Kibana 7.10.2
kibana:
  image: docker.elastic.co/kibana/kibana:7.10.2
  # ...
# ...
```

### ElasticSearch

```xml
helm repo add elastic https://helm.elastic.co;
helm install -n mvr elasticsearch elastic/elasticsearch \
-f elk-values.yaml --debug
```

**NOTES:**

1. Watch all cluster members come up.
    
    ```xml
    kubectl get pods --namespace=mvr -l app=elasticsearch-master -w
    ```
    
2. Retrieve elastic user's password.
    
    ```xml
    kubectl get secrets --namespace=mvr elasticsearch-master-credentials \
    -ojsonpath='{.data.password}' | base64 -d
    ```
    
3. Test cluster health using Helm test.
    
    ```xml
    helm --namespace=mvr test elasticsearch
    ```
    

### LogStash

```xml
helm install -n mvr logstash elastic/logstash -f elk-values.yaml --debug
```

**NOTES:**

1. Watch all cluster members come up.
    
    ```xml
    kubectl get pods --namespace=mvr -l app=logstash-logstash -w
    ```
    

### Kibana

```xml
helm install -n mvr kibana elastic/kibana -f elk-values.yaml --debug
```

**NOTES:**

1. Watch all containers come up.

    
    ```xml
    kubectl get pods --namespace=mvr -l release=kibana -w
    ```
    
2. Retrieve the elastic user's password.
    
    ```xml
    kubectl get secrets --namespace=mvr elasticsearch-master-credentials -ojsonpath='{.data.password}' | base64 -d
    ```
    
3. Retrieve the kibana service account token.
    
    ```xml
    kubectl get secrets --namespace=mvr kibana-kibana-es-token -ojsonpath='{.data.token}' | base64 -d
    ```
    

if install fails, run these to uninstall everything than install again:

```xml
kubectl delete -n mvr configmap kibana-kibana-helm-scripts
kubectl delete -n mvr serviceaccount pre-install-kibana-kibana
kubectl delete -n mvr serviceaccount post-delete-kibana-kibana
kubectl delete -n mvr roles pre-install-kibana-kibana
kubectl delete -n mvr rolebindings pre-install-kibana-kibana
kubectl delete -n mvr job pre-install-kibana-kibana
helm uninstall -n mvr kibana
```

### expose web UI’s

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:  
  name: elasticsearch
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - elasticsearch.aks-rofl16722.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: elasticsearch-master.mvr.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:  
  name: kibana
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - kibana.aks-rofl16722.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: kibana-kibana.mvr.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```

### Logstash configuration

To configure Logstash to collect your app logs, you will need to define:

1. an **input** plugin to read the logs from your app, for example:
read the logs from the container with the ID **`my-container`** and tag them with the type **`my-app`**

2. a **filter** plugin to parse and transform the logs, for example:
apply the **`json`** filter to the logs with the **`my-app`** tag and parse the **`message`** field as JSON

3. an **output** plugin to send the logs to a destination, for example:
send the logs to Elasticsearch running on the host **`elasticsearch`** and create an index named **`my-app`** with a daily time-based suffix.

these are defined in `logstash.conf`

```yaml
input {
  container {
    id => "wiki-random"
    type => "app"
  }
}

filter {
  grok {
    match => { "message" => "%{DATA:uniqueid} %{DATA:random1}, %{DATA:random2}, %{DATA:random3}, %{DATA:random4}, %{DATA:random5}" }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "wiki-random-%{+YYYY.MM.dd}"
  }
}
```

which will be packaged in a configmap:

```yaml
kubectl -n mvr create configmap logstash-config --from-file=logstash.conf
```

update the logstash deployment to include it:

```yaml
spec:
      containers:
        volumeMounts:
        - name: config-volume
          mountPath: /usr/share/logstash/config
      volumes:
      - name: config-volume
        configMap:
          name: logstash-config
```

test filebeat:

```yaml
echo "test log message" | filebeat test output
```

bad result:

```yaml
elasticsearch: http://elasticsearch:9200...
  parse url... OK
  connection...
    parse host... OK
    dns lookup... ERROR lookup elasticsearch on 10.0.0.10:53: no such host
```

good result:

```yaml
logstash: logstash-logstash-headless.mvr.svc.cluster.local:5044...
  connection...
    parse host... OK
    dns lookup... OK
    addresses: 10.244.3.55
    dial up... OK
  TLS... WARN secure connection disabled
  talk to server... OK
```