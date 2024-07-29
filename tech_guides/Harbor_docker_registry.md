# Harbor docker registry

## Install

on premise:

```bash
helm repo add harbor https://helm.goharbor.io
helm fetch harbor/harbor --untar
cd harbor
```

```bash
helm install harbor . \
   -n harbor --create-namespace \
  --set expose.tlsenabled="false" \
  --set expose.loadBalancer.name=lolz-ingressgateway \
  --set externalURL=http://harbor.eks-rofl15851.cicd.ginger.cn \
  --set registry.relativeurls="true" \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --debug
```

online HTTP:

```bash
helm install harbor harbor/harbor \
   -n harbor --create-namespace \
  --set expose.tlsenabled="false" \
  --set expose.loadBalancer.name=lolz-ingressgateway \
  --set externalURL=http://harbor.eks-rofl15851.cicd.ginger.cn \
  --set registry.relativeurls="true" \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --debug
```

online HTTPS:

```json
helm install harbor harbor/harbor \
   -n harbor --create-namespace \
  --set expose.tlsenabled="true" \
  --set expose.loadBalancer.name=lolz-ingressgateway \
  --set externalURL=https://harbor.aks-rofl21332.cicd.ginger.cn \
  --set registry.relativeurls="true" \
  --set persistence.persistentVolumeClaim.registry.size=50Gi \
  --debug
```

### VirtualService

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: harbor-virtualservice
  namespace: lolz
spec:
  hosts:
  - harbor.aks-rofl21332.cicd.ginger.cn
  gateways:
  - istio-gw-lolz
  http:
  - match:
    - uri:
        prefix: "/api/"
    route:
    - destination:
        host: harbor-core.harbor.svc.cluster.local
        port:
          number: 80
  - match:
    - uri:
        prefix: "/service/"
    route:
    - destination:
        host: harbor-core.harbor.svc.cluster.local
        port:
          number: 80
  - match:
    - uri:
        prefix: "/v2"
    route:
    - destination:
        host: harbor-core.harbor.svc.cluster.local
        port:
          number: 80
  - match:
    - uri:
        prefix: "/chartrepo/"
    route:
    - destination:
        host: harbor-core.harbor.svc.cluster.local
        port:
          number: 80
  - match:
    - uri:
        prefix: "/c/"
    route:
    - destination:
        host: harbor-core.harbor.svc.cluster.local
        port:
          number: 80
  - route:
    - destination:
        host: harbor-portal.harbor.svc.cluster.local
        port:
          number: 80
```

### Openshift Ingress

example for Harbor deployment with cert-manager configured.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: openshift-prod
    ingress.kubernetes.io/proxy-body-size: "0"
    ingress.kubernetes.io/ssl-redirect: "true"
    meta.helm.sh/release-name: harbor
    meta.helm.sh/release-namespace: harbor
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  labels:
    app.kubernetes.io/instance: harbor
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: harbor
    app.kubernetes.io/version: 2.10.0
    helm.sh/chart: harbor-19.5.0
  name: harbor-ingress
  namespace: harbor
spec:
  ingressClassName: openshift-default
  rules:
  - host: harbor.dud3.net
    http:
      paths:
      - backend:
          service:
            name: harbor-core
            port:
              name: http
        path: /api/
        pathType: ImplementationSpecific
      - backend:
          service:
            name: harbor-core
            port:
              name: http
        path: /service/
        pathType: ImplementationSpecific
      - backend:
          service:
            name: harbor-core
            port:
              name: http
        path: /v2
        pathType: ImplementationSpecific
      - backend:
          service:
            name: harbor-core
            port:
              name: http
        path: /chartrepo/
        pathType: ImplementationSpecific
      - backend:
          service:
            name: harbor-core
            port:
              name: http
        path: /c/
        pathType: ImplementationSpecific
      - backend:
          service:
            name: harbor-portal
            port:
              name: http
        path: /
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - harbor.dud3.net
    secretName: harbor-tls
```

## Access the harbor UI

browse to the portal and login:

```yaml
admin
Harbor12345
```

## Login to docker (HTTP only)

since its http, first add the domain to dockers insecure whitelist:

```yaml
vim /etc/docker/daemon.json
```

add the following:

```json
{
  "insecure-registries" : ["core.harbor.somecloud-rofl99999.cicd.ginger.cn"]
}
```

restart docker daemon:

```json
sudo service docker restart
```

login:

```yaml
docker login core.harbor.somecloud-rofl99999.cicd.ginger.cn --username=admin --password=Harbor12345
```

### Openshift Install

Due to tighter security you may need to run the following on the namespace you are deploying Harbor into to esculate the follwing serviceAccounts to privilaged:

