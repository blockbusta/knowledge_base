# Min.IO standalone deployment

### install stack
Note the access/secret keys are fixed in the secret, replace them if not running a test/dev environment.
```
kubectl create namespace minio
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/pvc.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/secret.yaml
kubectl apply -f https://raw.githubusercontent.com/blockbusta/knowledge_base/refs/heads/main/scripts/standalone_minio/service.yaml
```

### expose endpoints
Replace the `webapp.me` with your domain.

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
