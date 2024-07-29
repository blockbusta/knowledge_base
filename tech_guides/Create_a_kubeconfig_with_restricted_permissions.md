# Create a kubeconfig with restricted permissions

<aside>
💡 **source:** [https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#bound-service-account-token-volume)

</aside>

since k8s 1.22, each pod gets a projected volume assigned to it automatically:

```bash
volumes:
  - name: **kube-api-access-ztjdx**
    projected:
      defaultMode: 420
      sources:
      - serviceAccountToken:
          expirationSeconds: 3607
          path: token
      - configMap:
          items:
          - key: ca.crt
            path: ca.crt
          name: kube-root-ca.crt
      - downwardAPI:
          items:
          - fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
            path: namespace
```

which is mounted on each container (even initContainers)

```bash
volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-ztjdx
      readOnly: true
```

this path holds:

```bash
bash-4.2$ pwd

/var/run/secrets/kubernetes.io/serviceaccount
```

```bash
bash-4.2$ ls -lah

lrwxrwxrwx 1 root postgres   13 Feb  7 13:15 ca.crt -> ..data/ca.crt
lrwxrwxrwx 1 root postgres   16 Feb  7 13:15 namespace -> ..data/namespace
lrwxrwxrwx 1 root postgres   12 Feb  7 13:15 token -> ..data/token
```