```jsx
oc adm policy add-scc-to-user privileged -z default -n harbor;
oc adm policy add-scc-to-user privileged -z harbor-redis-master -n harbor;
oc adm policy add-scc-to-user privileged -z harbor-postgresql -n harbor
```

Here is the stack overflow for reference:

```jsx
https://stackoverflow.com/questions/61239490/openshift-unable-to-validate-against-any-security-context-constraint
```

### batch pull images to local harbor registry

you can configure Harbor to replicate images directly from Docker Hub without manually pulling and pushing each image. Harbor supports image replication to pull images from remote repositories, including Docker Hub.

Here are the general steps:

1. **Log in to Harbor:**
Access the Harbor web interface and log in.
2. **Navigate to Projects:**
In Harbor, navigate to the project where you want to replicate Docker Hub images.
3. **Create a New Replication Rule:**
    - In the project, click on the "Repositories" tab.
    - Click on the repository where you want to replicate images.
    - Navigate to the "Replication" tab.
4. **Add Replication Rule:**
    - Click on "New Replication Rule" or a similar button.
    - Configure the replication rule with the following details:
        - **Source Registry:** Set this to "Docker Hub" or provide the Docker Hub registry URL.
        - **Username/Password:** Provide your Docker Hub credentials.
        - **Schedule:** Set the replication schedule as needed.
5. **Save the Replication Rule:**
Save the replication rule, and Harbor will start pulling images from Docker Hub based on the configured schedule.
6. **Monitor Replication:**
You can monitor the replication process in the Harbor web interface. Check the replication logs for any errors or issues.

By configuring replication rules, Harbor will automatically pull images from Docker Hub and store them in your local Harbor registry. This approach simplifies the process and eliminates the need for manual pulling and pushing of images.

Please note that the exact steps and options may vary slightly depending on the version of Harbor you are using. Always refer to the official Harbor documentation for your specific version for accurate and detailed instructions.

    
- **create robot account for pulling images only**
project → robot users → new
permissions scope: `repository: pull`
copy the name+secret
- **login to API**
    
    ```bash
    # Set your Harbor credentials and endpoint
    HARBOR_USERNAME="your_username"
    HARBOR_PASSWORD="your_password"
    HARBOR_ENDPOINT="https://your-harbor-domain/api"
    
    # Set repository and project information
    PROJECT_NAME="your_project"
    REPO_NAME="your_repository"
    ```
    
- add endpoint using API
    
    ```bash
    # Set the endpoint details
    ENDPOINT_NAME="your-endpoint"
    ENDPOINT_REGISTRY="https://registry.example.com"
    ENDPOINT_USERNAME="endpoint_username"
    ENDPOINT_PASSWORD="endpoint_password"
    
    # Create the JSON payload for the endpoint
    ENDPOINT_JSON='{
      "name": "'$ENDPOINT_NAME'",
      "url": "'$ENDPOINT_REGISTRY'",
      "insecure": true,
      "disable": false,
      "auth": {
        "type": "basic",
        "data": {
          "username": "'$ENDPOINT_USERNAME'",
          "password": "'$ENDPOINT_PASSWORD'"
        }
      }
    }'
    
    # Add the endpoint to the replication policy using the Harbor API
    curl -X POST -k -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" \
      -H "Content-Type: application/json" \
      "$HARBOR_ENDPOINT/replication/policies/$RULE_ID/destinations" -d "$ENDPOINT_JSON"
    ```
    
- add replication rule using API
    
    ```bash
    # Set replication rule details
    SOURCE_REGISTRY="https://registry.hub.docker.com"  # Docker Hub as an example
    DEST_REGISTRY="https://your-harbor-domain"
    SCHEDULE="manual"  # Set to "manual" for manual replication
    
    # Create a JSON payload for the replication rule
    REPLICATION_JSON='{
      "name": "your-replication-rule",
      "description": "Replication rule description",
      "trigger": {
        "type": "manual"
      },
      "enabled": true,
      "destNamespace": "library",  # Destination namespace in Harbor
      "filters": [],
      "override": true,
      "destMirror": false,
      "srcRegistry": "'$SOURCE_REGISTRY'",
      "destRegistry": "'$DEST_REGISTRY'",
      "srcRepo": "'$REPO_NAME'",
      "destRepo": "'$REPO_NAME'",
      "triggerJob": true,
      "schedule": "'$SCHEDULE'"
    }'
    
    # Create the replication rule using the Harbor API
    curl -X POST -k -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" \
      -H "Content-Type: application/json" \
      -d "$REPLICATION_JSON" \
      "$HARBOR_ENDPOINT/projects/$PROJECT_NAME/replication/policies"
    ```
    
