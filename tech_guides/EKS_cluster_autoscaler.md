# EKS cluster autoscaler

## Install

1. apply manifests:
    
    ```bash
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
    ```
    
2. add eviction annotation:
    
    ```yaml
    kubectl -n kube-system annotate \
    deployment.apps/cluster-autoscaler \
    cluster-autoscaler.kubernetes.io/safe-to-evict="false"
    ```
    
3. check the k8s cluster version:
    
    ```bash
    kubectl version --short  | grep Server
    ```
    
4. find the corresponding major version release:
    
    [https://github.com/kubernetes/autoscaler/releases](https://github.com/kubernetes/autoscaler/releases)
    
    Check image section and copy the 1st path, for example, when searching 1.23:
    
    
    ```ruby
    k8s.gcr.io/autoscaling/cluster-autoscaler:v1.23.0
    ```
    
    version 1.25 latest:
    
    ```bash
    registry.k8s.io/autoscaling/cluster-autoscaler:v1.25.3
    ```
    
5. edit the autoscaler deployment:
    
    ```bash
    kubectl -n kube-system edit deploy cluster-autoscaler
    ```
    
    - go to command arguments, replace with your cluster name:
        
        ```bash
        ....k8s.io/cluster-autoscaler/**<YOUR_CLUSTER_NAME>**
        ```
        
    - add the following arguments to the command:
        
        ```bash
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        ```
        
    - change the image to the version copied earlier, then save and exit.

## Debug

display auto-scaler logs:

```bash
kubectl -n kube-system logs -f deploy/cluster-autoscaler
```

show all nodegroups discovered by autoscaler:

```bash
kubectl -n kube-system edit cm cluster-autoscaler-status
```

<aside>
⚠️ *if it doesn't exist, or you do not see all nodegroups - then something isnt working*

</aside>

## `eksctl` reference

to make sure auto scaler will work with your nodegroup, verify these in your cluster manifest:

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
nodeGroups:
  - name: cpu-pool
    ...
    iam:
      withAddonPolicies: 
        autoScaler: true
    tags:
      k8s.io/cluster-autoscaler/enabled: 'true'
```