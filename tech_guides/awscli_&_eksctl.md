# awscli & eksctl

# aws cli

get caller idnetity (current logged in user)

```python
aws sts get-caller-identity
```

**S3 commands with minio bucket:**

aws cli config

```bash
# cat ~/.aws/credentials
[default]
aws_access_key_id = $MINIO_ACCESS_KEY
aws_secret_access_key = $MINIO_SECRET_KEY
```

aws cli commands

```bash
aws --endpoint-url $MINIO_ENDPOINT_URL s3 ls s3://$MINIO_BUCKET/storage_files/
aws --endpoint-url $MINIO_ENDPOINT_URL s3 cp s3://$MINIO_BUCKET/storage_files/lolz-db-backup.sql .
```

**for example:**

aws cli config

```bash
# cat ~/.aws/credentials
[default]
aws_access_key_id = 1_lolz_accid
aws_secret_access_key = 8TJSAZQkPtWcBkPKRHW-yAyeHYKq
```

aws cli commands

```bash
aws --endpoint-url http://172.29.216.185:9020 s3 ls s3://lolzs3/storage_files/
aws --endpoint-url http://172.29.216.185:9020 s3 cp s3://lolzs3/storage_files/lolz-db-backup.sql .
```

# eksctl

create cluster:

```python
eksctl create cluster -f /path/to/cluster.yaml
```

get kubeconfig:

```python
eksctl utils write-kubeconfig --cluster=<name> --kubeconfig=/path/to/kube.yaml
```