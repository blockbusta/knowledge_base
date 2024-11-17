# run minio client test pod
```
kubectl run minio-client --image=minio/mc:latest --command -- sleep infinity
kubectl exec -it minio-client -- bash
```

# Object Storage migration

<aside>
⚠️ Migrating data between buckets can take hours and sometimes even days.
To reduce the risk of mc client disconnecting, **we run the operation from a VM**
(not any laptop/workstation) and opening a tmux session.

</aside>

# Install minio client

install command for ubuntu: [https://docs.min.io/docs/minio-client-complete-guide.html](https://docs.min.io/docs/minio-client-complete-guide.html)

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc;

chmod +x $HOME/minio-binaries/mc;
export PATH=$PATH:$HOME/minio-binaries/;

mc --help;
```

# Install tmux

```jsx
sudo apt-get install tmux
```

Open a tmux session:

```jsx
tmux new -s mc-migration
```

<aside>
☝🏻 to detach from current session: `ctrl + b` then `d`
to re-attach to last session: `tmux a`

</aside>

# configure minio cli

Add the source and destination S3 compatible hosts.

```bash
mc alias set <ALIAS> <YOUR-S3-ENDPOINT> [YOUR-ACCESS-KEY] [YOUR-SECRET-KEY] [--api API-SIGNATURE]
```

<aside>
⚠️ mc stores all its configuration information in `~/.mc/config.json` file.

</aside>

### minio

```jsx
mc alias set minio http://192.168.1.51 BKIKJAA5BMMU2RHO6IBB V7f1CwQqAcwo80UEIJEjc5gVQUSSx5ohQ9GSrr12 --api S3v4
```

### AWS S3

<aside>
⚠️ When migrating to a bucket other user created, you won’t be able to retrieve it’s credentials. They’ll need to add you to the bucket ACL. Once added, you’ll be able to perform the migration using your own AWS credentials.

1. Go to any bucket in your account, click **Permissions** and scroll down to **ACL**.
    
    Copy your Canonical ID from “**Bucket owner (your AWS account)”**
    
    
2. Ask the customer to grant you access (read+write) to the bucket:
**Bucket** → **Permissions** → **ACL** → **Edit** → **Access for other AWS accounts** → **Add Grantee**

Provide the following: 
    - **Grantee:** your cannonical ID
    - **Objects:** `List, Write`
    - **Bucket ACL:** `Read, Write`
3. Configure aws cli with your credentials. Once you have permissions to the bucket
    
    ```jsx
    aws configure
    AWS Access Key ID [None]: xxxxxxxxxxx
    AWS Secret Access Key [None]: xxxxxxxxxx
    ```
    
4. Type the following to ensure you have connectivity to their S3 bucket. 
** Note if you run “aws s3 ls”, their bucket will not show up in the list this is expected from a shared bucket.
    
    ```jsx
    aws s3 ls <bucket-name>
    ```
    
5. Example of a S3 cli copy. This copies all files/folders in current directory to a bucket called “lolz” in S3.
    
    ```jsx
    aws s3 cp . s3://lolz --recursive --acl bucket-owner-full-control
    ```
    
    **Note:** if you need to update the ACL on files you can run the following command
    
    ```jsx
    aws s3api put-object-acl --bucket "lolz" --key "data/L-uqntrby/Data_Prepocessing.ipynb" --acl bucket-owner-full-control
    ```
    
</aside>

<aside>
⚠️ When working in AWS environment where session tokens are required edit `~/.mc/config.json` and add "sessionToken" directive:

</aside>

```jsx
mc alias set s3 https://s3.amazonaws.com <ACCESS_KEY> <SECRET_KEY> --api S3v4
```

```json
"s3": {
"url": "[https://s3.amazonaws.com](https://s3.amazonaws.com/)",
"accessKey": "accessKey",
"secretKey": "secretKey",
"sessionToken": "sessionToken",
"api": "S3v4",
"path": "auto"
}
```

### GCP GCS

```jsx
mc alias set gcs  https://storage.googleapis.com <ACCESS_KEY> <SECRET_KEY>
```

**to create access/secret keys:**

1. Create a **Service Account** in GCP console, with an appropriate role assigned to it.
`Storage Bucket Admin` will do, but you can be more restrictive if needed.
2. Go to **Cloud Storage** → **Settings** → **Interoperability**, then create **HMAC keys** by clicking on ‘**Create a key for a Service Account**’ and then proceed to select the Service Account you created in the previous step.
3. Once HMAC key creation is complete, copy and store the ‘**Access Key**’ & ‘**Secret**’

# bucket connectivity test

check your buckets are accessible by listing their content:

```bash
mc ls s3

mc ls minio
```

to check bucket/folder size:

```bash
mc du s3
mc du s3/blabla/path

mc du minio
mc du minio/blabla/path
```

# perform migration

Use `mc copy` command to migrate data between source and destination buckets:

```jsx
mc cp --recursive minio/<source-bucket>/ s3/<destination-bucket>/
```

![Untitled](Object%20Storage%20migration%2004d4672d1e1847d4940b648067835313/Untitled%201.png)
