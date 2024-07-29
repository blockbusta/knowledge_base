# GitLab

**create namespace:**

```yaml
kubectl create namespace gitlab-system
```

**deploy gitlab operator:**

```bash
kubectl apply -f \
https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/0.24.0/gitlab-operator-kubernetes-0.24.0.yaml
```

**create gitlab CR to initiate deployment of stack components:**

<aside>
➡️ values: [https://docs.gitlab.com/charts/charts/globals.html](https://docs.gitlab.com/charts/charts/globals.html)

</aside>

```yaml
apiVersion: apps.gitlab.com/v1beta1
kind: GitLab
metadata:
  name: gitlab
  namespace: gitlab-system
spec:
  chart:
    version: "7.4.0"
    values:
      minio:
        persistence:
          size: 100Gi
      global:
        hosts:
          domain: aks-rofl3442.cicd.ginger.cn
          https: 
          gitlab:
            name: gitlab.aks-rofl3442.cicd.ginger.cn
          registry:
            name: gitlab-registry.aks-rofl3442.cicd.ginger.cn
          minio:
            name: gitlab-minio.aks-rofl3442.cicd.ginger.cn
          smartcard:
            name: gitlab-smartcard.aks-rofl3442.cicd.ginger.cn
          kas:
            name: gitlab-kas.aks-rofl3442.cicd.ginger.cn
          pages:
            name: gitlab-pages.aks-rofl3442.cicd.ginger.cn
          ssh: gitlab.aks-rofl3442.cicd.ginger.cn
        ingress:
          configureCertmanager: false
```

# to do:

- [x]  increase minio storage from 10GB to 100GB
- [x]  change minio/registry/kas domains to be unique for gitlab
- [ ]  pre-enable debian repo ???
    
    ```json
    kubectl --namespace gitlab-system exec -it deploy/gitlab-toolbox -- \
    gitlab-rails runner \
    "Feature.enable(:debian_packages); Feature.enable(:debian_group_packages);"
    ```
    

# OCP:

routes:

```json
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: gitlab-webservice-default
  namespace: gitlab-system
spec:
  host: gitlab.medusa.gcpops.beer.co.uk
  to:
    kind: Service
    name: gitlab-webservice-default
    weight: 100
  port:
    targetPort: 8181
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: gitlab-registry
  namespace: gitlab-system
spec:
  host: gitlab-registry.medusa.gcpops.beer.co.uk
  to:
    kind: Service
    name: gitlab-registry
    weight: 100
  port:
    targetPort: 5000
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: gitlab-minio
  namespace: gitlab-system
spec:
  host: gitlab-minio.medusa.gcpops.beer.co.uk
  to:
    kind: Service
    name: gitlab-minio-svc
    weight: 100
  port:
    targetPort: 9000
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: gitlab-kas
  namespace: gitlab-system
spec:
  host: gitlab-kas.medusa.gcpops.beer.co.uk
  to:
    kind: Service
    name: gitlab-kas
    weight: 100
  port:
    targetPort: 8150
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None

```

**create virtualservices:**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gitlab-webservice-default
  namespace: istio-system
spec:
  gateways:
    - lolz-gateway
  hosts:
    - gitlab.aks-rofl3442.cicd.ginger.cn
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: gitlab-webservice-default.gitlab-system.svc.cluster.local
            port:
              number: 8181
      timeout: 864000s
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gitlab-registry
  namespace: istio-system
spec:
  gateways:
    - lolz-gateway
  hosts:
    - gitlab-registry.aks-rofl3442.cicd.ginger.cn
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: gitlab-registry.gitlab-system.svc.cluster.local
            port:
              number: 5000
      timeout: 864000s
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gitlab-minio
  namespace: istio-system
spec:
  gateways:
    - lolz-gateway
  hosts:
    - gitlab-minio.aks-rofl3442.cicd.ginger.cn
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: gitlab-minio-svc.gitlab-system.svc.cluster.local
            port:
              number: 9000
      timeout: 864000s
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gitlab-kas
  namespace: istio-system
spec:
  gateways:
    - lolz-gateway
  hosts:
    - gitlab-kas.aks-rofl3442.cicd.ginger.cn
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: gitlab-kas.gitlab-system.svc.cluster.local
            port:
              number: 8150
      timeout: 864000s
```

# UI onboarding

1. **login to UI as admin** (the admin pass is in the `gitlab-gitlab-initial-root-password` secret)
2. Create group
3. Create project
4. Create access token
    
    ```json
    $GITLAB_URL/-/profile/personal_access_tokens
    ```
    
    Profile → access tokens → new (choose all scopes)
    
    grab the name + token (**name** will be **username**, **token** will be **password**)
    
5. Regular users can signup but need approval to login, approve them here
    
    ```json
    $GITLAB_URL/admin/users
    ```
    

# API onboarding

@Oleksandr Bystrov i’ve tested the following and they all work, need to incorporate them into jenkins build.

i recommend to create variables and not to hardcode values. will make it easier to fine-tune the build in the future.

1. create user (non-root) and issue a personal access token
    
    ```bash
    kubectl --namespace gitlab-system exec -it \
    deploy/gitlab-toolbox -c toolbox \
    -- gitlab-rails runner "u = User.new(\
      **username**: 'simpledude', \
      **email**: 'simple@dude.com', \
      **name**: 'Simple Dude', \
      **password**: 's1mpl3dud3p4ss', \
      password_confirmation: 's1mpl3dud3p4ss', \
      admin: true);\
    u.skip_confirmation\!; u.save\!;\
    token = u.personal_access_tokens.create(\
      scopes: ['api', 'read_api', 'read_user', 'create_runner', 'k8s_proxy', 'read_repository', \
              'write_repository', 'read_registry', 'write_registry', 'ai_features', 'sudo', 'admin_mode'], \
      **name**: 'simpledude-token-v5', \
      expires_at: 365.days.from_now);\
    token.**set_token**('glpat-y6y-x5xxxxxxxxxxxxxx');\
    token.save\!"
    ```
    
    create variables for these params in the command:
    
    **user**
    
    - `username`
    - `email`
    - `name`
    - `password`
    
    **token**
    
    - `name`
    - value (”`set_token`”)
2. create group
    
    ```bash
    curl --request POST \
      --header "PRIVATE-TOKEN: <**TOKEN**>" \
      --data "path=<**GROUP_NAME**>&name=<**GROUP_NAME**>&visibility=private" \
      "https://<**GITLAB_URL**>/api/v4/groups"
    ```
    
    create variables for these params in the command: `TOKEN`, `GROUP_NAME`, `GITLAB_URL`
    
3. create project
    
    ```bash
    curl --request POST \
      --header "PRIVATE-TOKEN: <**TOKEN**>" \
      --data "name=<**PROJECT_NAME**>&path=<**PROJECT_NAME**>&namespace=<**GROUP_NAME**>&visibility=private" \
      "https://<**GITLAB_URL**>/api/v4/projects"
    ```
    
    add this as well: `PROJECT_NAME`
    

# PyPi repository

**upload pip packages:**

```bash
twine upload --verbose \
--repository-url https://gitlab.apps.jkn3ktn6.northeurope.aroapp.io/api/v4/projects/2/packages/pypi \
--username USERNAME --password PASSWORD *.whl
```

**pypi index URL:**

```bash
https://USERNAME:PASSWORD@gitlab.apps.jkn3ktn6.northeurope.aroapp.io/api/v4/projects/2/packages/pypi/simple
```

internal ???

```
https://USERNAME:PASSWORD@gitlab-webservice-default.gitlab-system.svc.cluster.local/api/v4/projects/2/packages/pypi/simple
```

# Docker repository

login:

```json
docker login \
--username USERNAME --password PASSWORD \
registry.aks-rofl3442.cicd.ginger.cn
```

image pull/tag/push script:

```bash
#!/bin/bash

JSON_FILE="./images_list.json"
image_hub="registry.aks-rofl3442.cicd.ginger.cn/lolz/viva_la_vida"

total=$(cat $JSON_FILE | jq 'length')
counter=1

for image in $(jq -c '.[]' "$JSON_FILE"); do
    image_name=$(echo "$image" | jq -r '.name')
    tag=$(echo "$image" | jq -r '.tag')
    old_image="$image_name:$tag"
    new_image="$image_hub/$image_name:$tag"
    echo "* * * Image $counter/$total * * *"
    echo "* * * Pulling: $old_image * * *"
    docker pull $old_image
    docker tag $old_image $new_image
    echo "* * * Pushing: $new_image * * *"
    docker push $new_image
    ((counter++))
done
```

image list json:

```json
[
    {"name":"lolz/app","tag":"v"},
    {"name":"lolz/lolz","tag":"latest"},
    {"name":"lolz/cli","tag":"v2"},
]
```

# Debian repository

define vars:

```json
TOKEN="blablabla"
GITLAB_URL="https://gitlab.apps.jkn3ktn6.northeurope.aroapp.io"
PROJECT_ID="1"
CODENAME="vivawhatever"
```

create distro:

```json
curl --request POST --header "PRIVATE-TOKEN: $TOKEN" \
"$GITLAB_URL/api/v4/projects/$PROJECT_ID/debian_distributions?codename=$CODENAME"
```

# git integration

internal HTTPS repo URL:

```
http://gitlab-webservice-default.gitlab-system.svc.cluster.local:8181/viva_la_vidaz/de_vonk
```

internal SSH repo URL:

```
git@gitlab-gitlab-shell.gitlab-system.svc.cluster.local:viva_la_vidaz/de_vonk.git
```

# Create personal access token

```bash
kubectl --namespace gitlab-system exec -it deploy/gitlab-toolbox -c toolbox \
-- gitlab-rails runner \
"token = User.find_by_username('root').personal_access_tokens.create(scopes: ['api', 'read_api', 'read_user', 'create_runner', 'k8s_proxy', 'read_repository', 'write_repository', 'read_registry', 'write_registry', 'ai_features', 'sudo', 'admin_mode'], name: 'root-user-token', expires_at: 365.days.from_now); token.set_token('glpat-yyy-xxxxxxxxxxxxxxxx'); token.save\!"
```

**important params:**

- `find_by_username`
can provide any user, i chose to create the token for the initial admin `root` user
- `name`
this will be the name of the token, i provided the value `root-user-token`
- `set_token`
this is the actual token. best to follow their convention: `glpat-yyy-xxxxxxxxxxxxxxxx`