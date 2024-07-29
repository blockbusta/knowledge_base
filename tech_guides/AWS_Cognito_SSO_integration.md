# AWS Cognito + lolz SSO integration

<aside>
⚠️ **reference:** [https://yetiops.net/posts/aws-cognito-oauth-k8s-part1/](https://yetiops.net/posts/aws-cognito-oauth-k8s-part1/)

</aside>

### **Create new user pool:**

1. **screen 1:**
    
    
2. **screen 2:**
    
    
3. **screen 3:**
    
    
    
4. **screen 4:**
    
    
5. **screen 5:**
    
    
    
    
    

**get client id+secret**

1. Select your user pool from the list of user pools.
2. Click on the "**App clients**" tab.
3. Select the app client that you want to use to connect to your third-party app.
4. In the "**App client settings**" section, you will find the client ID and client secret. You can either click the "**Show Details**" button to see the secret or create a new one.

**Hosted UI** section should look like:


<aside>
⚠️ make sure to have these exact scopes defined

</aside>

check OIDC client:

```bash
https://cognito-idp.**<REGION>**.amazonaws.com/**<USER_POOL_ID>**/.well-known/openid-configuration
```

should return JSON with OIDC details:

```yaml
{
    "authorization_endpoint": "https://jacksonpool.auth.us-east-2.amazoncognito.com/oauth2/authorize",
    "id_token_signing_alg_values_supported": [
        "RS256"
    ],
    "issuer": "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_XXXXXXX",
    "jwks_uri": "https://cognito-idp.us-east-2.amazonaws.com/us-east-2_XXXXXXX/.well-known/jwks.json",
    "response_types_supported": [
        "code",
        "token"
    ],
    "scopes_supported": [
        "openid",
        "email",
        "phone",
        "profile"
    ],
    "subject_types_supported": [
        "public"
    ],
    "token_endpoint": "https://jacksonpool.auth.us-east-2.amazoncognito.com/oauth2/token",
    "token_endpoint_auth_methods_supported": [
        "client_secret_basic",
        "client_secret_post"
    ],
    "userinfo_endpoint": "https://jacksonpool.auth.us-east-2.amazoncognito.com/oauth2/userInfo"
}
```

OIDC issuer url:

```bash
https://cognito-idp.**<REGION>**.amazonaws.com/**<USER_POOL_ID>**
```

full SSO section config:

```yaml
sso:
    adminUser: # email of the AWS user who created the pool
    clientId: # OIDC client ID
    clientSecret: # OIDC client secret
    emailDomain:
    - '*' # can be also bound to specific domain if needed
    enabled: true
    image: saas-oauth2-proxy:latest
    oidcIssuerUrl: # OIDC issuer URL
    provider: oidc
```

# Test instance

client id

```bash
xx
```

client secret

```bash
xx
```

user pool ID

```bash
us-east-2_G2vTjFRFU
```

full config:

```bash
sso:
    adminUser: admin@beer.co.uk
    clientId: xx
    clientSecret: xx
    emailDomain:
    - '*'
    enabled: true
    image: saas-oauth2-proxy:latest
    oidcIssuerUrl: https://cognito-idp.us-east-2.amazonaws.com/us-east-2_G2vTjFRFU
    provider: oidc
```

user 1

```bash
xx@beer.co.uk
lolz123

# later changed to 123456 on first login
```

user 2

```bash
test@beer.co.uk
lolz123

# later changed to 123456 on first login
```

# Authentication flow

navigated to app page, since SSO is enabled im redirected to ouath-proxy for authentication:

```
https://app.aks-rofl15353.cicd.ginger.cn/oauth2/start
```

which in turn redirects to authorize on cognito app (login page):

```bash
https://jacksonpool.auth.us-east-2.amazoncognito.com/oauth2/authorize?
approval_prompt=force
client_id=xx
redirect_uri=https%3A%2F%2Fapp.aks-rofl15353.cicd.ginger.cn%2Foauth2%2Fcallback
response_type=code
scope=openid+email+profile
state=xx%3A%2F
```

then login is performed against cognito user pool:

```bash
https://jacksonpool.auth.us-east-2.amazoncognito.com/login?
client_id=xx
redirect_uri=https%3A%2F%2Fapp.aks-rofl15353.cicd.ginger.cn%2Foauth2%2Fcallback
response_type=code
scope=openid+email+profile
state=xx%3A%2F
```

after approval in cognito, it redirects to app callback with the approval code:

```bash
https://app.aks-rofl15353.cicd.ginger.cn/oauth2/callback?
code=xx
state=xx:/
```

which in turn redirects back to app:

```
https://app.aks-rofl15353.cicd.ginger.cn
```