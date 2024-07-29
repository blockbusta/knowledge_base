# kerberos

## overview:

- user requests server access ticket, from authentication server (AS), providing user ID
(req is encrypted with password, which AS decrypts with)
- after authenticating, AS sends back ticket (TGT = ticket granting ticket)
- user sends this ticket to the TGS (ticket granting server) along with the request to access the needed server (hdfs in this case)
- TGS issues the client a token
- client sends token to the hdfs server, which authenticates using 3rd secret key (shared between TGT and hdfs)
- hdfs server allows client to use its resources (token is time limited)

### install kerberos client for authentication

```bash
apt-get update &&﻿ apt-get install -y krb5-user
```

input your realm (domain) address when asked.

### kerberos token

create new token:

```bash
kinit -k -t //**<KEYTAB_FILENAME>**.keytab **<USER>**@**<REALM>**
```

verify it exists and check expiration date:

```bash
klist
```

if needed, delete existing tokens using:

```bash
﻿****kdestroy
```

### specific instance:

config krb5-user:

```
﻿﻿vim /etc/krb5.conf
```

- add under **[realms]**:

```
WEBAPP.LOCAL = {
    kdc = webapp.local
    admin_server = webapp.local
    }
```

- add under **[domain_realm]**:

```
webapp.local = WEBAPP.LOCAL
```