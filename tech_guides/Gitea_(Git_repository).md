# Gitea (Git repository)

### OCP

helm install:

```bash
helm install gitea gitea-charts/gitea \
  --set serviceAccount.create="true" \
  --set serviceAccount.name=gitea-sa \
  --set gitea.config.server.DOMAIN=gitea.aks-rofl3442.cicd.ginger.cn \
  --set gitea.config.server.PROTOCOL=https \
  --set gitea.config.packages.ENABLED="true" \
  --create-namespace -n gitea \
  --debug
```

```bash
helm upgrade --install gitea gitea-charts/gitea \
  --set serviceAccount.create="true" \
  --set serviceAccount.name=gitea-sa \
  --set gitea.config.server.DOMAIN=gitea.medusa.gcpops.beer.co.uk \
  --set gitea.config.server.PROTOCOL=https \
  --set gitea.config.packages.ENABLED="true" \
  --set gitea.config.server.ENABLE_ACME="true" \
  --set gitea.config.server.ACME_ACCEPTTOS="true" \
  --create-namespace -n gitea \
  --debug
```

apply security context:

```bash
oc adm policy add-scc-to-user privileged -z gitea-postgresql-ha -n gitea;
oc adm policy add-scc-to-user privileged -z gitea-redis-cluster -n gitea;
oc adm policy add-scc-to-user privileged -z gitea-sa -n gitea;
```

Route:

```bash
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: gitea
  namespace: gitea
spec:
  host: gitea.medusa.gcpops.beer.co.uk
  to:
    kind: Service
    name: gitea-http
    weight: 100
  port:
    targetPort: 3000
```

VirtualService:

```bash
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gitea
  namespace: istio-system
spec:
  gateways:
    - lolz-gateway
  hosts:
    - gitea.aks-rofl3442.cicd.ginger.cn
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: gitea-http.gitea.svc.cluster.local
      timeout: 864000s
```

container registry:

```bash
https://gitea.aks-rofl3442.cicd.ginger.cn/john_doe/lolz:v5
```

login:

```bash
docker login --username=lolz --password=* gitea.aks-rofl3442.cicd.ginger.cn
```