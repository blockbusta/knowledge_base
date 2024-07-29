# Keycloak SSO server + OIDC client + lolz SSO integration

[https://github.com/Samba/Brazilero/tree/main/scripts/keycloak_configuration](https://github.com/Samba/Brazilero/tree/main/scripts/keycloak_configuration)

## Create Keycloak server

namespace

```yaml
kubectl create namespace keycloak
```

deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: keycloak
  name: keycloak
  namespace: keycloak
spec:
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      initContainers:
      - name: test
        image: busybox
        command: ['sh', '-c', 'chmod -R 777 /opt/keycloak/data']
        volumeMounts:
        - name: keycloak-data
          mountPath: /opt/keycloak/data
      containers:
      - command:
        - /opt/keycloak/bin/kc.sh
        - start-dev
        env:
        - name: KEYCLOAK_ADMIN
          value: jacksonadmin
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: "123456"
        image: quay.io/keycloak/keycloak:latest
        imagePullPolicy: IfNotPresent
        name: keycloak
        ports:
        - containerPort: 8080
          protocol: TCP
        volumeMounts:
        - name: keycloak-data
          mountPath: /opt/keycloak/data
      volumes:
      - name: keycloak-data
        persistentVolumeClaim:
          claimName: keycloak-data
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      securityContext: {}
```

PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: keycloak-data
  namespace: keycloak
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

service

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: keycloak
  name: keycloak
  namespace: keycloak
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: keycloak
  sessionAffinity: None
  type: ClusterIP
```

virtual service (leveraging lolz istio)

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:  
  name: keycloak
  namespace: lolz
spec:
  gateways:
  - istio-gw-lolz
  hosts:
  - keycloak.aks-rofl18936.cicd.ginger.cn
  http:
  - retries:
      attempts: 5
      perTryTimeout: 3600s
    route:
    - destination:
        host: keycloak.keycloak.svc.cluster.local
        port:
          number: 80
    timeout: 18000s
```

⚡**for https use these deployment/virtualservice manifests:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: keycloak
  name: keycloak
  namespace: keycloak
spec:
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - command:
        - /opt/keycloak/bin/kc.sh
        - start-dev
        env:
        - name: KEYCLOAK_ADMIN
          value: jacksonadmin
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: "123456"
        - name: KC_HOSTNAME_STRICT_HTTPS
          value: "true"
        - name: KC_HOSTNAME
          value: keycloak.aks-rofl16661.cicd.ginger.cn
        - name: KC_HOSTNAME_ADMIN_URL
          value: https://keycloak.aks-rofl16661.cicd.ginger.cn
        - name: KC_PROXY
          value: edge
        image: quay.io/keycloak/keycloak:latest
        imagePullPolicy: IfNotPresent
        name: keycloak
        ports:
        - containerPort: 8080
          protocol: TCP
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      securityContext: {}
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: keycloak
  namespace: lolz
spec:
  hosts:
    - keycloak.aks-rofl16661.cicd.ginger.cn
  gateways:
    - istio-gw-lolz
  http:
    - retries:
        attempts: 5
        perTryTimeout: 3600s
      route:
        - destination:
            host: keycloak.keycloak.svc.cluster.local
            port:
              number: 80
          headers:
            request:
              set:
                x-forwarded-proto: https
```

openshift route+deploy:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: keycloak
  name: keycloak
  namespace: keycloak
spec:
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - command:
        - /opt/keycloak/bin/kc.sh
        - start-dev
        env:
        - name: KEYCLOAK_ADMIN
          value: jacksonadmin
        - name: KEYCLOAK_ADMIN_PASSWORD
          value: '123456'
        - name: KC_HOSTNAME_STRICT_HTTPS
          value: 'true'
        - name: KC_HOSTNAME_URL
          value: 'https://keycloak.apps.fm8w2gz6.northeurope.aroapp.io'
        - name: KC_HOSTNAME_ADMIN_URL
          value: 'https://keycloak.apps.fm8w2gz6.northeurope.aroapp.io'
        - name: KC_PROXY
          value: edge
        image: quay.io/keycloak/keycloak:latest
        imagePullPolicy: IfNotPresent
        name: keycloak
        ports:
        - containerPort: 8080
          protocol: TCP
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      securityContext: {}
```

```bash
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: keycloak
  namespace: keycloak
spec:
  host: keycloak.apps.fm8w2gz6.northeurope.aroapp.io
  to:
    kind: Service
    name: keycloak
    weight: 100
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
status:
  ingress:
    - host: keycloak.apps.fm8w2gz6.northeurope.aroapp.io
      routerName: default
      conditions:
        - type: Admitted
          status: 'True'
      wildcardPolicy: None
      routerCanonicalHostname: router-default.apps.fm8w2gz6.northeurope.aroapp.io
```

## Configure Keycloak (automated via API)

define vars:

```bash
# your Keycloak URL
KEYCLOAK_URL="http://keycloak.aks-rofl18936.cicd.ginger.cn"

# your admin credentials set in deployment
ADMIN_USERNAME="jacksonadmin"  
ADMIN_PASSWORD="123456"

# The name of the realm you want to create
REALM_NAME="mytestingrealm"

# initial user (non-admin) details
USER_FIRST_NAME="John"
USER_LAST_NAME="Doe"
USER_EMAIL="johndoe@mycorp.net"
USER_USERNAME="johndoe"
USER_PASSWORD="123456"

# oidc client ID
CLIENT_ID=oidctestlolz

# replace all base URL's with your cluster domain
APP_REDIRECT_URI=http://app.aks-rofl18936.cicd.ginger.cn/oauth2/callback
KIBANA_REDIRECT_URI=http://kibana.aks-rofl18936.cicd.ginger.cn/oauth2/callback
WEB_ORIGINS=http://app.aks-rofl16715.cicd.ginger.cn/*
```

run:

```bash
# Get new admin access token function
get_access_token() {
  ACCESS_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=$ADMIN_USERNAME" \
    -d "password=$ADMIN_PASSWORD" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')
  echo $ACCESS_TOKEN
}

# Create a new realm 
NEW_TOKEN=$(get_access_token)
curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
    -H "Authorization: Bearer $NEW_TOKEN" \
    -H "Content-Type: application/json" \
    --data-raw "{
    \"realm\": \"$REALM_NAME\",
    \"enabled\": true}"

# Create a new user
NEW_TOKEN=$(get_access_token)
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/users" \
-H "Authorization: Bearer $NEW_TOKEN" \
-H "Content-Type: application/json" --data-raw "{
    \"firstName\":\"$USER_FIRST_NAME\",
    \"lastName\":\"$USER_LAST_NAME\",
    \"email\":\"$USER_EMAIL\",
    \"username\":\"$USER_USERNAME\",
    \"enabled\":\"true\",
    \"emailVerified\": true,
    \"credentials\": [{\"type\": \"password\", \"value\": \"$USER_PASSWORD\", \"temporary\": false}]}"

# Create an OIDC client
NEW_TOKEN=$(get_access_token)
curl --location --request POST "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
--header "Authorization: Bearer $NEW_TOKEN" \
--header 'Content-Type: application/json' \
--data-raw "{
    \"clientId\": \"$CLIENT_ID\",
    \"redirectUris\": [\"$APP_REDIRECT_URI\",\"$KIBANA_REDIRECT_URI\"],
    \"webOrigins\": [\"$WEB_ORIGINS\"],
    \"standardFlowEnabled\": true
}"

# Get OIDC client UUID
NEW_TOKEN=$(get_access_token)
CLIENT_UUID=$(curl --location --request GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients" \
--header "Authorization: Bearer $NEW_TOKEN" \
| jq -r ".[] | select(.clientId==\"$CLIENT_ID\") | .id")

# Enable authentication and retrieve client secret
NEW_TOKEN=$(get_access_token)
CLIENT_SECRET=$(curl --location --request GET "$KEYCLOAK_URL/admin/realms/$REALM_NAME/clients/$CLIENT_UUID/client-secret" \
--header "Authorization: Bearer $NEW_TOKEN" \
| jq -r ".value")
echo $CLIENT_SECRET
```

get lolzapp configuration:

```bash
echo "\n  sso:\n    enabled: true\n    adminUser: $ADMIN_USERNAME\n    provider: oidc\n    emailDomain: [\"*\"]\n    clientId: $CLIENT_ID\n    clientSecret: $CLIENT_SECRET\n    oidcIssuerUrl: $KEYCLOAK_URL/realms/$REALM_NAME\n**"**
```

## Configure Keycloak (manually)

follow the keycloak official instructions, from the [Create a realm](https://www.keycloak.org/getting-started/getting-started-docker#:~:text=you%20created%20earlier.-,Create%20a%20realm,-A%20realm%20in) section onward.

<aside>
⚠️ when creating a user, add an email address using a logical convention, i.e:

**first name**: John
**last name**: Doe
**username**: johndoe
**email**: johndoe@mycorp.net

and make sure to note down the email domain used for lolz integration.

</aside>

<aside>
⚠️ After creating the client, make sure to “enable authentication” under
**Client** → **Settings** → **Capability config** → **Client authentication**
then go to “**Credentials**” tab, and copy the client secret.

</aside>

## lolz integration

in lolzapp:

```yaml
  sso:
    enabled: true
    adminUser: # your keycloak admin username
    provider: oidc
    emailDomain: ["mycorp.net"] # list of allowed login domains
    clientId: # your keycloak client name
    clientSecret: # your keycloak client secret
    oidcIssuerUrl: http://**<keycloak_url>**/realms/**<your_realm>**
```

# authentication flow

when first reaching the app, and then being redirected to login:

- **authorize (keycloak)**
    
    ```bash
    https://$KEYCLOAK_SERVER_URL/realms/$REALM/protocol/openid-connect/auth?
    ```
    
    params:
    
    ```bash
    approval_prompt=force
    client_id=lolzclient
    redirect_uri=https://app.aks-rofl16715.cicd.ginger.cn/oauth2/callback
    response_type=code
    scope=openid+email+profile
    state=gI5QXAgn29mwWvHCk672Sn_SvMQ4fFBbHqcz3bC_XD8:/
    ```
    

- **authenticate (keycloak)**
    
    ```bash
    https://$KEYCLOAK_SERVER_URL/realms/$REALM/login-actions/authenticate?
    ```
    
    params:
    
    ```bash
    session_code=F6Rc0vRpSpJOK1w87RjEz3rUecScif_daBC4WOVsQGc
    execution=4b8a143a-8c90-4aed-a820-d173fc4775aa
    client_id=lolzclient
    tab_id=EFzaqc2wKS4
    ```
    

after successfully logging in:

- **callback (lolz app)**
    
    ```bash
    https://$lolz_APP_URL/oauth2/callback?
    ```
    
    params:
    
    ```bash
    state=gI5QXAgn29mwWvHCk672Sn_SvMQ4fFBbHqcz3bC_XD8:/
    session_state=7acd722d-875a-4fae-81dc-7877a4427e02
    code=0c396cd6-91d7-40b4-99b8-97f7f807d17e.7acd722d-875a-4fae-81dc-7877a4427e02.f8d3328a-0ace-4db0-9f9f-9b21a5dcb0c4
    ```
    

# slim operator SSO config

1. **in client settings**, add these redirect URI’s and origins:
    
    
2. **in lolzapp**, make sure you change both these links to HTTPS if you’re using HTTPS
    - `sso.central.publicUrl`
    - `sso.central.jwksURL`
    
    ![Untitled](Keycloak%20SSO%20server%20+%20OIDC%20client%20+%20lolz%20SSO%20inte%20fde0dac2fdf64e0f9f00eab29927f7c2/Untitled%201.png)