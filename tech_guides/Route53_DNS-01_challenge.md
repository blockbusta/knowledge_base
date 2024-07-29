# Route53 DNS-01 challenge

# Requirements:

- Hosted Zone ID
    
    
    ```bash
    aws route53 list-hosted-zones-by-name --dns-name **blabla.net**
    ```
    
- Acess/Secret keys for a user with permissions for the hosted zone in route 53
    
    [https://cert-manager.io/docs/configuration/acme/dns01/route53/](https://cert-manager.io/docs/configuration/acme/dns01/route53/)
    

# Instructions:

install cert manager

```bash
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
```

route53 creds secret

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: **route53-credentials-secret**
  namespace: cert-manager
data:
  **secret-access-key**: **<AWS_SECRET_KEY>
EOF**
```

cluster issuer

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cicd
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: **jackson.johnson@beer.co.uk**
    privateKeySecretRef:
      name: letsencrypt-cicd
    solvers:
    - dns01:
        route53:
          region: us-east-2
          hostedZoneID: **<AWS_ROUTE53_HOSTED_ZONE_ID>**
          accessKeyID: **<AWS_ACCESS_KEY>**
          secretAccessKeySecretRef:
            name: **roflroute53-credentials-secret**
            key: **secret-access-key
EOF**
```

certificate

```bash
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: domain-ingress-certs
  namespace: lolz
spec:
  dnsNames:
  - '*.aks-rofl15353.cicd.ginger.cn'
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-cicd
  renewBefore: 96h
  secretName: istio-ingressgateway-certs
```