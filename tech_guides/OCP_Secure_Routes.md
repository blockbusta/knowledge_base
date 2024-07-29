# OCP Secure Routes

1. wildcard DNS record pointing to existing default LB public IP
    
    ```python
    *.medusa.gcpops.beer.co.uk
    ```
    

1. matching wildcard certificate for the same wildcard domain

1. route manifest:
    
    ```yaml
    kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: web-server-route
      namespace: nginxtest
      labels:
        app: webserver
    spec:
      host: web-server.medusa.gcpops.beer.co.uk
      to:
        kind: Service
        name: web-server-service
        weight: 100
      port:
        targetPort: 80
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        certificate: |-
          -----BEGIN CERTIFICATE-----
          ...........................
          -----END CERTIFICATE-----
        key: |-
          -----BEGIN RSA PRIVATE KEY-----
          ...............................
          -----END RSA PRIVATE KEY-----
    
    ```