## install minio using helm

> this example use sub-path routing:
> - minio console exposed at: `https://my.website.com/minio-console`
> - minio api exposed at: `https://my.website.com/minio-api`


**add repo**:
```
helm repo add minio https://charts.min.io/
helm repo update
```

**modify** `minio_values.yaml` as needed.

**install chart:**
```
helm install minio minio/minio \
-n minio --create-namespace \
-f minio_values.yaml --debug
```

---

**original chart**: https://github.com/minio/minio/tree/master/helm/minio
**original values**: https://github.com/minio/minio/blob/master/helm/minio/values.yaml
