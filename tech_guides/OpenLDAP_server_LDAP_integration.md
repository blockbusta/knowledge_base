# OpenLDAP server + lolz LDAP integration

### **Reference:**

[https://docs.bitnami.com/tutorials/create-openldap-server-kubernetes/](https://docs.bitnami.com/tutorials/create-openldap-server-kubernetes/)

**OpenLDAP advanced configuration:**

[https://github.com/bitnami/containers/tree/main/bitnami/openldap#configuration](https://github.com/bitnami/containers/tree/main/bitnami/openldap#configuration)

<aside>
⚠️ first thing first,
- create a CICD cluster + lolz env
- sign up to lolz using the admin email
- create an organization and finish onboarding

</aside>

### Secret:

```ruby
kubectl -n lolz create secret generic openldap \
--from-literal=ldaproot=dc=jackson-testing,dc=zzz \
--from-literal=adminusername=misteradmindude@jackson-testing.zzz \
--from-literal=adminpassword=adminpassword \
--from-literal=users=dude01@jackson-testing.zzz,dude02@jackson-testing.zzz \
--from-literal=passwords=weluvtotest0101,weluvtotest0202
```

### Deployment:

```yaml
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openldap
  namespace: lolz
  labels:
    app.kubernetes.io/name: openldap
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: openldap
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: openldap
    spec:
      containers:
        - name: openldap
          image: docker.io/bitnami/openldap:latest
          imagePullPolicy: "Always"
          env:
            - name: LDAP_ADMIN_USERNAME
              valueFrom:
                secretKeyRef:
                  key: adminusername
                  name: openldap
            - name: LDAP_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  key: adminpassword
                  name: openldap
            - name: LDAP_USERS
              valueFrom:
                secretKeyRef:
                  key: users
                  name: openldap
            - name: LDAP_PASSWORDS
              valueFrom:
                secretKeyRef:
                  key: passwords
                  name: openldap
            - name: LDAP_ROOT
              valueFrom:
                secretKeyRef:
                  key: ldaproot
                  name: openldap
          ports:
            - name: tcp-ldap
              containerPort: 1389
EOF
```

### Service:

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: openldap
  namespace: lolz
  labels:
    app.kubernetes.io/name: openldap
spec:
  type: ClusterIP
  ports:
    - name: tcp-ldap
      port: 1389
      targetPort: tcp-ldap
  selector:
    app.kubernetes.io/name: openldap
EOF
```

### configuration in lolzapp:

```yaml
ldap:
      account: cn
      adminPassword: adminpassword
      adminUser: cn=misteradmindude@jackson-testing.zzz,dc=jackson-testing,dc=zzz
      base: dc=jackson-testing,dc=zzz
      enabled: true
      host: openldap.lolz.svc.cluster.local
      port: "1389"
      ssl: "false"
```

### utilities:

test basic LDAP connectivity from app pod:

```bash
curl -v -u "cn=misteradmindude@jackson-testing.zzz,dc=jackson-testing,dc=zzz":"adminpassword" "ldap://openldap.lolz.svc.cluster.local:1389"
```

good response:

```bash
* Rebuilt URL to: ldap://ldap.ldap.svc.cluster.local:389/
*   Trying 10.0.180.80...
* TCP_NODELAY set
* Connected to ldap.ldap.svc.cluster.local (10.0.180.80) port 389 (#0)
* LDAP local: ldap://ldap.ldap.svc.cluster.local:389/
DN:
	objectClass: top
	objectClass: OpenLDAProotDSE

* Connection #0 to host ldap.ldap.svc.cluster.local left intact
```

search for specific users and retrieve their information:

```bash
curl -v -u "cn=misteradmindude@jackson-testing.zzz,dc=jackson-testing,dc=zzz":"adminpassword" "ldap://openldap.lolz.svc.cluster.local:1389/cn=dude02@jackson-testing.zzz,ou=users,dc=jackson-testing,dc=zzz"
```

test admin authentication directly from rails console:

```ruby
ldap = Net::LDAP.new
ldap.host = "openldap.lolz.svc.cluster.local"
ldap.port = "1389"
ldap.auth "cn=misteradmindude@jackson-testing.zzz,dc=jackson-testing,dc=zzz", "adminpassword"
ldap.bind
```

formatted version using env vars:

```ruby
ldap = Net::LDAP.new
ldap.host = $lolz["ldap"]["host"]
ldap.port = $lolz["ldap"]["port"]
ldap_auth_string = "cn=#{$lolz["ldap"]["admin_user"]},#{$lolz["ldap"]["base"]}, #{$lolz["ldap"]["admin_password"]}"
ldap.auth ldap_auth_string
ldap.bind
```

same but using devise with any email+pass combo:

```bash
Devise::LDAP::Adapter.valid_credentials?("dude01@jackson-testing.zzz", "weluvtotest0101")
=> true
```

get root domain info from openldap server pod:

```ruby
ldapsearch -x -b "dc=jackson-testing,dc=zzz" -H ldap://openldap.lolz.svc.cluster.local:1389
```

[jackson LDAP testing notes](OpenLDAP%20server%20+%20lolz%20LDAP%20integration%202f8afc71603a446ea5416f8f07acead0/jackson%20LDAP%20testing%20notes%204fcff9d1244048e78cb2728cead57bcc.md)

test connection to a secure LDAP server, using insecure flag:

```bash
ldap = Net::LDAP.new(
  host: 'corpadssl.intel.com',
  port: 3269,
  encryption: { method: :simple_tls, verify_mode: OpenSSL::SSL::VERIFY_NONE } # Use VERIFY_NONE for --insecure
)

if ldap.bind
  puts 'LDAP connection successful'
  # Perform LDAP operations here
else
  puts "LDAP connection failed: #{ldap.get_operation_result.message}"
end
```

test admin credentials:

```bash
# LDAP connection configuration
ldap = Net::LDAP.new(
  host: 'corpadssl.intel.com',
  port: 3269,
  encryption: { method: :simple_tls, verify_mode: OpenSSL::SSL::VERIFY_NONE }
)

# LDAP credentials (if required)
ldap.auth('admin_username', 'admin_password')

if ldap.bind
  puts "LDAP auth succeeded! #{ldap.get_operation_result.message}"
else
  puts "LDAP auth failed :( #{ldap.get_operation_result.message}"
end
```