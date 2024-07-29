# NGINX Ingress dynamic TLS certs with ZeroSSL

1. install nginx ingress & assign DNS (refer to existing tutorial)
2. install cert manager:
    
    (reference: [https://cert-manager.io/docs/tutorials/zerossl/zerossl/](https://cert-manager.io/docs/tutorials/zerossl/zerossl/))
    
    ```bash
    helm install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.12.0 \
        --set ingressShim.defaultIssuerName=zerossl-production \
        --set ingressShim.defaultIssuerKind=ClusterIssuer \
        --set installCRDs="true" \
        --debug
    ```
    
    if you want to set limit for concurrent challenges running in at once:
    `--set maxConcurrentChallenges="2"`
    
3. create ZeroSSL account at [https://zerossl.com](https://zerossl.com/)
    
    After that go to developer section and generate `EAB Credentials for ACME Clients`. 
    
    you will retrieve **EAB KID** + **EAB HMAC Key**, Save them aside.
    
4. create **EAB HMAC Key** secret:
    
    ```bash
    kubectl -n **YOUR_NAMESPACE** create secret generic \
           zero-ssl-eabsecret \
           --from-literal=secret='**YOUR_ZEROSSL_EAB_HMAC_KEY**'
    ```
    
5. create Issuer:
replace **YOUR_NAMESPACE, YOUR@MAIL.COM, YOUR_ZEROSSL_EAB_KID**
    
    ```bash
    kubectl -n **YOUR_NAMESPACE** apply -f - <<EOF
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: zerossl-production
    spec:
      acme:
        server: https://acme.zerossl.com/v2/DV90
        email: **YOUR@MAIL.COM**
        privateKeySecretRef:
          name: zerossl-prod
        externalAccountBinding:
          keyID: **YOUR_ZEROSSL_EAB_KID**
          keySecretRef:
            name: zero-ssl-eabsecret
            key: secret
          keyAlgorithm: HS256
        solvers:
          - http01:
              ingress:
                ingressClassName: nginx
    EOF
    ```
    
    check the clusterissuer after applying:
    
    ```bash
    $ kubectl -n YOUR_NAMESPACE describe issuer zerossl-prod
    
    Status:
      Acme:
        Last Registered Email:  dummy-email@yourmail.com
        Uri:                    https://acme.zerossl.com/v2/DV90/account/tXXX_NwSv15rlS_XXXX
      Conditions:
        Last Transition Time:  2021-09-09T17:03:26Z
        Message:               The ACME account was registered with the ACME server
        Reason:                ACMEAccountRegistered
        Status:                True
        Type:                  Ready
    ```
    
6. test with an example ingress, deploy sample app to check:
    
    ```bash
    WEBSERVER_ROUTE="webserver.testing.mydomain.com"
    kubectl -n **YOUR_NAMESPACE** apply -f - <<EOF
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
        cert-manager.io/issuer: "zerossl-production"
    spec:
      ingressClassName: nginx
      tls:
      - hosts:
        - $WEBSERVER_ROUTE
        secretName: web-server-tls
      rules:
      - host: $WEBSERVER_ROUTE
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
    
7. **optional:** check ingress certificate
    
    ```bash
    kubectl describe ingress test-ingress -n default
    # check if tls is terminated using secret-tls
    ```
    
8. **optional:** check certificate
    
    ```bash
    DOMAIN2CHECK=blabla.company.io
    echo | openssl s_client -servername $DOMAIN2CHECK -connect $DOMAIN2CHECK:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates
    ```