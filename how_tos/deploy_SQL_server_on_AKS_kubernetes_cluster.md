# deploy SQL server on AKS kubernetes cluster

## create secret for sql password:

```bash
kubectl create secret generic mssql --from-literal=SA_PASSWORD="MyC0m9l&xP@s5"
```

## create storage class and pvc:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
     name: azure-disk
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Standard_LRS
  kind: Managed
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: mssql-data
  annotations:
    volume.beta.kubernetes.io/storage-class: azure-disk
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 8Gi
```

```bash
kc apply -f sql-pvc.yaml
```


## create deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssql-deployment
spec:
  replicas: 1
  selector:
     matchLabels:
       app: mssql
  template:
    metadata:
      labels:
        app: mssql
    spec:
      terminationGracePeriodSeconds: 30
      hostname: mssqlinst
      securityContext:
        fsGroup: 10001
      containers:
      - name: mssql
        image: mcr.microsoft.com/mssql/server:2019-latest
        ports:
        - containerPort: 1433
        env:
        - name: MSSQL_PID
          value: "Developer"
        - name: ACCEPT_EULA
          value: "Y"
        - name: SA_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql
              key: SA_PASSWORD 
        volumeMounts:
        - name: mssqldb
          mountPath: /var/opt/mssql
      volumes:
      - name: mssqldb
        persistentVolumeClaim:
          claimName: mssql-data
---
apiVersion: v1
kind: Service
metadata:
  name: mssql-deployment
spec:
  selector:
    app: mssql
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433
  type: LoadBalancer
```

```yaml
kc apply -f sql-deploy.yaml
```


## grab SQL server external IP address:

```yaml
kc get svc | grep sql
```


**your SQL server credentials:**

```bash
user: sa
pass: MyC0m9l&xP@s5
server: 52.168.26.254
```

# OPTIONAL:

### install sqlcmd client (for executing SQL queries in terminal)

```bash
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
```

```bash
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
```

```bash
export ACCEPT_EULA=Y
apt-get update && apt-get install -y mssql-tools unixodbc-dev
```

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
```

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

## connect to SQL and run queries with sqlcmd

```bash
sqlcmd -S **External_IP_Address** -U sa -P "MyC0m9l&xP@s5" -Q "SHOW DATABASES;"
```

**`-S`** the external IP of the mssql service

**`-P`** the password set in the beginning

**`-Q`** the SQL query you wish to execute

## connect to SQL DB using SQL connector in 

[https://www.connectionstrings.com/microsoft-odbc-driver-17-for-sql-server/info-and-download/](https://www.connectionstrings.com/microsoft-odbc-driver-17-for-sql-server/info-and-download/)

```bash
What driver is needed for SQL Server 2019?
The Microsoft ODBC Driver 17
```