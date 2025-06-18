
## install standalone minio storage using helm

### add repo
```
helm repo add minio https://charts.min.io/
helm repo update
```

### set values
create `minio_values.yaml` file:
```yaml
image:
  repository: quay.io/minio/minio
  tag: latest

mcImage:
  repository: quay.io/minio/mc
  tag: latest

mode: standalone

rootUser: admin
rootPassword: master123

buckets:
  - name: test-bucket
    policy: none

persistence:
  size: 10Gi
```

### install chart
```
helm install minio minio/minio \
-n minio --create-namespace \
-f minio_values.yaml --debug
```
wait for pod to be up.

### OPTIONAL: console access
port-forward console UI:
```bash
kubectl -n minio port-forward svc/minio-console 9001
```
login at http://localhost:9001/ using credentials from values file.

if needed, port-forward the minio API as well:
```bash
kubectl -n minio port-forward svc/minio 9000
```

### OPTIONAL: test bucket connectivity
create a pod with minio client:

```
kubectl run minio-client --image minio/mc --command -- sleep infinity
```

exec into it:
```
kubectl exec -it minio-client -- bash
```

set the connection details:
```
mc alias set minio http://minio.minio.svc.cluster.local:9000 admin master123
```

list buckets:
```
mc ls minio
```

list bucket content:
```
mc ls minio/test-bucket
```

see documentation for additional commands: https://min.io/docs/minio/linux/reference/minio-mc.html

### notes
- original chart: https://github.com/minio/minio/tree/master/helm/minio

- original values: https://github.com/minio/minio/blob/master/helm/minio/values.yaml
