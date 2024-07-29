# Pebble CA server

before installing pebble, make sure you have nginx ingress installed:

```yaml
helm install -n nginx --create-namespace nginx \
ingress-nginx/ingress-nginx --wait \
--set controller.service.externalTrafficPolicy=Local \
--set controller.ingressClassResource.default=true \
--debug
```

and cert manager installed:

```yaml
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
```

apply pebble manifests:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: pebble
  namespace: pebble
spec:
  type: ClusterIP
  ports:
    - port: 14000
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app.kubernetes.io/name: pebble
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pebble
  namespace: pebble
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: pebble
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: pebble
    spec:
      volumes:
      - name: config-volume
        configMap:
          name: pebble
          items:
          - key: pebble-config.json
            path: pebble-config.json
      containers:
      - image: letsencrypt/pebble:v2.3.1
        imagePullPolicy: Always
        name: pebble
        ports:
        - name: http
          containerPort: 14000
          protocol: TCP
        volumeMounts:
        - name: config-volume
          mountPath: /test/config/pebble-config.json
          subPath: pebble-config.json
          readOnly: true
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: pebble
  namespace: pebble
data:
  pebble-config.json: |
    {
      "pebble": {
        "listenAddress": "0.0.0.0:14000",
        "managementListenAddress": "0.0.0.0:15000",
        "certificate": "test/certs/localhost/cert.pem",
        "privateKey": "test/certs/localhost/key.pem",
        "httpPort": 80,
        "tlsPort": 443,
        "ocspResponderURL": "",
        "externalAccountBindingRequired": false
      }
    }
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: pebble-issuer
  namespace: nginx # wherever u need the certs
spec:
  acme:
    skipTLSVerify: true
    email: jackson@test.com
    server: https://pebble.pebble:14000/dir
    privateKeySecretRef:
      name: pk-pebble-issuer
    solvers:
      - selector:
        http01:
          ingress:
            class: nginx
```

check that the issuer is ready:

```yaml
# k -n nginx get issuer
NAME            READY   AGE
pebble-issuer   True    11m
```

simple nginx hello world deployment to test:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webserver-deployment
  labels:
    app: webserver
spec:
  replicas: 3
  selector:
    matchLabels:
      app: webserver
  template:
    metadata:
      labels:
        app: webserver
    spec:
      containers:
      - name: webserver
        image: nginx:latest
        ports:
        - containerPort: 80
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 0
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        image: 'nginx:latest'
      volumes:
      - name: html
        configMap:
          name: nginx-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    <html>
    <head>
      <title>Welcome to my custom Nginx page!</title>
    </head>
    <body>
      <h1>Hello, this is my custom Nginx page! yaalalaalal balalalgaan!!!!!</h1>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: web-server-service
spec:
  selector:
    app: webserver
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-server
  annotations:
    cert-manager.io/issuer: "pebble-issuer"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - nginxtest.supercharged.gcpops.beer.co.uk
    secretName: web-server-tls
  rules:
  - host: nginxtest.supercharged.gcpops.beer.co.uk
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-server-service
            port:
              number: 80
```

in my case, i applied it in the `nginx` namespace, but you can apply it in `lolz` as well.

check certificate issued:

```yaml
# k -n nginx get certificate
NAME             READY   SECRET           AGE
web-server-tls   True    web-server-tls   25m
```

cert described:

```yaml
Status:
  Conditions:
    Last Transition Time:  2023-08-10T16:27:22Z
    Message:               Certificate is up to date and has not expired
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2028-08-10T16:27:22Z
  Not Before:              2023-08-10T16:27:22Z
  Renewal Time:            2026-12-10T16:27:22Z
  Revision:                1
Events:
  Type    Reason     Age   From          Message
  ----    ------     ----  ----          -------
  Normal  Issuing    13m   cert-manager  Issuing certificate as Secret does not exist
  Normal  Generated  13m   cert-manager  Stored new private key in temporary Secret resource "web-server-tls-cg5ll"
  Normal  Requested  13m   cert-manager  Created new CertificateRequest resource "web-server-tls-5p5ql"
  Normal  Issuing    12m   cert-manager  The certificate has been successfully issued
```

visit the route in chrome incognito

<aside>
⚠️ note that visiting the website in chrome will give you a not-trusted screen.
thats because pebble’s root certificate isn’t included in your browser.

</aside>


![Untitled](Pebble%20CA%20server%2056844890f01a4c51807b015b86c418b9/Untitled%201.png)