# AWS CLI

# 1) install

### linux:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
which aws
```

### MacOS:

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
aws --version
which aws
```

# 2) retrieve credentials

# 3) login

```bash
aws configure
```

paste the **access key**, then **secret access key**, then **region**

<aside>
⛔ **important**: the credentials are temporary and expire in a couple of hours.
if you run into any kind of permission error, try reloading the [awsapps.com](http://awsapps.com) page and retrieve new credentials.

</aside>

# S3 commands

upload a local file to s3 bucket:

```bash
aws s3 cp **SOURCE_FILE_NAME** s3://**S3_BUCKET**/**DESTINATION_FILE_NAME**
```

download file from s3 bucket to local:

```bash
aws s3 cp **s3://S3_BUCKET/FILE_NAME** **LOCAL_FILE_NAME**
```

# S3 commands with minio bucket

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
aws --endpoint-url $MINIO_ENDPOINT_URL s3 cp s3://$MINIO_BUCKET/storage_files/db-backup.sql .
```

**for example:**

aws cli config

```bash
# cat ~/.aws/credentials
[default]
aws_access_key_id = blablabla
aws_secret_access_key = 8TJSAZQkPtWcBkPKRHW-yAyeHYKq
```

aws cli commands

```bash
aws --endpoint-url http://172.29.216.185:9020 s3 ls s3://mybucket/storage_files/
aws --endpoint-url http://172.29.216.185:9020 s3 cp s3://mybucket/storage_files/db-backup.sql .
```