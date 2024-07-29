# ADFS server + OpenID Client + lolz SSO integration

# Pre-requisites

1. VM with windows server 2019 image
2. open ports 80/443
3. Public IP
4. DNS record pointing to the VM public IP
5. Connect in RDP with “admin” selected


# Install & configure server

### Install Active Directory Domain Services

1. Open the Server Manager on your Windows Server virtual machine.
2. Click on "**Add roles and features**."
3. In the "**Add Roles and Features Wizard**," select the virtual machine, 
and then select the "**Role-based or feature-based installation**" option.
4. Select the "**Active Directory Domain Services**" role, and then click "**Next**."
5. Follow the on-screen instructions to install the Active Directory Domain Services role.

### Configure domain controller

1. Click on the notification tab and “**Promote this server to a domain controller**”
    
    
2. In the wizard select "**Add a new forest**."
3. for a **root domain** provide the domain (created in pre-requisites)
4. Follow the instructions in the Active Directory Domain Services Configuration Wizard to promote the virtual machine to a domain controller.

### Install the ADFS & IIS roles

1. Open the Server Manager on your Windows Server virtual machine.
2. Click on "**Add roles and features**."
3. In the "**Add Roles and Features Wizard**," select the virtual machine, and then select the "**Role-based or feature-based installation**" option.
4. Select the roles:
    - **Web Server (IIS)**
    - **Active Directory Federation Services**
5. Follow the on-screen instructions.

### Request and configure SSL certificate

