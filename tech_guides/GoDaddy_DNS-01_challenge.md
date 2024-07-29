# GoDaddy DNS-01 challenge

1. Install Cert Manager on your Kubernetes cluster
    
    ```yaml
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
    ```
    
2. Create a GoDaddy API key and secret, select type “**Production**”
[https://developer.godaddy.com/](https://developer.godaddy.com/)
    
    <aside>
    👨🏻‍⚕️ to test API key you can call GoDaddy API to list your domains:
    
    ```bash
    curl -X GET \
    -H "Authorization: sso-key **<KEY>**:**<SECRET>**" \
    "https://api.godaddy.com/v1/domains"
    ```
    
    </aside>
    
3. clone the **godaddy-webhook** repo:
    
    ```yaml
    git clone https://github.com/snowdrop/godaddy-webhook
    ```
    

1. install the webhook from git repo folder
    
    ```yaml
    cd godaddy-webhook;
    kubectl apply -f deploy/webhook-all.yml --validate=false
    ```
    
2. Create a GoDaddy API secret that contains your API key and secret
    
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: godaddy-api-key
      namespace: cert-manager
    type: Opaque
    stringData:
      token: <KEY>:<SECRET>
    ```
    

1. Create a certificate issuer
    
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory 
        email: <EMAIL>
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
        - selector:
            dnsNames:
            - '*.cracker-jack.funkyzebra.space'
          dns01:
            webhook:
              config:
                apiKeySecretRef:
                  name: godaddy-api-key
                  key: token
                production: true
                ttl: 600
              groupName: acme.mycompany.com
              solverName: godaddy
    ```
    
2. create Certificate
    
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: miyagi-funkyzebra-space
      namespace: lolz
    spec:
      secretName: miyagi-funkyzebra-space-tls
      renewBefore: 240h
      dnsNames:
      - '*.cracker-jack.funkyzebra.space'
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
    ```
    

The flow of object created by the certificate:

`Certificate` → `CertificateRequest` → `Order` → `Challenge`

Once the challenge passes, the certificate is issued.

You can verify by listing certs and see if its true/false in “Ready” column:

```bash
kubectl -n cert-manager get certificates
```

and checking the TLS secret was created

```bash
kubectl -n lolz get secrets | grep tls
```

## Setting the TLS certificate within lolz

edit lolzinfra:

```bash
kc edit lolzinfra
```

set the following:

```bash
spec:
  https:
    enabled: true
    certSecret: **<CERT-SECRET-NAME>**
```