# MinIO client

[https://docs.min.io/docs/minio-client-complete-guide.html](https://docs.min.io/docs/minio-client-complete-guide.html)

download and install:

```bash
	wget https://dl.min.io/client/mc/release/linux-amd64/mc
	chmod +x mc
	./mc --help
```

get minio credentials (single chained command, copy paste and run)

```bash
echo "------- STORAGE_ACCESS_KEY -------";echo $(kubectl  get secret env-secrets --template={{.data.STORAGE_ACCESS_KEY}} | base64 -d);echo "------- STORAGE_SECRET_KEY -------";echo $(kubectl  get secret env-secrets --template={{.data.STORAGE_SECRET_KEY}} | base64 -d);echo "------- STORAGE_BUCKET -------";echo $(kubectl  get secret env-secrets --template={{.data.STORAGE_BUCKET}} | base64 -d);echo "------- STORAGE_ENDPOINT -------";echo $(kubectl  get secret env-secrets --template={{.data.STORAGE_ENDPOINT}} | base64 -d)
```

edit minio config file:

```bash
./mc ls

# you'll receive this line:
# mc: Configuration written to `/root/.mc/config.json`. Please update your access credentials.

vim /root/.mc/config.json
```

update the minio credentials in **config.json**:

```bash
                "**bucket_name**": { # can change bucket name to whatever you like
                        "url": "**STORAGE_ENDPOINT**",
                        "accessKey": "**STORAGE_ACCESS_KEY**",
                        "secretKey": "**STORAGE_SECRET_KEY**",
                        "api": "S3v2",
                        "path": "dns"
```

display files in bucket:

```bash
./mc ls **bucket_name**

# **bucket_name** is according to config.json above
```

### how **to get files' path in minio:**

go to the file (in project files or dataset), copy download link, strip all tokens:

```bash
http://minio.webapp.company.com/storage/mangos/assets/bf9e9998a83a0659666e3e32cd4c051f0a82aa46/GWNgUXxyo/ml-utilities/setup.sh
```

the path for minio client will be:

```bash
**bucket_name**/storage/mangos/assets/bf9e9998a83a0659666e3e32cd4c051f0a82aa46/GWNgUXxyo/ml-utilities/setup.sh
```

display incomplete files:

```bash
./mc ls **bucket_name** --incomplete
```

copy file from bucket to local:

```bash
./mc cp **bucket_name**/path/ ~/local/path
```