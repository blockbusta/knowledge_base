# Tokenize kubeconfig

- Create `ssh-permissions.yaml` ****(newer less permissive manifest)

```yaml
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: port-forward-role
  namespace: my-webapp
rules:
- apiGroups: [""]
  resources: ["pods","pods/portforward"]
  verbs: ["get","list","create"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: port-forward-role
  namespace: my-webapp
subjects:
- kind: ServiceAccount
  name: port-forward-role
roleRef:
  kind: Role
  name: port-forward-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: port
  name: port-forward-role
  namespace: my-webapp
```

- Apply it on the cluster:

```ruby
kubectl apply -f ssh-permissions.yml
```

- Verify you receive the following response:

```yaml
role.rbac.authorization.k8s.io/port-forward-role created
rolebinding.rbac.authorization.k8s.io/port-forward-role created
serviceaccount/port-forward-role created
```

- Retrieve the `port-forward-role` token:

```bash
kubectl describe secret $(kubectl get secret | grep port-forward-role-token | awk '{print $1}') | grep token:
```

- Copy the token
- Edit the kubeconfig file in the following sections:

1. set "app" under ****contexts:
**contexts ⇒ context ⇒ user:** `app`
2. Remove existing child objects from "**users**" section, and set it with the following user "app" and token:
**users ⇒ name:** `app`
**users ⇒ user ⇒ token:** `ACTUAL_TOKEN`

the changes should look like this within kubeconfig:

```yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: 
    server: 
  name: 
contexts:
- context:
    cluster: 
    user: **app**
  name: 
current-context: 
kind: Config
preferences: {}
users:
- name: **app**
  user:
    **token: ACTUAL_TOKEN**

```

- Save kubeconfig then check if you can see cluster resources:

```bash
kubectl get pods
```