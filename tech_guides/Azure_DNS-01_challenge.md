# Azure DNS-01 challenge

[lolz_deployment_examples/worker_installs at main · dud3/lolz_deployment_examples](https://github.com/dud3/lolz_deployment_examples/tree/main/worker_installs)

## Azure DNS using Service Principles

This guild will configured a wildcard TLS certificate when using Azure DNS using letsEncrypt.


### Useful Documents

Document I followed to create the guide:
[https://cert-manager.io/docs/configuration/acme/dns01/azuredns/#service-principal](https://cert-manager.io/docs/configuration/acme/dns01/azuredns/#service-principal)

<aside>
⚠️ There are several methods you can use to “challenge” your DNS entries. These instructions are not using the most current method, which requires using **Azure workload identity.** Workload identify requires preview features.

</aside>

1. You need to create a resource group with a new DNS zone. You can create this using the CLI or the GUI.


1. How to quickly create a dns zone using the GUI

Go into your resource group and select create new DNS Zone


1. Give your zone a name this is the subdomain for lolz. For example ‘app.cert-manager.dud3.net’ is cert-manager.dud3.net.


1. Now that you have your dns zone we need to create a wildcard dns record for the zone. Go into the zone under your resource group and add a new record set. Your name will be ‘*.’ because the entry is a wildcard record. The values needs to be the LB address of either Istio or your ingress controller (nginx for example).


1. Next you need to install cert-manager, this can be done using helm.

```elixir
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade -n cert-manager cert-manager jetstack/cert-manager \
    --install \
    --create-namespace \
    --wait \
    --namespace cert-manager \
    --set installCRDs=true
```

1. Once cert-manager is running you will now need access to Azure using the CLI. We need to create a service principle in Azure that has permissions to the DNS domain we just created.

If you need directions on getting the azure cli working. Here are some docs you could provide: [https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/](https://cert-manager.io/docs/tutorials/getting-started-aks-letsencrypt/)

```elixir
az login
```

1. You will need the name of the resource group you created, the DNS zone and to give your new service principle account a name.

create-sp.sh

```elixir
# Choose a name for the service principal that contacts azure DNS to present
# the challenge.
AZURE_CERT_MANAGER_NEW_SP_NAME=service_principle_cert_manager
# This is the name of the resource group that you have your dns zone in.
AZURE_DNS_ZONE_RESOURCE_GROUP=cert-manager
# The DNS zone name. It should be something like domain.com or sub.domain.com.
AZURE_DNS_ZONE=cert-manager.dud3.net

DNS_SP=$(az ad sp create-for-rbac --name $AZURE_CERT_MANAGER_NEW_SP_NAME --output json)
AZURE_CERT_MANAGER_SP_APP_ID=$(echo $DNS_SP | jq -r '.appId')
AZURE_CERT_MANAGER_SP_PASSWORD=$(echo $DNS_SP | jq -r '.password')
AZURE_TENANT_ID=$(echo $DNS_SP | jq -r '.tenant')
AZURE_SUBSCRIPTION_ID=$(az account show --output json | jq -r '.id')
```

1. You need to lower the permissions to the user:

```elixir
az role assignment delete --assignee $AZURE_CERT_MANAGER_SP_APP_ID --role Contributor
```

1. Give the user access to the DNS Zone:

```elixir
DNS_ID=$(az network dns zone show --name $AZURE_DNS_ZONE --resource-group $AZURE_DNS_ZONE_RESOURCE_GROUP --query "id" --output tsv)
az role assignment create --assignee $AZURE_CERT_MANAGER_SP_APP_ID --role "DNS Zone Contributor" --scope $DNS_ID
```

1. Check Permissions. As the result of the following command, we would like to see just one object in the permissions array with "DNS Zone Contributor" role.

```elixir
az role assignment list --all --assignee $AZURE_CERT_MANAGER_SP_APP_ID
```

1. Create the secret on the Kubernetes Custer:

```elixir
kubectl -n cert-manager create secret generic azuredns-config --from-literal=client-secret=$AZURE_CERT_MANAGER_SP_PASSWORD
```

1. Get the variables for configuring the issuer.

```elixir
echo "AZURE_CERT_MANAGER_SP_APP_ID: $AZURE_CERT_MANAGER_SP_APP_ID"
echo "AZURE_CERT_MANAGER_SP_PASSWORD: $AZURE_CERT_MANAGER_SP_PASSWORD"
echo "AZURE_SUBSCRIPTION_ID: $AZURE_SUBSCRIPTION_ID"
echo "AZURE_TENANT_ID: $AZURE_TENANT_ID"
echo "AZURE_DNS_ZONE: $AZURE_DNS_ZONE"
echo "AZURE_DNS_ZONE_RESOURCE_GROUP: $AZURE_DNS_ZONE_RESOURCE_GROUP"
```

1. You need to create a cluster issuer now. Update the variables with your information which was echo’d to the shell.

```elixir
kubectly apply -f cluster-issuer.yaml
```

cluster-issuer.yaml

```elixir
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: azure-cluster-issuer
spec:
  acme:
    privateKeySecretRef:
      name: letsencrypt-prod
    server: https://acme-v02.api.letsencrypt.org/directory
    email: <your-email-address> #Update with your email address
    solvers:
    - dns01:
        azureDNS:
          clientID: AZURE_CERT_MANAGER_SP_APP_ID
          clientSecretSecretRef:
          # The following is the secret we created in Kubernetes. Issuer will use this to present challenge to Azure DNS.
            name: azuredns-config
            key: client-secret
          subscriptionID: AZURE_SUBSCRIPTION_ID
          tenantID: AZURE_TENANT_ID
          resourceGroupName: AZURE_DNS_ZONE_RESOURCE_GROUP
          hostedZoneName: AZURE_DNS_ZONE
          # Azure Cloud Environment, default to AzurePublicCloud
          environment: AzurePublicCloud
```

You can verify the cluster issuer is ready to accept certificates

```elixir
k get clusterissuers.cert-manager.io
NAME                   READY   AGE
azure-cluster-issuer   True    68m
```

1. You now need to create the certificate for cert-manager/letsencrpt to provide.

certificate.yaml

```elixir
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: lolz-wildcard
  namespace: lolz
  annotations:
    cert-manager.io/issue-temporary-certificate: "true"
spec:
  secretName: lolz-domain-tls #This is the TLS secret which will be created. Reference this in the helm install
  renewBefore: 240h
  dnsNames:
  - '*.cert-manager.dud3.net' #Update this values to match your wildcard dns entry
  issuerRef:
    name: azure-cluster-issuer
    kind: ClusterIssuer
```

In the values file you reference the secretName above as show below:

lolz-values.yaml

```elixir
clusterDomain: aws.dud3.net
networking:
  https:
    certSecret: lolz-domain-tls
    enabled: true
```

### Troubleshooting:

Perform the following if your certificate isn’t working properly.

Cert-Manager troubleshooting site.

[https://cert-manager.io/docs/troubleshooting/acme/](https://cert-manager.io/docs/troubleshooting/acme/)

This will show the order for the certificate

```elixir
kc get orders
```

This will show if there is any issues challenging the DNS server

```elixir
kc get challenges
```

Do a describe on the orders and challenges to get additional details.