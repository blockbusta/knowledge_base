# Min.IO standalone deployment

### install stack
Note that `minioadmin` is set as access/secret key, if not running a test/dev environment, replace them in the `minio-creds` secret:

Access key (`MINIO_ROOT_USER`) 3-20 charsacters

Secret key (`MINIO_ROOT_PASSWORD`) 4-40 charsacters

```
kubectl create namespace minio
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/secret.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/service.yaml
```

### expose endpoints
Replace `webapp.me` with your domain:

**for nginx ingress controller:**
```
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/ingress.yaml
```

**for istio ingress controller:**
```
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/virtualservice.yaml
```

**for openshift:**
```
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/route.yaml
```
