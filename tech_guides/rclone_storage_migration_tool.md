# rclone storage migration tool

## install

linux / macos

```yaml
curl https://rclone.org/install.sh | bash
```

## config

add new remote storage using interactive wizard

```yaml
rclone config
```

check config file path

```yaml
rclone config file
```

edit config file

```yaml
vim ~/.config/rclone/rclone.conf
```

list configured remotes

```yaml
rclone listremotes
```

## list and view buckets

list bucket path (recursively)

```yaml
rclone ls remote:bucket_name
```

list bucket path (folders only)

```yaml
rclone lsd remote:bucket_name
```

check bucket size and file count

```yaml
rclone size --human-readable remote:bucket_name
```

check total size of bucket

```yaml
rclone ncdu remote:bucket_name
```

## copy files

<aside>
🔥 when you migrate to an AWS S3 bucket and permission is granted to your canonical ID, all files will be owned by **your user** by default.

this means that any **signed download links from application won’t work**.

add this flag to copy command for assigning canned ACL to all files copied:

```yaml
--s3-acl bucket-owner-full-control
```

[https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl](https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html#canned-acl)

providing this ACL ensures both you and the bucket owner have full control over the files. and once the bucket owner has control, signed download links will work.

⚠️ **remember:** this is super important to do while uploading, otherwise you’ll need to iterate the entire bucket and re-assign the ACL to each object, using AWS CLI:

```bash
bucket="my_bucket"

keys=$(aws s3api list-objects --bucket "$bucket" --query 'Contents[].Key' --output text)

for link in $keys; do
  aws s3api put-object-acl --bucket $bucket --key $link --acl bucket-owner-full-control
done
```

</aside>

<aside>
⚠️ when destination bucket is GCS, add this flag to the copy command:

```yaml
--gcs-bucket-policy-only
```

</aside>

<aside>
👉🏻 when source is a folder (or bucket root), file transfers are recursive by default.

</aside>

<aside>
👉🏻 after transfer is done, you can verify all files were transferred successfully by running the same command again. 
rclone will first check for all files to exist on the destination bucket, if all files were uploaded successfully, the expected output should look like this:

```yaml
$ rclone copy --progress remote1:bucket_1_name remote2:bucket_2_name
Transferred:              0 B / 0 B, -, 0 B/s, ETA -
Checks:              3127 / 3127, 100%
Elapsed time:        16.2s
```

notice no files were transferred, and checks completed at 100%

</aside>

copy files from minio bucket to S3 bucket

```yaml
rclone copy --progress --s3-acl bucket-owner-full-control minio:bucket_1_name s3:bucket_2_name
```

copy files from local to bucket

```yaml
rclone copy --progress /data/blablo remote:bucket_name
```

copy files from bucket 1 to bucket 2

```yaml
rclone copy --progress remote1:bucket_1_name remote2:bucket_2_name
```

## **config templates**

s3

```yaml
[my_s3]
type = s3
provider = AWS
access_key_id = ***
secret_access_key = ***
region = us-east-1
session_token = *** # optional for STS usage
```

minio

```yaml
[my_minio]
type = s3
provider = Minio
access_key_id = ***
secret_access_key = ***
endpoint = https://minio.lolz.my-corp.lol
```

Google Cloud Storage

```yaml
[my_gcs]
type = google cloud storage
service_account_file = /data/gcs_key.json
location = us-central1
project_number = 652699653988 # optional, for bucket list permissions
```

Azure Blob Storage

```ruby
[azure]
type = azureblob
account = # storage account name
key = # base64 encoded key, 88 chars long after encoding
```

### safe migration plan

1. **Transfer files with checksum verification**: Use the **`rclone copy`** command to transfer files between the buckets while enabling checksum verification. Add the **`-checksum`** flag to perform checksum verification during the transfer. Here's an example command:
    
    ```
    rclone copy minio:bucket1 s3:bucket2 --checksum
    ```
    
    Replace **`minio:bucket1`** with the source bucket on MinIO and **`s3:bucket2`** with the destination bucket on AWS S3.
    
2. **Capture errors**: To capture any errors during the transfer process, you can redirect the command output to a log file. For example:
    
    ```
    rclone copy minio:bucket1 s3:bucket2 --checksum > transfer.log 2>&1
    ```
    
    This redirects both the standard output and error streams to the specified log file (**`transfer.log`** in this case).
    
3. **Verify transfer**: After the transfer is complete, you can compare the source and destination buckets' contents to ensure that all files were transferred successfully. You can use the **`rclone check`** command for this purpose. Here's an example command:
    
    ```
    rclone check minio:bucket1 s3:bucket2 --size-only --one-way
    ```
    
    The **`--size-only`** flag compares the file sizes, and the **`--one-way`** flag checks for files existing in the source but not in the destination.
    
4. **Generate a detailed report**: To generate a detailed report summarizing the transfer, you can use the **`rclone ncdu`** command. It provides a concise overview of the transferred files' sizes. Here's an example command:
    
    ```
    rclone ncdu minio:bucket1
    ```
    
    Replace **`minio:bucket1`** with the source bucket you want to generate the report for.