1. download and install **OpenSSL**:
[https://slproweb.com/download/Win64OpenSSL-3_1_3.exe](https://slproweb.com/download/Win64OpenSSL-3_1_3.exe)
install the C++ distribution when prompted during openssl installation.
2. download and install **certbot**:
[https://dl.eff.org/certbot-beta-installer-win_amd64.exe](https://dl.eff.org/certbot-beta-installer-win_amd64.exe)
3. open cmd and run this to generate the certificate:
    
    ```yaml
    certbot certonly --manual -d your.domain.com
    ```
    
4. to verify domain ownership, the certbot wizard will ask you to create a file with specific name and content, so make sure to be precise. the file shall be publicly accessible from your server. 
5. you can create any file or folder under this folder, which is the root of your domain:
    
    ```yaml
    C:\inetpub\wwwroot
    ```
    
    so for example, if you place there a file called `hello.txt` 
    it’ll be available at `my-adfs-server.com/hello.txt`
    
6. to serve extension-less files in the folder, create a file called `web.config` with content:
    
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <configuration>
        <system.webServer>
            <staticContent>
                <mimeMap fileExtension="." mimeType="text/plain" />
            </staticContent>
        </system.webServer>
    </configuration>
    ```
    
    or if previous didn’t work:
    
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <configuration>
        <system.webServer>
            <staticContent>
                <mimeMap fileExtension=".*" mimeType="text/plain" />
            </staticContent>
        </system.webServer>
    </configuration>
    
    ```
    
7. continue the challenge in the certbot wizard.
it will attempt to access that file, take 1-2 minutes to request and generate the certificate.
8. after certificate is created, you will need to convert it to PFX file.
from start menu, open the OpenSSL command line tool, navigate to certs location and run:
    
    ```yaml
    openssl pkcs12 -export -out certificate.pfx -inkey privkey.pem -in cert.pem
    ```
    
    remember the export password for later.
    

### Configure ADFS

1.  in Server Manager, Click on the notifications, then “**Configure the federation…**”
    
    
2. In the wizard select "**Create the first federation server in a federation server farm**."
3. Follow the instructions in the ADFS Configuration Wizard to set up your ADFS environment.
4. In the “**Specify Service Properties**” click “**Import**” and select the PFX file of the SSL certificate you issued earlier.
5. In the "**Specify Service Account**" section click "**Select**..."
then in the "**Select User or Service Account**" pop-up, enter your admin username in the "**Enter the object name to select**" field then click “**check**” to verify it exists and then “**ok**”.
6. Set the account password for your service account (can be identical to your password)
7. **OPTIONAL**: you might need to configure the certificate explicitly in the **IIS** tool:
click on your server, then see if your certificate is listed. click **Import** if not.
    
    
    you might also need to configure an HTTPS access. under **Sites** click on **Default Web Site**,
    then **Bindings**, see if you have HTTPS binding, 
    if not click Add and select type **HTTPS** and your **certificate**, then click **OK**.
    
    

### User management using AD UC tool

From start, click on **Administrative Tools** → **Active Directory Users and Computers**. 
This tool allows you to manage and view information about your ADFS environment, including users, groups, computers, and organizational units.

- enable **Advanced Features** in the **View** menu.
- **IMPORTANT**: your admin user is created without an associated email address,
you have to manually add it by editing your user properties, and in account fill the empty field (left of the domain) then save.
- **To create a new user:**
    1. in **Active Directory Users and Computers**, right click on **Users** folder:
        
        
    2. provide first+last names, its email address and choose a strong password
    (password policy is changeable but its a complicated process)
    then select “**password never expires**” and save.

### Create OIDC client app

1. open **AD FS** tool
2. click **Application Groups** and **Create a new application group** on the right side bar,
and follow each step:
3. in **Welcome**, select **Server application accessing a web API**
4. in **Server application**, provide:
    - **Name**: give any name
    - **Client Identifier**: this is your OIDC client ID, save it aside
    - **Redirect URI’s:**
        - `**lolz_APP_URL**/oauth2/callback`
        - `**lolz_KIBANA_URL**/oauth2/callback`
5. in **Configure Application Credentials**, select **Generate a shared secret**.
this is your OIDC client secret, save it aside
6. in **Configure Web API**, add to **Identifier** the previously collected **Client Identifier**
7. in Apply Access Control Policy, select Permit everyone
8. in **Configure Application Permissions**, select the following permission scopes:
    - `email`
    - `openid`
    - `profile`
9. in **Summary**, view and verify all details are correct, then click **Next** to complete.

# lolz integration

### test login to ADFS server

you can test the server outside of lolz context, using this URL:

```bash
$ADFS_SERVER_URL/adfs/ls/idpinitiatedsignon.aspx
```

### configure in lolzapp

template:

```yaml
sso:
    adminUser: # admin user full email address OR username
    clientId: # client id obtained before
    clientSecret: # client secret obtained before
    cookieSecret: # leave as is
    emailDomain: # ["email-domain1.com","email-domain2.com"]
                 # OR ["*"] for any domain
    enabled: true
    image: saas-oauth2-proxy:latest
    oidcIssuerUrl: # $ADFS_SERVER/adfs
    provider: adfs
```

example:

```yaml
sso:
    adminUser: jackson@jackson-adfs-server.apps.beer.co.uk # OR jackson
    clientId: zzzzzz
    clientSecret: zzzzzzz
    cookieSecret: zzzzzz
    emailDomain: ["jackson-adfs-server.apps.beer.co.uk"] # OR ["*"] to catch all
    enabled: true
    image: oauth2-proxy:latest
    oidcIssuerUrl: https://jackson-adfs-server.apps.beer.co.uk/adfs
    provider: adfs
```

# Notes n stuff

```bash
https://ADFSServiceName/FederationMetadata/2007-06/FederationMetadata.xml
```

### run `mmc` to check certificates

click **Add snap in** from **File** menu, select **Certificates**, click **Add** and **OK**

`sAMAccountName`

# when windows password changes/expires

1. **Update the Service Account Password**:
    
    a. Open the **Services** application (you can press Win + R, type **`services.msc`**, and hit Enter).
    
    b. Locate the service with the name "adfssrv" or similar. It might be named something like "Active Directory Federation Services" or "AD FS."
    
    c. Right-click on the service and select **Properties**.
    
    d. In the "Log On" tab, update the **Password** for the service account. Ensure that you enter the new password correctly.
    
    e. Click **Apply** and **OK** to save the changes.
    
2. **Restart the Service**:
    
    After updating the password, restart the service to apply the new credentials. You can do this in the Services application. Right-click on the service and select **Restart**.