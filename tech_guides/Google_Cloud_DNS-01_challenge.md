# Google Cloud DNS-01 challenge

[https://cert-manager.io/docs/configuration/acme/dns01/google/](https://cert-manager.io/docs/configuration/acme/dns01/google/)

1. Install Cert Manager on your Kubernetes cluster
    
    ```yaml
    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
    ```
    
2. create a service account in google cloud, for the DNS challenge:
    
    ```bash
    # your google cloud project id:
    PROJECT_ID=developmentlolz
    
    gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"
    ```
    
    attach a policy with DNS permissions to it
    
    ```bash
    gcloud projects add-iam-policy-binding $PROJECT_ID \
       --member serviceAccount:dns01-solver@$PROJECT_ID.iam.gserviceaccount.com \
       --role roles/dns.admin
    ```
    
    grab its key file
    
    ```bash
    gcloud iam service-accounts keys create gcp_dns.json \
       --iam-account dns01-solver@$PROJECT_ID.iam.gserviceaccount.com
    ```
    

1. create secret with the service account key:
    
    ```bash
    kubectl --namespace lolz create secret generic \
    clouddns-dns01-solver-svc-acct --from-file=gcp_dns.json
    ```
    

1. create issuer:
    
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: gcp-dns-issuer
      namespace: lolz
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: jackson.johnson@beer.co.uk
        privateKeySecretRef:
          name: example-issuer-account-key
        solvers:
        - dns01:
            cloudDNS:
              project: developmentlolz
              serviceAccountSecretRef:
                name: clouddns-dns01-solver-svc-acct
                key: gcp_dns.json
    ```
    

1. create certificate:
    
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: gcp-dns-cert
      namespace: lolz
    spec:
      secretName: gcp-dns-domain-tls-secret
      issuerRef:
        name: gcp-dns-issuer
      dnsNames: ["*.on-the-rocks.gcpops.beer.co.uk"]
      renewBefore: 96h
    ```
    
2. check the secrets in lolz namespace for the new TLS secret:
    
    ```bash
    $ kubectl -n lolz get secret | grep tls
    
    example-com-tls
    ```