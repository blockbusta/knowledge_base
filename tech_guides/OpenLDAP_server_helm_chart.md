# OpenLDAP server helm chart

## Deploy LDAP server

1. add repo
    
    ```bash
    helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap
    ```
    
2. install
    
    ```bash
    helm install ldap helm-openldap/openldap-stack-ha \
    -n ldap --create-namespace \
    --set global.ldapDomain=jackson.zzz \
    --set global.adminPassword=wow010203 \
    --set global.configPassword=wow010203 \
    --set users=dude01 \
    --set userPasswords=weluvtotest0101 \
    --set persistence.enabled=true \
    --set persistence.size=10Gi \
    --set replicaCount=1 \
    --debug
    ```
    
    <aside>
    👨🏻‍🚒 values file: [https://github.com/jp-gouin/helm-openldap/blob/master/values.yaml](https://github.com/jp-gouin/helm-openldap/blob/master/values.yaml)
    
    </aside>
    
3. add virtualservices
    
    ```bash
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ldap-phpldapadmin
      namespace: lolz
    spec:
      gateways:
        - istio-gw-lolz
      hosts:
        - ldap-ui.aks-rofl15353.cicd.ginger.cn
      http:
        - retries:
            attempts: 5
            perTryTimeout: 172800s
          route:
            - destination:
                host: ldap-phpldapadmin.ldap.svc.cluster.local
          timeout: 864000s
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: ldap-ltb-passwd
      namespace: lolz
    spec:
      gateways:
        - istio-gw-lolz
      hosts:
        - ldap-ltb-passwd.aks-rofl15353.cicd.ginger.cn
      http:
        - retries:
            attempts: 5
            perTryTimeout: 172800s
          route:
            - destination:
                host: ldap-ltb-passwd.ldap.svc.cluster.local
          timeout: 864000s
    ```
    
4. define LDAP in lolz app:
    
    ```bash
    ldap:
          account: cn
          adminPassword: wow010203
          adminUser: cn=admin,dc=jackson,dc=zzz
          base: dc=jackson,dc=zzz
          enabled: true
          host: ldap.ldap.svc.cluster.local
          port: "389"
          ssl: "false"
    ```
    

## Create users

1. get the LDAP UI virtualservice URL
    
    ```bash
    kubectl -n lolz get virtualservices | grep phpldapadmin
    ```
    
2. login to the LDAP UI, using this username, with the password defined in helm install
    
    ```bash
    cn=admin,dc=jackson,dc=zzz
    ```
    
3. expand the domain, click (1) on `ou=users`, and select (2) **Create child entry**:
    
    
4. select “**Generic: Posix Group**”, name it, select users (optional), then hit “**Create Object**”
5. click again on **ou=users** and create another child entry (step 6)
6. now we’ll create the test user that will be used to check login to lolz:
    - select **Generic: User Account**
    - provide **First Name** and **Last Name**, other details will get created automatically.
    - in **Common Name** provide the full email address you wish to use, make sure its under the same domain provided in the helm install. for this example `johnny@jackson.zzz`
    - set **Password**
    - in **GID Number**, select the group created earlier, and finish by clicking “**Create Object**”
    
7. now you can login using that email+password.
