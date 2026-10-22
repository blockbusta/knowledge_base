# SeaweedFS Kubernetes Deployment & AWS CLI S3 Quickstart

This guide covers deploying SeaweedFS with S3 API enabled and auto-bucket creation on Kubernetes, followed by verifying object operations via the AWS CLI.

---

## 1. Prepare Helm Values (`seaweedfs-values.yaml`)

Create `seaweedfs-values.yaml` with S3 enabled, admin credentials configured, and automatic bucket creation enabled:

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
    autoCreateBuckets: true
    config: |
      {
        "identities": [
          {
            "name": "admin",
            "credentials": [
              {
                "accessKey": "admin",
                "secretKey": "master123"
              }
            ],
            "actions": ["Read", "Write", "List", "Tagging", "Admin"]
          }
        ]
      }

s3:
  enabled: true
  buckets:
    - name: test-bucket

```

---

## 2. Deploy SeaweedFS via Helm

```bash
# Add SeaweedFS repository
helm repo add seaweedfs https://seaweedfs.github.io/seaweedfs/helm
helm repo update

# Install chart
helm install seaweedfs seaweedfs/seaweedfs \
  --namespace seaweedfs \
  --create-namespace \
  -f seaweedfs-values.yaml \
  --debug

```

Verify all pods reach the `Running` state:

```bash
kubectl get pods -n seaweedfs

```

---

## 3. Test S3 API using AWS CLI

### Step 3.1: Deploy Test Pod

```bash
kubectl run aws-cli --image=amazon/aws-cli --command -- sleep infinity

```

### Step 3.2: Exec into Pod & Configure Environment

```bash
kubectl exec -it aws-cli -- bash

```

Inside the pod, export credentials and target region:

```bash
export AWS_ACCESS_KEY_ID=admin
export AWS_SECRET_ACCESS_KEY=master123
export AWS_DEFAULT_REGION=us-east-1
export S3_ENDPOINT=http://seaweedfs-s3.seaweedfs.svc.cluster.local:8333

```

---

## 4. Perform S3 Operations

### List Buckets

```bash
aws --endpoint-url $S3_ENDPOINT s3 ls

```

*(If `test-bucket` is not listed, create it manually via CLI)*:

```bash
aws --endpoint-url $S3_ENDPOINT s3 mb s3://test-bucket

```

### Upload a Test File

```bash
echo "Hello from SeaweedFS S3!" > hello.txt
aws --endpoint-url $S3_ENDPOINT s3 cp hello.txt s3://test-bucket/

```

### List Bucket Contents

```bash
aws --endpoint-url $S3_ENDPOINT s3 ls s3://test-bucket

```

### OPTIONAL
**Access the S3 Web / Filer UI Locally:**
```bash
kubectl port-forward svc/seaweedfs-filer 8888:8888 -n seaweedfs

```


Navigate to `http://localhost:8888` in your browser to browse `test-bucket`.
