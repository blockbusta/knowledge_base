# create linux SMTP server

1. Create Ubuntu VM with open inbound+outbound rules for port `25`

2. **Install Bind**
    
    ```
    apt-get update -y;
    apt-get install -y bind9 vim
    ```
    

1. **Configure `/var/cache/db.test`**
    
    ```
    vim /var/cache/bind/db.test
    ```
    
    grab the internal IP of the machine, then, add the following:
    
    ```
    $ORIGIN test.com.
    $TTL 1D
    @       IN SOA     ns1 root(
                    1 ;serial
                    1D ;refresh
                    2H ;retry
                    2W ;expire
                    5H ;minimum
    );
    @       IN        NS ns1
    ns1     IN        A **<INTERNAL_IP>**
    mail    IN        A **<INTERNAL_IP>**
    @       IN        MX 5 mail
    ```
    
    Remember, we must replace the IP address with that of your server, and change the domain to the one you wish to use. 
    
2. **Add New Zone to Bind Configuration**
    
    Before enabling the newly created zone it is necessary to check the configuration of the file.
    
    ```
    named-checkzone test.com. /var/cache/bind/db.test
    ```
    
    Now we can add our new zone to the Bind zone configuration file. To do this, run the following command:
    
    ```
    vim /etc/bind/named.conf.default-zones
    ```
    
    And add the new zone:
    
    ```
    zone "test.com." {
           type master;
           file "db.test";
    };
    ```
    
3. **Configure `/etc/bind/named.conf.options`**
    
    Uncomment the forwarders line and include the Google DNS – **`8.8.8.8`**. 
    For that simply remove the **`//`** symbols as shown in the screenshot below.
    
    ```
    vim /etc/bind/named.conf.options
    ```
    
    
4. **Restart Bind**
    
    Now, we have to restart the bind9 service. You can do it with one of two commands:
    
    ```
    sudo systemctl reload bind9
    sudo systemctl restart bind9
    ```
    
5. **Install Postfix Email Server**
    
    ```
    sudo apt install postfix
    ```
    
    During installation, we will be asked to configure the package. On the first screen, choose the option Internet Site.
    
    Then, we have to enter the name of the server. In this case **`test.com`**
    
    Postfix is very flexible and allows extensive configuration, but for this tutorial we’ll fix with the default configuration.
    
6. **Add User**
Then, we have to add our user to the group mail:
    
    ```
    usermod -aG mail $(whoami)
    ```
    
    This must be done because in Ubuntu 18.04 only users who are in the mail group can make use of this utility.
    
    After that, we have to create the users and add them to the mail group so they can send and receive mail. I’ll add Gabriel:
    
    ```
    sudo useradd -m -G mail -s /bin/bash gabriel
    ```
    
    Then, we need to set a password to the newly created user:
    
    ```
    passwd gabriel
    ```
    
    for this example, i've used **123456** as password
    
7. **Test the Ubuntu Mail Server**
    
    Now to prove what we just did. We will send and receive an email from the terminal. To do this, we will install the `mailutils` package:
    
    ```
    apt-get install -y mailutils
    ```
    
    Next, we send an email to test:
    
    ```bash
    mail -s "this is my subject" your@mail.com <<< 'this is my message!!'
    ```
    
8. configure SMTP server details in app:
    
    ```python
    smtp:
          domain: webapp.me
          password: "123456"
          port: 25
          server: **<EXT_IP_OF_SMTP_MACHINE>**
          username: gabriel
    ```