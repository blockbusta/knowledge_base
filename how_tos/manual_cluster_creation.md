# manual cluster creation

## GKE

```bash
PROJECT=development
ZONE=us-central1-a
REGION=us-central1
CLUSTER_NAME=**YOUR_CLUSTER_NAME**
```

```bash
gcloud --project ${PROJECT} container clusters create ${CLUSTER_NAME} --num-nodes 2 --enable-ip-alias --region ${REGION} --machine-type n1-standard-8 --image-type ubuntu --scopes=storage-rw --no-enable-autoupgrade --disk-type=pd-standard --disk-size=200 --node-locations us-central1-a
```


## EKS

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: **your_cluster_name**
  region: us-west-2
nodeGroups:
  - name: ng-1-default # The name of the node pool.
    instanceType: m5.4xlarge
    volumeSize: 100
    minSize: 1 # The minimum amount of nodes to auto scale down to.
    maxSize: 2 # The maximum amount of nodes to auto scale up to.
    desiredCapacity: 2 # The default amount of nodes to have live.
    privateNetworking: true # Required.
    # AmazonLinux2 AMI per region
    # us-west-1 = ami-08ebd7af2ff25f41c
    # us-west-2 = ami-0d12f7a11de8a0809
    # us-east-1 = ami-0e5bb2367e692b807
    # us-east-2 = ami-04d2bccaa067f7296
    iam:
      withAddonPolicies:
        autoScaler: true # Required.
        imageBuilder: true # Required
vpc:
  id: vpc-zzz
  subnets:
    private:
      us-west-2a: { id: subnet-zzz }
      us-west-2b: { id: subnet-zzz }
      us-west-2d: { id: subnet-zzz }
    public:
      us-west-2a: { id: subnet-zzz }
      us-west-2b: { id: subnet-zzz }
      us-west-2d: { id: subnet-zzz }
```


### create cluster

```bash
eksctl create cluster -f cluster.yaml
```

## delete cluster

```bash
# by name
eksctl delete cluster --name=**YOUR_CLUSTER_NAME**

# by cluster yaml
eksctl delete cluster -f cluster.yaml
```

## AKS

```python

```


##  helm install

```bash
helm install  / --timeout 1500s  --wait --set global.domain=**SOME_NAME**.webapp.me --set global.provider=**gke/aks/eks** --**debug**
```

### Removing  (while keeping the cluster alive)

```bash
helm uninstall 
kubectl delete ns 
```

### installing  enterprise (ONLY FOR INTERNAL USE!)

```bash
### adding the repo (done once) ###

helm repo add enterprise  --username **** --password **CHANGE_TO_PASSWORD** https://helm-enterprise.webapp.me:8444

### install ###

helm repo update
helm install  enterprise/
```

### get external IP address of app

```bash
kubectl  get svc | grep ingress | awk "{print $4}"
```

## install workers only cluster

```python
helm install  / --timeout 1500s  --wait --set cert-manager.enabled=true,global.use_ssl=true --set global.provider=eks --set global.domain=i-workers.prod-aks.webapp.me --set app.enabled=false --kubeconfig eks-2ngz.yaml --debug
```