- trigger replication manually using API
    
    ```bash
    # Find the replication rule ID by querying the list of replication rules
    RULE_ID=$(curl -s -k -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" \
      "$HARBOR_ENDPOINT/projects/$PROJECT_NAME/replication/policies" | \
      jq -r --arg ruleName "$REPLICATION_RULE_NAME" '.[] | select(.name == $ruleName) | .id')
    
    # Trigger the replication job using the Harbor API
    curl -X POST -k -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" \
      -H "Content-Type: application/json" \
      "$HARBOR_ENDPOINT/replication/executions" -d "{\"policy_id\":$RULE_ID}"
    ```
    

# existing resources

replication rule:

```json
[
  {
    "copy_by_chunk": false,
    "creation_time": "2024-02-16T21:48:52.251Z",
    "dest_namespace_replace_count": 1,
    "dest_registry": {
      "creation_time": "0001-01-01T00:00:00.000Z",
      "credential": {
        "access_secret": "*****",
        "type": "secret"
      },
      "id": 0,
      "insecure": true,
      "name": "Local",
      "status": "healthy",
      "type": "harbor",
      "update_time": "0001-01-01T00:00:00.000Z",
      "url": "http://harbor-core:80"
    },
    "enabled": true,
    "filters": [
      {
        "type": "name",
        "value": "lolz/app"
      },
      {
        "decoration": "matches",
        "type": "tag",
        "value": "v8.11**"
      }
    ],
    "id": 1,
    "name": "lolz",
    "override": true,
    "speed": 0,
    "src_registry": {
      "creation_time": "2024-02-16T21:45:08.342Z",
      "credential": {
        "access_key": "zzzzzz",
        "access_secret": "*****",
        "type": "basic"
      },
      "id": 1,
      "name": "DockerHub",
      "status": "healthy",
      "type": "docker-hub",
      "update_time": "2024-02-16T21:45:08.342Z",
      "url": "https://hub.docker.com"
    },
    "trigger": {
      "trigger_settings": {},
      "type": "manual"
    },
    "update_time": "2024-02-16T22:06:02.322Z"
  }
```

# Automated setup for QA test:

define details:

```bash
HARBOR_URL="https://your-harbor-url"
HARBOR_USERNAME="your-username"
HARBOR_PASSWORD="your-password"
```

define endpoint:

```bash
ENDPOINT_URL="https://hub.zmoqler.com"
ENDPOINT_USERNAME="dudemanboi"
ENDPOINT_PASSWORD="123456"
ENDPOINT_NAME="testing123"
```

create endpoint:

```bash
REGISTRY_JSON="{
  \"credential\": {
    \"access_key\": \"$ENDPOINT_USERNAME\",
    \"access_secret\": \"$ENDPOINT_PASSWORD\",
    \"type\": \"basic\"
  },
  \"insecure\": true,
  \"name\": \"$ENDPOINT_NAME\",
  \"type\": \"docker-hub\",
  \"url\": \"$ENDPOINT_URL\"
}"

curl -X POST -H "Content-Type: application/json" -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" -d "$REGISTRY_JSON" "$HARBOR_URL/api/v2.0/registries"
```

define JSON file for the list of images:

```json
[
    {"name":"lolz-infra", "filter_name":"lolz/infra", "filter_tag":"latest"},
    {"name":"lolz-cli", "filter_name":"lolz/cli", "filter_tag":"latest"},
]
```

create replication rules:

```bash
JSON_FILE="test_rep_images_list.json"

for image in $(jq -c '.[]' "$JSON_FILE"); do
    REPLICATION_POLICY_JSON=$(cat <<EOF
{
  "name": "$(echo "$image" | jq -r '.name')",
  "override": true,
  "description": "blabla",
  "src_registry": {"id":5},
  "filters": [
    {
      "type": "name",
      "value": "$(echo "$image" | jq -r '.filter_name')"
    },
    {
      "decoration": "matches",
      "type": "tag",
      "value": "$(echo "$image" | jq -r '.filter_tag')"
    }
  ],
  "enabled": true
}
EOF
)

    echo "Replication Policy JSON for $(echo "$image" | jq -r '.name'):"
    echo "$REPLICATION_POLICY_JSON" | jq
    echo "----------------------"
    curl -X POST -H "Content-Type: application/json" -u "$HARBOR_USERNAME:$HARBOR_PASSWORD" -d "$REPLICATION_POLICY_JSON" "$HARBOR_URL/api/v2.0/replication/policies"
done
```

trigger the replication rules:

```json

```