# CoreDNS

# Intro

the DNS server used in k8s clusters.

It’s the standard used across managed k8s and rancher (only GKE still uses kube-dns, the legacy DNS server)

its configurations are maintained in a `Corefile` which persists in a configmap.

[https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/)

CoreDNS configuration is comprised of different plugins, all built in.

[https://coredns.io/manual/configuration](https://coredns.io/manual/configuration)

# Changing `cluster.local` cluster domain

### Pre-requisites

Patch lolzapp & lolzinfra

```bash
kubectl patch -n lolz lolzapp lolz-app -p '{"spec": {"clusterInternalDomain": "wow.test"}}' --type=merge
kubectl patch -n lolz lolzinfra lolz-infra -p '{"spec": {"clusterInternalDomain": "wow.test"}}' --type=merge
```

Patch Istio Operator (if using istio ingress)

```bash
kubectl -n lolz patch istiooperator lolz-istio --type merge --patch '{
  "spec": {
    "components": {
      "pilot": {
        "k8s": {
          "overlays": [
            {
              "kind": "Deployment",
              "name": "istiod",
              "patches": [
                {
                  "path": "spec.template.spec.containers[0].args[4]",
                  "value": "wow.test"
                }
              ]
            }
          ]
        }
      }
    }
  }
}' 
```

changes will be visible in both istio-operator and istiod deployment

# EKS

in EKS, coredns is less restrictive, and as long as you have cluster admin permissions you can configure the Corefile directly.

1. **Edit the ConfigMap**:
    
    ```yaml
    kubectl edit configmap coredns -n kube-system
    ```
    
2. **Modify the Corefile**: 
In the ConfigMap, you'll find a key named **`Corefile`**. This is the CoreDNS configuration.
    
    Insert the `rewrite…` line between the `health` and `kubernetes…` lines,
    Then modify this line to change the cluster domain from `cluster.local` to `wow.test`
    
    For example:
    
    ```
    ...
        health
        rewrite name substring svc.**wow.test** svc.**cluster.local**
        kubernetes cluster.local in-addr.arpa ip6.arpa {
    ...
    ```
    
    exit and save the changes.
    
3. **Apply the Changes**: After editing the ConfigMap, you need to apply the changes to the CoreDNS pods.
    
    ```bash
    kubectl rollout restart deployment coredns -n kube-system
    ```
    

# AKS

In AKS, the coredns is managed by Azure, so you are expected to make any changes using either a `*.server` or `*.override` files, that either creates new server blocks or appends new configuration to existing sections of the Corefile.

Official AKS docs on coredns configuration:

[https://learn.microsoft.com/en-us/azure/aks/coredns-custom#rewrite-dns](https://learn.microsoft.com/en-us/azure/aks/coredns-custom#rewrite-dns)

note that these docs might be obsolete, as theres an open issue about the inability to change the configuration:

[https://github.com/MicrosoftDocs/azure-docs/issues/109609](https://github.com/MicrosoftDocs/azure-docs/issues/109609)

# GKE

they still use the legacy kube-dns component