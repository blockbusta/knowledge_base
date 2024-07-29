# NGINX ingress

## Pre-requisites

**prepare an empty cluster, or create one with jenkins:**

[https://devops.jenkins.beer.co.uk/view/Ci-Cd/job/roflEmpty-Cluster/build](https://devops.jenkins.beer.co.uk/view/Ci-Cd/job/roflEmpty-Cluster/build?delay=0sec)

## I**nstall NGINX ingress**

add helm chart **`ingress-nginx/ingress-nginx`**

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

install for k8s `v1.24` and up:

```yaml
helm install -n lolz --create-namespace nginx \
ingress-nginx/ingress-nginx --wait \
--set controller.service.externalTrafficPolicy=Local \
--set controller.ingressClassResource.default=true \
--debug
```

post install, you should see the pod & service deployed and running:

```yaml
>>> kc get all

NAME                                                  READY   STATUS    RESTARTS   AGE
pod/nginx-ingress-nginx-controller-6c8884f8d6-rqgnt   1/1     Running   0          118s

NAME                                               TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)                      AGE
service/nginx-ingress-nginx-controller             LoadBalancer   10.100.30.109   blabla.us-east-2.elb.amazonaws.com   80:31070/TCP,443:30784/TCP   118s
service/nginx-ingress-nginx-controller-admission   ClusterIP      10.100.54.67    <none>                                                                    443/TCP                      118s

NAME                                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx-ingress-nginx-controller   1/1     1            1           118s

NAME                                                        DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-ingress-nginx-controller-6c8884f8d6   1         1         1       118s
```

lolz helm install params for nginx ingress:

```yaml
  --set networking.istio.enabled=false \
  --set networking.ingress.type=ingress \
```

**done!**

## optional stuff:

**deploy NGINX webserver to test**

```yaml
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-web-server
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: ngnix-web-server-service
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-web-server-ingress
  annotations:
spec:
  ingressClassName: nginx
  rules:
  - host: 11223344.us-east-2.elb.amazonaws.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: ngnix-web-server-service
            port:
              number: 80
EOF
```

### Misc command reference

Installs for environments with no load balancer. My node internal IP is `172.31.21.239` for example in AWS.

```elixir
helm install nginx -n nginx ingress-nginx/ingress-nginx --wait \
--set controller.service.externalIPs={172.31.21.239} \
--set controller.ingressClassResource.default=true \
--create-namespace
```

**legacy configs:**

install chart version `4.2.5` for `v1.20` k8s clusters

```yaml
helm install -n lolz --create-namespace nginx \
--set controller.ingressClassResource.default=true \
ingress-nginx/ingress-nginx --wait --version 4.2.5
```

install chart version `4.4.2` for `v1.22` k8s clusters and above

```yaml
helm install -n lolz --create-namespace nginx \
--set controller.ingressClassResource.default=true \
ingress-nginx/ingress-nginx --wait
```

<aside>
⛔ **don’t use this helm chart:** `**nginx-stable/nginx-ingress`** 

this release had issues with websockets, causing workspace features as terminal and IPYNB notebooks to malfunction.

```bash
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install -n lolz --create-namespace nginx nginx-stable/nginx-ingress --wait
```

**read more:**

- https://github.com/kubernetes/ingress-nginx/issues/3746
- [https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#custom-nginx-upstream-hashing](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#custom-nginx-upstream-hashing)
- [https://docs.nginx.com/nginx-ingress-controller/configuration/global-configuration/configmap-resource](https://docs.nginx.com/nginx-ingress-controller/configuration/global-configuration/configmap-resource)

</aside>

### Error 413 on file uploads with ingress-nginx

should resolve cases when you get 413 errors in a jupyter workspace, while dragging and dropping files in order to upload them.

You need to increase the proxy body size allowed for the nginx controller you can do this by updating the nginx values file with the following settings

```bash
controller:
  config:
    proxy-body-size: 100m # This is the limit of file transmition
```

Or if you prefer the set command
helm upgrade set command example:

```bash
--set-string controller.config.proxy-body-size="100m"
```

### Websocket errors Fix

So here is the workaround and may work for a lot of your clients. Once I set this on both the control plane and worker clusters all worked correctly including the page reloads.TLDR - Set a global config setting to add these snippets to the location config of each nginx ingress

How I did it:

```
Set .spec.controller.customConfigMap to a CM name:
X67TFNW4YT:aipg-ocp01 wanlessc$ oc get -n nginx-ingress nginxingress/nginxingress -o yaml | yq .spec.controller.customConfigMap
nginxingress-nginx-ingress-custom

Create the configmap below with the `location-snippets` key and the values contained in it:
X67TFNW4YT:aipg-ocp01 wanlessc$ oc get -n nginx-ingress cm/nginxingress-nginx-ingress-custom -o yaml | yq
apiVersion: v1
data:
  location-snippets: |
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"location-snippets":"proxy_set_header Upgrade $http_upgrade;\nproxy_set_header Connection $connection_upgrade;\n"},"kind":"ConfigMap","metadata":{"annotations":{},"labels":{"app.kubernetes.io/instance":"cluster-nginx-ingress"},"name":"nginxingress-nginx-ingress-custom","namespace":"nginx-ingress"}}
  creationTimestamp: "2024-02-14T19:55:57Z"
  labels:
    app.kubernetes.io/instance: cluster-nginx-ingress
  name: nginxingress-nginx-ingress-custom
  namespace: nginx-ingress
  resourceVersion: "120593250"
  uid: e83a500b-f0d2-41d4-a11a-ce0fa2ac3ce0

```

You can also add the following annotation, `nginx.org/websocket-services:`

```jsx
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.org/websocket-services: lolz-job-notebooksession-njzruel8bssnvnng8cba-1-jupyter
```