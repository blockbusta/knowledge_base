# NGINX Ingress dynamic TLS certs with lets-encrypt

1. install nginx ingress & assign DNS (refer to existing tutorial)

2. install cert manager
    
    ```bash
    helm repo add jetstack https://charts.jetstack.io;
    helm repo update;
    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version v1.12.0 \
      --set installCRDs=true \
      --debug
    ```
    
3. deploy kuard example deploy+service:
    
    ```bash
    kubectl -n YOUR_NAMESPACE apply -f \
    https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
    ```
    
    ```bash
    kubectl -n YOUR_NAMESPACE apply -f \
    https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
    ```
    
4. create letsencrypt prod issuer:
    
    ```bash
    kubectl -n YOUR_NAMESPACE apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: user@example.com
        privateKeySecretRef:
          name: letsencrypt-prod
        solvers:
          - http01:
              ingress:
                ingressClassName: nginx
    EOF
    ```
    
5. modify & deploy kuard example ingress:
    
    ```bash
    kubectl -n YOUR_NAMESPACE apply -f - <<EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: kuard
      annotations:
        cert-manager.io/issuer: "letsencrypt-prod"
    spec:
      ingressClassName: nginx
      tls:
      - hosts:
        - kuard.your-wildcard-domain.com
        secretName: quickstart-example-tls
      rules:
      - host: kuard.your-wildcard-domain.com
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kuard
                port:
                  number: 80
    EOF
    ```
    
6. Cert-manager will read these annotations and use them to create a certificate, which you can request and see:
    
    ```bash
    $ kubectl get certificate
    NAME                     READY   SECRET                   AGE
    quickstart-example-tls   True    quickstart-example-tls   16m
    ```
    
7. visit the website address to check TLS cert is valid:
    
    ```bash
    kc get ingress
    ```
    

1. **OPTIONAL**: test with another deploy+service+ingress combo
    
    ```bash
    kubectl -n YOUR_NAMESPACE apply -f - <<EOF
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
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: web-server-service
    spec:
      selector:
        app: web-server
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
        cert-manager.io/issuer: "letsencrypt-prod"
    spec:
      ingressClassName: nginx
      tls:
      - hosts:
        - webserver.your-wildcard-domain.com
        secretName: web-server-tls
      rules:
      - host: webserver.your-wildcard-domain.com
        http:
          paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-server-service
                port:
                  number: 80
    EOF
    ```
    
2. check again that certificate was created:
    
    ```bash
    kc get ingress
    ```
    

# lets-encrypt Issuing Limitations

The Let's Encrypt production issuer has very strict rate limits.

it can be very easy to hit those limits.

- The main limit is **Certificates per Registered Domain** (50 per week).
- You can create a maximum of 300 **New Orders** per account per 3 hours.
- You can combine multiple hostnames into a single certificate, up to a limit of 100 **Names per Certificate**.
- **Revoking certificates does not reset rate limits**, because the resources used to issue those certificates have already been consumed.

read more here: [https://letsencrypt.org/docs/rate-limits/](https://letsencrypt.org/docs/rate-limits/)

![Untitled](NGINX%20Ingress%20dynamic%20TLS%20certs%20with%20lets-encrypt%20ac6556f9d260473b88c7f0b1e1d91aed/Untitled.png)