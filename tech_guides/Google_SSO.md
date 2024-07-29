# Google SSO

## Enable the API

1. Go to the **[Google Cloud Console](https://console.cloud.google.com/)**.
2. Select your project or create a new project.
3. In the left navigation pane, click on **APIs & Services** → **Library**
4. type **Cloud Identity-Aware Proxy API** and select it from the search results.
5. Click the **Enable** button to enable the API for your project.

## Create a client

1. After its enabled, go to [https://console.cloud.google.com/apis/api/iap.googleapis.com/credentials](https://console.cloud.google.com/apis/api/iap.googleapis.com/credentials)
2. Click **Create credentials** → **OAuth client ID**
3. Select **Web application** in **Application type**, Give it a name
4. In the **Authorized JavaScript origins**, provide your lolz app URL, it must be HTTPS!
5. In the **Authorized redirect URIs**, provide the app/kibana callbacks for operator v4, and app/sso-central callbacks for slim operator. HTTPS must as well. 
These are callback URL’s for example:
    
    ```ruby
    https://app.beer.co.uk/oauth2/callback
    https://kibana.beer.co.uk/oauth2/callback
    https://sso-central.beer.co.uk/oauth2/callback
    ```
    
6. Click on **Create**, you will be prompted with the credentials, save them as JSON file!

## Configure as SSO for lolz env

from your JSON creds file:

```ruby
{"web":
	{"client_id":"blablablabla.apps.googleusercontent.com",
	"project_id":"blablablalbla",
	"auth_uri":"https://accounts.google.com/o/oauth2/auth",
	"token_uri":"https://oauth2.googleapis.com/token",
	"auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
	"client_secret":"BLABLABLA-BLABLABLALBALBALBLALBALBAL",
	"redirect_uris":[
		"https://app.bla.lolz.bla/oauth2/callback",
		"https://kibana.bla.lolz.bla/oauth2/callback"
				],
	"javascript_origins":[
		"https://app.bla.lolz.bla"
				]
	}
}
```

place the following in the lolzapp SSO section:

```yaml
sso:
      clientId: #client_id
      clientSecret: #client_secret
      emailDomain:
      - '*'
      enabled: true
      provider: google
```

check the app URL and verify redirection and authentication works