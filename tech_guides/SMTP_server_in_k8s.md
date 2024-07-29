# SMTP server in k8s

<aside>
ℹ️ based on [https://github.com/namshi/docker-smtp](https://github.com/namshi/docker-smtp)

</aside>

### deployment + service:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smtp-server
  namespace: lolz
spec:
  replicas: 1
  selector:
    matchLabels:
      app: smtp-server
  template:
    metadata:
      labels:
        app: smtp-server
    spec:
      containers:
        - name: smtp-container
          image: namshi/smtp
          ports:
            - containerPort: 25
          env:
            - name: MAILNAME
              value: "aks-rofl15353.cicd.ginger.cn"
            - name: DISABLE_IPV6
              value: "true"
            - name: RELAY_NETWORKS
              value: ":10.0.0.0/8:127.0.0.0/8:172.17.0.0/16:192.0.0.0/8"
---
apiVersion: v1
kind: Service
metadata:
  name: smtp-server
  namespace: lolz
spec:
  selector:
    app: smtp-server
  ports:
    - name: smtp-port
      protocol: TCP
      port: 25
      targetPort: 25
```

**configurable values:**

| MAILNAME | the cluster domain |
| --- | --- |

### settings in lolzapp:

```bash
smtp:
      domain: aks-rofl15353.cicd.ginger.cn
      password: ""
      port: 25
      sender: info@aks-rofl15353.cicd.ginger.cn
      server: smtp-server
      username: ""
```

**configurable values:**

| domain | the cluster domain |
| --- | --- |
| sender | best to keep as info@cluster_domain 
for any mails sent from lolz to be recognized and not marked as suspicious in the recipient inbox. |

# OCP:

manifest

```json
apiVersion: v1
kind: Namespace
metadata:
  name: smtp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smtp-server
  namespace: smtp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: smtp-server
  template:
    metadata:
      labels:
        app: smtp-server
    spec:
      securityContext:
        runAsUser: 0
      containers:
        - name: smtp-container
          image: namshi/smtp
          ports:
            - containerPort: 25
          env:
            - name: MAILNAME
              value: "medusa.gcpops.beer.co.uk"
            - name: DISABLE_IPV6
              value: "true"
            - name: RELAY_NETWORKS
              value: ":10.0.0.0/8:127.0.0.0/8:172.17.0.0/16:192.0.0.0/8"
      serviceAccountName: smtp-sa
---
apiVersion: v1
kind: Service
metadata:
  name: smtp-server
  namespace: smtp
spec:
  selector:
    app: smtp-server
  ports:
    - name: smtp-port
      protocol: TCP
      port: 25
      targetPort: 25
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: smtp-sa
```

add SCC to SA

```json
oc adm policy add-scc-to-user privileged -z smtp-sa -n smtp
```

configure in lolzapp

```json
smtp:
      domain: medusa.gcpops.beer.co.uk
      password: ""
      port: 25
      sender: info@medusa.gcpops.beer.co.uk
      server: smtp-server.smtp.svc.cluster.local
      username: ""
```