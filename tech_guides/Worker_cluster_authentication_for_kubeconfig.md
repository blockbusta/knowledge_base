# Worker cluster authentication for kubeconfig

1. Create `permissions.yaml` manifest:
    
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: lolz-admin
    rules:
      - verbs:
          - '*'
        apiGroups:
          - '*'
        resources:
          - '*'
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: lolz-admin
    subjects:
      - kind: ServiceAccount
        name: lolz-admin
        namespace: default
    roleRef:
      kind: ClusterRole
      name: lolz-admin
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: lolz-admin
      namespace: default
    secrets:
      - name: lolz-admin
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: lolz-admin
      namespace: default
      annotations:
        kubernetes.io/service-account.name: lolz-admin
    type: kubernetes.io/service-account-token
    ```
    
    then apply it:
    
    ```bash
    kubectl apply -f permissions.yaml
    ```
    
2. define user and token in kubeconfig:
    
    ```bash
    TOKEN=$(kubectl describe secret lolz-admin | grep token: | awk '{print $2}')
    CURRENT_CONTEXT=$(kubectl config current-context)
    kubectl config set-credentials lolz-admin --token $TOKEN
    kubectl config set contexts.${CURRENT_CONTEXT}.user lolz-admin
    ```
    

1. test the kubeconfig for output:
    
    ```bash
    kubectl -n lolz get pods
    ```
    

## **example**

**how the applied changes should look in kubeconfig file:**

1. context set to use the service account:
    
    ```bash
    ....
    contexts:
    - context:
        cluster: my-cluster
        user: lolz-admin
      name: my-cluster-context
    current-context: my-cluster-context
    ....
    ```
    
2. service account set with its token:
    
    ```bash
    ....
    users:
    - name: lolz-admin
      user:
        token: $SERVICE_ACCOUNT_TOKEN
    ....
    ```
    

**to validate service account and token exist:**

```bash
kubectl describe serviceaccount lolz-admin
kubectl describe secret lolz-admin
```