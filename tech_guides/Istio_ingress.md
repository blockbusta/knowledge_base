# Istio ingress

add helm repo:

```yaml
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

install:

```yaml
helm install istio-base istio/base -n istio-system --create-namespace --debug;
helm install istiod istio/istiod -n istio-system --wait --debug;
helm install istio-ingress istio/gateway -n istio-system --wait --debug
```

point the ingress LB svc external IP to your wildcard DNS record:

```yaml
$ kubectl -n istio-system get svc
NAME            TYPE           CLUSTER-IP     **EXTERNAL-IP**    PORT(S)                                      AGE
istio-ingress   LoadBalancer   10.0.23.173    **20.72.74.106**   15021:30534/TCP,80:31403/TCP,443:30928/TCP   81m
```

create gateway:

```yaml
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: istio-gateway
  namespace: lolz
spec:
  selector:
    istio: ingress
    app: istio-ingress
  servers:
  - hosts:
    - '*.124to125test.funkyzebra.space'
    port:
      name: http
      number: 80
      protocol: HTTP
EOF
```

# Example VS

create virtualservice to any service you wish to expose:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: prometheus
  namespace: istio-system
spec:
  gateways:
  - istio-gateway
  hosts:
  - prometheus.jacksonzzz.apps.beer.co.uk
  http:
  - retries:
      attempts: 5
      perTryTimeout: 1800s
    route:
    - destination:
        host: prometheus.prometheus.svc.cluster.local
    timeout: 9000s
```