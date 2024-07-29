# Use AWS EFS as an NFS cache

# Why?

EFS is a managed, scalable, elastic, multi-zone file system.

[https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html)

**Instead** of using **EBS** directly (by leveraging the gp2 storage class), which has availability zone limitations, and can’t be mounted to multiple instances at once.

And **instead** of creating an **NFS** server (which requires installation and maintenance) on an **EC2** instance (which is $$$).

We integrate directly to EFS which solves all of these issues.

# Create EFS

In your AWS Console, go to EFS and create a new file system

- **Name**: optional
- **VPC**: choose the VPC your EKS cluster is in
- **Availability**: Regional

in the newly created EFS, go to **Network** → **Manage** and add mount points for all needed availability zones your cluster nodes can be spawned on.

- **Subnet ID:** choose the subnet needed
- **IP address:** leave empty so it’ll be set automatically
- **Security groups:** choose the same security group of your cluster nodes

# Install EFS CSI driver in cluster

**deploy the EFS driver pods:**
(will get deployed as daemonset in `kube-system` namespace)

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.0"
```

check pod created for each node:

```bash
**kubectl -n kube-system get pods | grep efs**

efs-csi-node-b2psf   3/3   Running   0   100m
efs-csi-node-dzbg7   3/3   Running   0   100m
efs-csi-node-gvwbm   3/3   Running   0   100m
efs-csi-node-sskpm   3/3   Running   0   100m
```

**create the StorageClass and PVC:**

replace `$AWS_EFS_FILE_SYSTEM_ID` with your EFS file system ID (grab from file system page)
and save this YAML:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
  namespace: my-webapp
provisioner: efs.csi.aws.com

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pvc
  namespace: my-webapp
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: **$AWS_EFS_FILE_SYSTEM_ID**

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-storage-claim
  namespace: my-webapp
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

and apply:

```bash
alias kc="kubectl "
kc apply -f efs-sc-pvc.yaml
```

**check objects created:**

SC:

```elm
**kc get sc | grep efs**

NAME    PROVISIONER      RECLAIMPOLICY  VOLUMEBINDINGMODE  ALLOWVOLUMEEXPANSION  AGE
efs-sc  efs.csi.aws.com  Delete         Immediate          false                 91m
```

PVC:

```elm
**kc get pvc | grep efs**

NAME               STATUS VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
efs-storage-claim  Bound  efs-pvc 5Gi       RWX           efs-sc        88m
```

PV:

```elm
**kc get pv | grep efs**

NAME     CAPACITY  ACCESS MODES  RECLAIM POLICY  STATUS  CLAIM                    STORAGECLASS  AGE
efs-pvc  5Gi       RWX           Retain          Bound   /efs-storage-claim  efs-sc        90m
```

# Add the EFS PVC as an NFS cache

follow this guide and add the EFS PVC as NFS cache disk:

[https://app.webapp.me/docs/guides/nfs-cache.html](https://app.webapp.me/docs/guides/nfs-cache.html)

choose PVC and provide this `efs-storage-claim` as claim name.

all done! you can test caching a dataset to make sure theres no connectivity issues.