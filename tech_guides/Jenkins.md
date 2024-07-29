# Jenkins

[https://github.com/bitnami/charts/tree/main/bitnami/jenkins/#parameters](https://github.com/bitnami/charts/tree/main/bitnami/jenkins/#parameters)

```yaml
helm repo add bitnami https://charts.bitnami.com/bitnami;
helm repo update;

helm install jenkins -n jenkins --create-namespace bitnami/jenkins \
  --set jenkinsUser=jacksonadmin \
  --set jenkinsPassword=12345six \
  --set service.type=ClusterIP \
  --debug
```

create virtualservice to expose:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: jenkins
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - jenkins.aks-rofl16567.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: jenkins.jenkins.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```