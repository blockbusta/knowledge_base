# Integrating Alertmanager with Prometheus to receive email alerts

# Step-by-step installation

<aside>
👉 This guide assumes you don’t have Alertmanager installed on your cluster.

</aside>

## Create an Alertmanager secret for email alerts

Edit the following secret manifest, and apply:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-configuration
  namespace: my-webapp
type: Opaque
stringData:
  alertmanager.yaml: |
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: 'notifications'
    receivers:
    - name: 'notifications'
      email_configs:
      - to: your@mail.com
        from: metric-alerts@webapp.me
        smarthost: smtp.server.net:587
        auth_username: apikey
        auth_identity: apikey
        auth_password: **********
        send_resolved: true
				require_tls: true #Some SMTP servers this needs to be set to false. If you have issues check the alertmanager pods and look for an error saying the SMTP server doesn't have tls enabled. 
```

## Create an Alertmanager instance

Create a YAML file and use kubectl apply to create the following resource:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Alertmanager
metadata:
  name: alertmanager-instance
  namespace: my-webapp
spec:
  replicas: 2
  configSecret: alertmanager-configuration # defaults to alertmanager-alertmanager-instance
```

<aside>
⚙ Last line can be omitted in case you use secret named alertmanager-<AM-name>.

</aside>

Make sure that a new Statefulset alertmanager-instance has been created and have finished successfully to run a pod. You could use:

```bash
kubectl  get pod -l alertmanager=alertmanager-instance 
# Make sure is running to continue
```

<aside>
🚧 If the statefulSet or pod doesn’t exist, check the logs of the prometheus operator for any errors, it detects the Alertmanager instance, and deploys the alertmanager statefulSet in return:

</aside>

```bash
kubectl  logs deploy/prometheus-operator
```

## Create an Alertmanager service

Create a YAML file and use kubectl apply to create the following service resource:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: alertmanager-service
  namespace: my-webapp
  labels:
    app: alertmanager
    owner: control-plane
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 9093
  selector:
    alertmanager: alertmanager-instance
  sessionAffinity: None
  type: ClusterIP
```

## Create an Istio virtual service for the Alertmanager

 deployments use Istio ingress controller by default. 

In this case, create the following Istio virtual service using kubectl apply command, and make sure you update the hosts and host fields.

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: alertmanager
  namespace: my-webapp
spec:
  gateways:
  - istio-gw-
  hosts:
  - alertmanager.your-domain.com
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: alertmanager-service.webapp.svc.cluster.local # service
        port:
          number: 80
    timeout: 18000s
```

Alternatively, you can use an ingress object (adjusted for Nginx ingress controller):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager
  namespace: my-webapp
spec:
  ingressClassName: nginx
  rules:
  - host: alertmanager.your-domain.com # host route
    http:
      paths:
      - backend:
          service:
            name: alertmanager-service # service name
            port:
              number: 80 # service port
        path: /
        pathType: Prefix
#  tls:
#  - hosts:
#    - alertmanager.your-domain.com
#    secretName: my-tls-secret
```

## Create a Prometheus rule to monitor a metric

Create a following rule, using kubectl apply. For example, this rule will fire when a main file system of a cluster’s node has reached 85% of used space:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: prometheus-rule-low-disk-space
  namespace: my-webapp
  labels:
    app: infra-prometheus
    role: alert-rules
spec:
  groups:
      - name: alerting_rules
        rules:
          - alert: LowDiskSpace
            expr:  (100 - ((node_filesystem_avail_bytes{mountpoint="/",fstype!=""} * 100) /  node_filesystem_size_bytes{mountpoint="/",fstype!=""})) >= 85
            labels:
              severity: high
            annotations:
              summary: "Instance {{ $labels.instance }} is low on disk space"
              description: "Host {{ $labels.instance }} has about {{ $value }}% used space!"
```

## Wire up Prometheus with the Alertmanager instance

Update the Prometheus resource with:

```yaml
alerting:
	  alertmanagers:
	  - namespace: my-webapp
	    name: alertmanager-service
	    port: 9093
```

A quick option is to run:

```bash
kubectl  patch prometheus infra-prometheus --type=merge \
-p='{"spec": {"alerting": {"alertmanagers": [{"namespace": "", "name": "alertmanager-service","port": 9093}]}}}'
```

Head to http://prometheus.your-domain.com/status (/status path) to check that Prometheus service has discovered the Alertmanager instance.

# Uninstallation

To rollback all the operations, you can use the following commands in order:

```bash
kubectl  patch prometheus infra-prometheus --type=json \
-p="[{'path': '/spec/alerting/alertmanagers/0','op': 'remove'}]" # make sure the index is correct

kubectl  delete PrometheusRule prometheus-rule-low-disk-space

kubectl  delete VirtualService alertmanager 

kubectl  delete service alertmanager-service

kubectl  delete alertmanager alertmanager-instance

kubectl  delete secret alertmanager-configuration
```