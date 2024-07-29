# OCP ingress sharding

routing traffic for a separate domain

```yaml
lolz.ai.vwgroup.com
```

to their OpenShift cluster

```yaml
ocp.dev.datalab.vwgroup.com
```

without creating a new load balancer.

This can be a bit tricky, but it's not impossible. Here's a high-level approach:

1. **DNS Configuration:** we’ll need to configure your DNS entries for the new domain (`*.lolz.ai.vwgroup.com`) to point to the existing load balancer's public IP address.
This will direct traffic intended for your application to the OpenShift cluster.
2. **Additional Router Sharding:** Instead of creating a new ingress controller, you can use router sharding, a feature of OpenShift Router that lets you shard (split) traffic based on the route's labels and the ingress controller's namespace selector. You can set up a new shard for your application's routes, and configure it to use the new wildcard domain and certificate. This should be done on the same ingress controller that's already deployed.

default ingress controller:

<aside>
👉🏻 while you are obliged to use an inclusive approach in the `routeSelector`, you can specify multiple labels in it.

</aside>

```yaml
oc edit -n openshift-ingress-operator ingresscontroller default
```

```yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  domain: ocp.company.com
  defaultCertificate:
    name: ocp-certificate
  routeAdmission:
    namespaceOwnership: InterNamespaceAllowed
  routeSelector:
    matchExpressions:
      - key: testing
        operator: NotIn
        values:
          - zone
  replicas: 2
```

second ingress controller:

```yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: secondary-shard-op3nsh1ft
  namespace: openshift-ingress-operator
spec:
  domain: op3nshift.gcpops.beer.co.uk
  defaultCertificate:
    name: op3nsh1ft-certificate
  endpointPublishingStrategy:
    type: HostNetwork
  routeAdmission:
    namespaceOwnership: InterNamespaceAllowed
  routeSelector:
    matchExpressions:
      - key: testing
        operator: In
        values:
          - zone
```

In the above example:

the **`default`** ingress controller handles routes with the label **`ingress: ocp`** 

the **`secondary-shard`** handles routes with the label `**app: lolz**`