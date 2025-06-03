## Deploying Kubernetes Dashboard via Helm

These instructions outline the steps to deploy a Kubernetes Dashboard using Helm.

**Prerequisites:**

*   Helm installed and configured.
*   kubectl installed and configured to access your Kubernetes cluster.

**Steps:**

1.  **Add Kubernetes Dashboard Helm Repository:**

    ```bash
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    helm repo update # Update repositories to ensure you have the latest chart versions
    ```

2.  **Deploy Kubernetes Dashboard using Helm:**

    ```bash
    helm upgrade --install \
    kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
    --create-namespace --namespace kubernetes-dashboard --debug
    ```
    **Note:** This command deploys the dashboard to the `kubernetes-dashboard` namespace.

3.  **Create an Admin Service Account:**

    Apply the following YAML configuration to create a `ServiceAccount` with cluster-admin privileges:

    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: admin-user
      namespace: kubernetes-dashboard
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
      annotations:
        kubernetes.io/service-account.name: "admin-user"
    type: kubernetes.io/service-account-token
    ```

    Save the above YAML content to a file (e.g., `admin-user.yaml`) and apply it:

    ```bash
    kubectl apply -f admin-user.yaml
    ```

4.  **Retrieve Authentication Token:**

    After applying the YAML, retrieve the token for the `admin-user` ServiceAccount:

    ```bash
    kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath="{.data.token}" | base64 -d
    ```

    **Important:** This token is used to log in to the Kubernetes Dashboard.

5.  **Access the Kubernetes Dashboard:**

    Port Forward (Development/Testing):
   
    ```bash
    nohup kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &
    ```

    Access the dashboard at https://localhost:8443/.

    To stop port forwarding, find the process ID:
    ```bash
    lsof -i :8443
    ```
    
    And kill it:
    ```bash
    kill -9 <PID>
    ```

**Notes:**

*   The `kubernetes-dashboard-kong-proxy` may have a different name, be sure to `kubectl get services -n kubernetes-dashboard` to get the correct service to port forward.
*   This setup uses a `ClusterRoleBinding` to grant cluster-admin privileges to the `admin-user` ServiceAccount.  **This is for demonstration purposes only and is not recommended for production environments.**  In a production environment, you should create more restrictive roles and bindings based on the actual needs of the user accessing the dashboard.
* The base for these instructions can be found here: [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
