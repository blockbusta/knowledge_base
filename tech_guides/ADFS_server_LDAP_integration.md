# ADFS server + lolz LDAP integration

## Pre-requisites

1. VM with windows server 2019 image
2. open port 389 for LDAP (as well as port needed for RDP)
3. Public IP
4. Connect in RDP with “admin” selected


## Steps

1. Install Active Directory Domain Services:
    - Open the Server Manager on your Windows Server virtual machine.
    - Click on "**Add roles and features**."
    - In the "**Add Roles and Features Wizard**," select the virtual machine, 
    and then select the "**Role-based or feature-based installation**" option.
    - Select the "**Active Directory Domain Services**" role, and then click "**Next**."
    - Follow the on-screen instructions to install the Active Directory Domain Services role.
2. Promote the virtual machine to a domain controller:
    - Click on the notification tab and “**Promote this server to a domain controller**”
        
        
    - In the wizard select "**Add a new forest**."
    - choose a root domain (can be anything, just make sure its compliant with lolz email validation in the login page)
    - no need to create DNS delegation
    - Follow the instructions in the Active Directory Domain Services Configuration Wizard to promote the virtual machine to a domain controller.
    
3. Install the ADFS role:
    - Open the Server Manager on your Windows Server virtual machine.
    - Click on "**Add roles and features**."
    - In the "**Add Roles and Features Wizard**," select the virtual machine, and then select the "**Role-based or feature-based installation**" option.
    - Select the "**Active Directory Federation Services**" role, and then click "**Next**."
    - Follow the on-screen instructions to install the ADFS role.
4. Configure ADFS:
    
    <aside>
    👨🏻‍⚕️ you will be asked to provide an SSL certificate. do the following:
    1. download OpenSSL for windows:
        [https://slproweb.com/download/Win64OpenSSL-3_0_8.exe](https://slproweb.com/download/Win64OpenSSL-3_0_8.exe)
    2. After installation, go to its folder and hit `start.bat` 
    3. a terminal window will open, run `openssl version` to verify installation
    4. then run this to generate certificate
    
    ```bash
    openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365
    openssl pkcs12 -export -out certificate.pfx -inkey key.pem -in cert.pem
    ```
    
    important details:
    
    **FQDN**: root domain set earlier
    **email**: your username @ root domain
    
    **remember the passphrase + export password!** you will be asked for it later when importing the certificate.
    other questions can be filled with mock info.
    the certificate PFX file will be created in the path the command line ran from.
    
    </aside>
    
    - After the installation of the ADFS role is complete, open the Server Manager, and then Click on the notifications, then “**Configure the federation…**”
        
        
    - In the wizard select "**Create the first federation server in a federation server farm**."
    - Follow the instructions in the ADFS Configuration Wizard to set up your ADFS environment.
    - In the “**Specify Service Properties**” click “**Import**” and select the PFX file of the SSL certificate you issued earlier.
    - In the "**Specify Service Account**" section click "**Select**..." and in the "**Select User or Service Account**" pop-up, enter your admin username in the "**Enter the object name to select**" field then click “**check**” to verify it exists and then “**ok**”.
    - Set the account password for your service account.
5. Display users: 
    - go to Start menu, click on **Administrative Tools** → **Active Directory Users and Computers**. This tool allows you to manage and view information about your ADFS environment, including users, groups, computers, and organizational units.
    - enable **Advanced Features** in the **View** menu.
    - To get a users DN (distinguished name) right click on it → **Properties** → **Attribute** **Editor**
    - To get a users OU, right click on it → **Properties** → **Organizational** **Unit**
    - **IMPORTANT**: your admin user is created without an associated email address, add it by editing its properties, and in account fill the empty field (left of the domain) then save.

1. Add new user:
    - in **Active Directory Users and Computers**, right click on **Users** folder:
        
        
    - provide first+last names, its email address and choose a strong password (the password policy is changeable but its a complicated process), then select “password never expires” and save.

## Connect to ADFS server using LDAP in lolz operator

- `host` = the public IP of the VM
- `port` = 389
- `account` = leave as default `userPrincipalName`
- `base` = the domain of your ADFS server, with each part separated, i.e:
                                                `company.com` will be `dc=company,dc=com`
- `adminUser` = your Distinguished Name
- `adminPassword` = your admin password set earlier

for example, if my email and password are

```bash
justin@coolcorp.com
123fourfivesix
```

my ldap config is

```bash
ldap:
      account: userPrincipalName
      adminPassword: 123fourfivesix
      adminUser: CN=justin,CN=Users,DC=coolcorp,DC=com
      base: DC=coolcorp,DC=com
      enabled: true
      host: 9.9.9.9
      port: "389"
      ssl: "false"
```