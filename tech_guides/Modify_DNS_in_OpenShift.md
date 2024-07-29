# Modify DNS in OpenShift

these instructions won’t modify the routing for existing openshift console and such.

we will create a new “router” especially for lolz, that won’t interfere with anything else.

<aside>
ℹ️ at least in ARO, azure creates a wildcard certificate, for the exact domain automatically created by them for that instance:

```bash
Common Name (CN)	*.apps.fm8w2gz6.northeurope.aroapp.io
Organization (O)	Microsoft Corporation
```

if you get smart and try to create 2nd-level subdomains like

```bash
**app.lolz**.apps.fm8w2gz6.northeurope.aroapp.io
```

they won’t be trusted 😄 since the certificate is only for 1st-level subdomains:

```bash
**app**.apps.fm8w2gz6.northeurope.aroapp.io
```

also, thats their own DNS that you cannot modify/alter anyway.
**for changing domain, its best to create a new separate domain + certificate**

</aside>

## instructions

1. create a TLS certificate for your domain. this step is according to your DNS provider.
eventually you’ll need the `tls.crt` and `tls.key` files. 
so if you have used cert-manager to create the certificate, you can extract the files from the certificate secret, like this:
    
    ```bash
    TLS_CRT_B64=$(kubectl -n lolz get secret op3nshift-tls -o jsonpath="{.data.tls\.crt}")
    TLS_KEY_B64=$(kubectl -n lolz get secret op3nshift-tls -o jsonpath="{.data.tls\.key}")
    echo $TLS_CRT_B64 | base64 -d > tls.crt
    echo $TLS_KEY_B64 | base64 -d > tls.key
    ```
    
    create a new TLS secret from these files:
    
    ```bash
    k -n openshift-ingress create secret tls op3nsh1ft-certificate \
    --cert=tls.crt --key=tls.key
    ```
    
2. create `ingressController`:
    
    ```bash
    apiVersion: operator.openshift.io/v1
    kind: IngressController
    metadata:
      name: op3nsh1ft
      namespace: openshift-ingress-operator
    spec:
      domain: 0p3nsh1ft.funkyzebra.space
      replicas: 2
      defaultCertificate:
        name: op3nsh1ft-certificate
    ```
    
3. the newly created `ingressController` will create a new LB service. grab its external IP:
    
    ```yaml
    k -n openshift-ingress get svc
    ```
    
    | NAME | TYPE | CLUSTER-IP | EXTERNAL-IP | PORT(S) | AGE |
    | --- | --- | --- | --- | --- | --- |
    | router-default | LoadBalancer | 172.30.130.35 | 90.80.70.60 | 80:31966/TCP,443:32700/TCP | 135d |
    | router-internal-default | ClusterIP | 172.30.16.11 | <none> | 80/TCP,443/TCP,1936/TCP | 135d |
    | router-internal-op3nsh1ft | ClusterIP | 172.30.133.149 | <none> | 80/TCP,443/TCP,1936/TCP | 33s |
    | router-op3nsh1ft | LoadBalancer | 172.30.180.222 | 20.10.70.10 | 80:32164/TCP,443:30401/TCP | 33s |
    
4. create/modify your A typewildcard DNS record with that LB address:
    
    ```yaml
    domain: *.0p3nsh1ft.funkyzebra.space
    value: **20.10.70.10**
    ```
    
5. update the new cluster domain in both `lolzapp`/`lolzinfra` CRD’s.
6. verify new routes were created with the new domain. done 😊

## notes

ARO openshift base domain configuration:

```yaml
kubectl -n openshift-ingress get ingresses.config.openshift.io cluster -o yaml
```

```yaml
apiVersion: config.openshift.io/v1
kind: Ingress
metadata:
  name: cluster
spec:
  domain: apps.fm8w2gz6.northeurope.aroapp.io
```

pre-existing `ingressController`:

```bash
k -n openshift-ingress-operator get ingressController default -o yaml
```

```bash
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  defaultCertificate:
    name: 0edf8182-104c-46aa-a133-b096765301eb-ingress
  domain: apps.fm8w2gz6.northeurope.aroapp.io
```

check TLS secret for pre-existing domain:

```yaml
k -n openshift-ingress get secrets
```

```yaml
NAME                                           TYPE                                  DATA   AGE
0edf8182-104c-46aa-a133-b096765301eb-ingress   kubernetes.io/tls                     2      135d
```