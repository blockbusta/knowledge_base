# SeaweedFS Kubernetes Deployment & AWS CLI S3 Quickstart

This guide covers deploying SeaweedFS with the S3 API enabled, authentication configured, and automatic bucket creation on Kubernetes, followed by verifying object operations via the AWS CLI.

---

## 1. Prepare Helm Values (`seaweedfs-values.yaml`)

The chart can serve S3 from two places: the filer's embedded S3 server, or a standalone `s3` deployment. These are configured separately. If you enable the standalone gateway, its settings must go under the top-level `s3:` key, because configuration under `filer.s3` applies only to the filer.

```yaml
master:
  enabled: true
  replicas: 1

volume:
  enabled: true
  replicas: 1
  storage: 10Gi

filer:
  enabled: true
  replicas: 1

s3:
  enabled: true
  enableAuth: true
  credentials:
    admin:
      accessKey: admin
      secretKey: master123
  createBuckets:
    - name: test-bucket
```

`enableAuth: true` is what makes the chart generate the identity config and mount it into the gateway. Without it, `credentials` has no effect. The chart also generates a second, read-only identity with random keys, which you can ignore.

---

## 2. Deploy SeaweedFS via Helm

```bash
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm repo update

helm install seaweedfs seaweedfs/seaweedfs \
  --namespace seaweedfs \
  --create-namespace \
  -f seaweedfs-values.yaml
```

Verify all pods reach `Running`:

```bash
kubectl get pods -n seaweedfs
```

---

## 3. Test the S3 API Using AWS CLI

Deploy a test pod:

```bash
kubectl run aws-cli --image=amazon/aws-cli --command -- sleep infinity
```

Exec in and set the environment:

```bash
kubectl exec -it aws-cli -- bash
```

```bash
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=master123
export AWS_DEFAULT_REGION=us-east-1
export S3_ENDPOINT=http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333
```

---

## 4. Perform S3 Operations

List buckets. `test-bucket` should already be present:

```bash
aws --endpoint-url $S3_ENDPOINT s3 ls
```

If it is missing, do not create it by hand. Its absence means `createBuckets` was not applied, which usually means it was written as `buckets` or nested in the wrong section. Fix the values file and run `helm upgrade`.

Upload and list:

```bash
echo "Hello from SeaweedFS S3!" > hello.txt
aws --endpoint-url $S3_ENDPOINT s3 cp hello.txt s3://test-bucket/
aws --endpoint-url $S3_ENDPOINT s3 ls s3://test-bucket/
```

---

## 5. Optional: Browse the Filer UI

```bash
kubectl port-forward svc/seaweedfs-filer 8888:8888 -n seaweedfs
```

Open `http://localhost:8888`.
