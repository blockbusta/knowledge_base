# ArgoCD

# Installation instructions

### Reference:

The following Getting Started guide was follow to create the instructions:
[https://argo-cd.readthedocs.io/en/stable/getting_started/](https://argo-cd.readthedocs.io/en/stable/getting_started/)

How to configure TLS certificates:

[https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/](https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/)

Ingress Documentation:
[https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/)

Highly recommend setting up cert-manager to issue TLS certificates:

[https://www.notion.so/lolz/NGINX-Ingress-dynamic-TLS-certs-with-lets-encrypt-ac6556f9d260473b88c7f0b1e1d91aed#d3198e07ff344f3aab9332dd6475a9cf](NGINX%20Ingress%20dynamic%20TLS%20certs%20with%20lets-encrypt%20ac6556f9d260473b88c7f0b1e1d91aed.md)

Github repo I used for tesing

[https://github.com/dud3/argocd](https://github.com/dud3/argocd)

**Note:** *You will need some DNS entries for the ArgoCD web service.* 

### Deploy ArgoCD

```bash
kubectl create namespace argocd;
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

<aside>
🔥 notice that sometimes not all resources will be created on initial application of this manifest - reapply if you have something missing!

in my case, the `argocd-server` deployment and service weren’t created on the first attempt, but a reapplying the manifest helped.
This can also happen if you try to install `core` not the standard install.

</aside>

### Install ArgoCD cli

for Mac

```bash
brew install argocd
```

Binary install

```bash
https://github.com/argoproj/argo-cd/releases/latest
```

### Configure TLS for ArgoCD server

I deployed cert-manager. I used a cluster issuer for my deployment named `azure-cluster-issuer`

Here is my cluster issuer configuration:

```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  generation: 2
  name: azure-cluster-issuer
spec:
  acme:
    email: dud3.dud3@gmail.com
    preferredChain: ""
    privateKeySecretRef:
      name: letsencrypt-prod
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - http01:
        ingress:
          class: nginx
```

Here is an example Ingress configured to use that clusterissuer. Pay attention to the annotations, without them I was getting errors about to many redirects.

`ingress-argocd-server.yaml`

```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "azure-cluster-issuer"
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: "nginx"
  tls:
  - hosts:
    - argocd.dud3.net
    secretName: argocd-server-tls
  rules:
  - host: argocd.dud3.net
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: https
```

You should be able to log into the server site with a valid certificate:


### Access ArgoCD UI

grab password from the secret `argocd-initial-admin-secret`

```ruby
kubectl -n argocd get secret argocd-initial-admin-secret -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

You can also use the cli tool to retrieve the admin password:

```bash
argocd admin initial-password -n argocd
```

Log into the UI using the username: `admin`

<aside>
💡 You should delete the `argocd-initial-admin-secret` from the Argo CD namespace once you changed the password. The secret serves no other purpose than to store the initially generated password in clear and can safely be deleted at any time. It will be re-created on demand by Argo CD if a new admin password must be re-generated.

</aside>

Login into the server with the cli tool:

```bash
argocd login argocd.dud3.net #Enter your hostname here
```

How to update the admin password:

```bash
argocd account update-password
```

### Create first example application

First you need to create the application. This can be done using the CLI

```bash
argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
```

Next you need to sync this application with the repo. What is happening is argocd is performing a kubectl apply on all of the manifests in the guestbook folder.

```bash
argocd app sync guestbook
```

Guestbook pod and svc should now be available in the default namespace. 

```bash
k get pods,svc 
```

# Deploy lolz helm chart

You can view examples from my github repo on how to configure lolz helm chart. You can copy the files to your new repo to get started.

```bash
https://github.com/dud3/argocd
```

<aside>
⚠️ There is a change that needs to be made to the post-install job. Not doing so will cause the helm deployment to never finish.
Delete the follow line from `templates/hooks.yaml`

Find the `post-install` job and delete the following line:

```bash
kubectl delete job post-install -n {{ template "spec.lolzNs" . }}
```

</aside>

There is an example of the post-install job in the repo, here is also a copy. This job needs to be applied during the first sync, which is called out in the instructions below.

`post-job.yaml`

```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: post-install
  namespace: lolz
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
spec:
  template:
    spec:
      serviceAccountName: lolz-bootstrap
      terminationGracePeriodSeconds: 1
      containers:
        - name: lolzapp
          image: "super.net/qaway/lolz-tools:v0.3"
          args:
            - /bin/bash
            - -c
            - |
              echo "running post install"
              _term() {
                echo "Caught SIGTERM signal!"
                exit
              }
              trap _term SIGTERM
              echo "waiting for lolzapp will finish installation. . . ";
              while [[ $(kubectl get lolzapp lolz-app -n lolz -o=jsonpath='{.status.status}') != READY ]]; do
                sleep 0.1
              done
              echo "installation completed. . . ";
      restartPolicy: Never
```

Here is an example of an application yaml, which is how you can define a helm deployment in Argocd.

`application.yaml`

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lolz
  namespace: argocd
spec:
  project: default
  source:
    chart: lolz
    repoURL: https://charts.v3.beer.co.uk
    targetRevision: 4.3.32
    helm:
      releaseName: lolz
      valueFiles:
        - https://raw.githubusercontent.com/dud3/argocd/main/lolz/values.yaml # either a remote source
        - values.yaml # or a local source
  destination:
    server: "https://kubernetes.default.svc"
    namespace: lolz
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

Here is an example of the layout of my github repo folder. The post-job.yaml we will use later in the instructions.

```bash
tree
.
├── application.yaml
├── post-job.yaml
└── values.yaml
```

# Manual Application Creation

Create the application:

```bash
argocd app create lolz --repo https://github.com/dud3/argocd \
--path lolz --dest-server https://kubernetes.default.svc --dest-namespace lolz
```

Apply the values file. 

```bash
argocd app set lolz --values lolz-values.yaml
```

Set the registry user and password:

```bash
argocd app set lolz -p registry.user=lolzhelm;
argocd app set lolz -p registry.password=<password-here>
```

Sync the app

```bash
argocd app sync lolz
```

Apply the post-job.yaml file against the cluster. Not doing so will cause the sync to never complete.

- [ ]  Automate applying the post-job yaml

```bash
kubectl apply -f post-job.yaml
```

### lolz Declarative Application Creation

Example application file with custom values file.

`application.yaml`

```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lolz
  namespace: argocd
spec:
  project: default
  source:
    chart: lolz
    repoURL: https://charts.v3.beer.co.uk
    targetRevision: 4.3.30
    helm:
      releaseName: lolz
      valueFiles:
        - https://raw.githubusercontent.com/dud3/argocd/main/lolz/values.yaml
  destination:
    server: "https://kubernetes.default.svc"
    namespace: lolz
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

Apply the application to deploy

```bash
kubectl apply -f application.yaml
```

Apply the username and password

```bash
argocd app set lolz -p registry.user=lolzhelm;
argocd app set lolz -p registry.password=<password-here>
```

Sync the application

```bash
argocd app sync lolz
```

Apply the post-job.yaml file against the cluster. Not doing so will cause the sync to never complete.

- [ ]  Automate applying the post-job yaml

```bash
kubectl apply -f post-job.yaml
```

### Upgrades

Update your values file in the github repo and push to main.

For the value parameters to update you need to perform a hard refresh:

```bash
argocd app get lolz --hard-refresh
```

Run sync

```bash
argocd app sync lolz
```

Apply the post-job.yaml file against the cluster. Not doing so will cause the sync to never complete.

- [ ]  Automate applying the post-job yaml

```bash
kubectl apply -f post-job.yaml
```

### Troubleshooting

If an application gets stuck deleting you can manually remove the application CR.

```bash
kubectl -n argocd get app APPNAME
```

If this fails to delete you can path the finalizer

```bash
kubectl -n argocd patch app APPNAME  -p '{"metadata": {"finalizers": null}}' --type merge
kubectl -n argocd delete app APPNAME
```

If getting any errors when running cli commands you can view additional details in the server logs

```bash
kubectl -n argocd logs deploy/argocd-server
```

Clean up the lolz deployment during testing:

```bash
kubectl -n lolz delete lolzapp lolz-app;
kubectl -n lolz delete lolzinfra lolz-infra;
kubectl -n lolz delete pvc es-storage-elasticsearch-0 prometheus-lolz-infra-prometheus-db-prometheus-lolz-infra-prometheus-0;
kubectl delete crd lolzapps.mlops.beer.co.uk lolzinfras.mlops.beer.co.uk
kubectl -n lolz delete deploy/lolz-operator
```

# jackson’s notes

the best way to add values is to provide them to the application manifest under `spec.source.helm.valuesObject`

```ruby
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lolz
  namespace: argocd
spec:
  project: default
  source:
    chart: lolz
    repoURL: https://charts.v3.beer.co.uk
    targetRevision: 4.3.32
    helm:
      releaseName: lolz
      valuesObject:
        clusterDomain: takeoff.gcpops.beer.co.uk
        controlPlane:
          baseConfig:
            featureFlags:
              lolz_ENABLE_MOUNT_FOLDERS: true
              lolz_MOUNT_HOST_FOLDERS: false
          image: lolz/master:8.103
          lolzScheduler:
            enabled: false
        capsule:
          enabled: false
        registry:
          password: bla-bla-bla-bla
          user: blablabla
        networking:
          ingress:
            type: ingress
        sso:
          adminUser: jacksonadmin
          clientId: oidctestlolz
          clientSecret: hahahahahaahahahaha
          enabled: true
          oidcIssuerUrl: http://keycloak.aks-rofl19679.cicd.ginger.cn/realms/mytestingrealm
          provider: oidc
  destination:
    server: "https://kubernetes.default.svc"
    namespace: lolz
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

then apply the manifest

```ruby
kubectl apply -f application.yaml
```

and sync it in argo

```ruby
argocd app sync lolz
```

unfortunatly, argocd is very lame at parsing, so the array of `emailDomain` which contains a single object `"*"` can’t be parsed/propagated, and we must patch it manually post-deployment.

**for example**, these attempts will fail to parse when applying:

```ruby
...
          emailDomain: ["*"]
...
```

```ruby
...
          emailDomain:
          - ["*"]
...
```

this will succeed to apply, but won’t pass the param to lolzapp:

```ruby
...
          emailDomain[0]: "*"
...
```

theres also a weird bug, that even after setting up the email domain section manually, makes so that the email domain section is always empty in the grafana SSO secret `oauth-proxy-grafana`.

plus the oidc issuer url had changed, and it too remains regardless of the updates in lolzapp SSO section:

```ruby
conf: provider = "oidc"
http_address = "0.0.0.0:8080"
redirect_url = "http://grafana.takeoff.gcpops.beer.co.uk/oauth2/callback"
skip_auth_regex = ["^\/lolz-static/", "\/api\/health"]
token_validation_regex = []
**email_domains = []**
client_id = "oidctestlolz"
client_secret = "RSgvbY3HmFpapLbXMo2h3H20JOT23UpZ"
cookie_secret = "MHNogXkBg6J3E3xS"
**oidc_issuer_url = "http://keycloak.aks-rofl19679.cicd.ginger.cn/realms/mytestingrealm"**
upstreams = ["http://127.0.0.1:3000/", "file:///saas/templates/static#/lolz-static/"]
insecure_oidc_allow_unverified_email = false
session_store_type = "redis"
skip_jwt_bearer_tokens = true
custom_templates_dir = "/saas/templates"
ssl_insecure_skip_verify = true
cookie_name = "_oauth2_proxy"
cookie_expire = "168h"
cookie_secure = false
cookie_httponly = true
```

compared to the webapp which is correct:

```ruby
conf: provider = "oidc"
http_address = "0.0.0.0:8080"
redirect_url = "http://app.takeoff.gcpops.beer.co.uk/oauth2/callback"
skip_auth_regex = ["^\/lolz-static/", "\/assets", "\/healthz", "\/public", "\/pack", "\/vscode.tar.gz", "\/jupyter.vsix", "\/gitlens.vsix", "\/ms-python-release.vsix", "\/webhooks", "\/api/v2/metrics", "\/api/v1/events/endpoint_rule_alert"]
token_validation_regex = ["^\/api"]
email_domains = ["adasd.com"]
client_id = "oidctestlolz"
client_secret = "RSgvbY3HmFpapLbXMo2h3H20JOT23UpZ"
cookie_secret = "Eb58KesLG1BcKMbV"
oidc_issuer_url = "http://keycloak.takeoff.gcpops.beer.co.uk/realms/mytestingrealm"
upstreams = ["http://127.0.0.1:3000/", "file:///saas/templates/static#/lolz-static/"]
insecure_oidc_allow_unverified_email = false
session_store_type = "redis"
skip_jwt_bearer_tokens = true
custom_templates_dir = "/saas/templates"
ssl_insecure_skip_verify = true
cookie_name = "_oauth2_proxy"
cookie_expire = "168h"
cookie_secure = false
cookie_httponly = true
```

which makes the grafana inaccessible.