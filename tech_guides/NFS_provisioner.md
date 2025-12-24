# NFS Provisioner Installation Guide

This guide covers installing NFS dynamic provisioning for Kubernetes clusters, supporting both vanilla Kubernetes and OpenShift Container Platform (OCP).

---

## Table of Contents

1. [Vanilla Kubernetes Installation](#vanilla-kubernetes-installation)
2. [OpenShift Installation](#openshift-installation)
3. [Verification](#verification)
4. [Troubleshooting](#troubleshooting)

---

## Vanilla Kubernetes Installation

### Step 1: Install NFS Client on Worker Nodes

**Before installing the NFS provisioner, ensure all worker nodes have NFS client utilities installed.** This is the most common cause of mount failures.

Deploy this DaemonSet to install NFS client on all nodes automatically:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nfs-client-installer
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: nfs-client-installer
  template:
    metadata:
      labels:
        app: nfs-client-installer
    spec:
      hostPID: true
      hostNetwork: true
      containers:
      - name: installer
        image: ubuntu:24.04
        securityContext:
          privileged: true
        command:
        - /bin/bash
        - -c
        - |
          nsenter -t 1 -m -u -n -i -- bash -c '
            if command -v apt-get &> /dev/null; then
              apt-get update && apt-get install -y nfs-common
            elif command -v yum &> /dev/null; then
              yum install -y nfs-utils
            elif command -v dnf &> /dev/null; then
              dnf install -y nfs-utils
            fi
          ' || true
          echo "NFS client installation complete"
          sleep infinity
        resources:
          requests:
            cpu: 10m
            memory: 32Mi
      tolerations:
      - operator: Exists
```

```bash
kubectl apply -f nfs-client-installer.yaml

# Wait for all pods to be ready
kubectl rollout status daemonset/nfs-client-installer -n kube-system

# Cleanup after installation (NFS utils persist on host)
kubectl delete daemonset nfs-client-installer -n kube-system
```

### Step 2: Install NFS Server Provisioner

```bash
# Add the Helm repository
helm repo add nfs-ganesha-server-and-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-ganesha-server-and-external-provisioner/

helm repo update

# Install NFS server provisioner
helm install nfs-server nfs-ganesha-server-and-external-provisioner/nfs-server-provisioner \
  --namespace nfs-provisioner \
  --create-namespace \
  --set persistence.enabled=true \
  --set persistence.size=500Gi \
  --set storageClass.name=nfs-rwx \
  --set storageClass.defaultClass=false \
  --set storageClass.allowVolumeExpansion=true \
  --set storageClass.reclaimPolicy=Retain \
  --set storageClass.mountOptions="{vers=3,retrans=2,timeo=30}"
```

### Step 3: Verify Installation

```bash
kubectl get pods -n nfs-provisioner
kubectl get storageclass nfs-rwx
```

---

## OpenShift Installation

For OpenShift, use the **NFS Provisioner Operator** from OperatorHub. The operator handles NFS client installation automatically.

Reference: [NFS Provisioner Operator on OperatorHub](https://operatorhub.io/operator/nfs-provisioner-operator)

### Step 1: Install the Operator

1. Log in to the **OpenShift Web Console**
2. Navigate to **Operators → OperatorHub**
3. Search for **"NFS Provisioner"**
4. Click on **NFS Provisioner Operator**
5. Click **Install**
6. Use default settings and click **Install**
7. Wait for status to show **"Succeeded"**

> **Note:** Use operator version `nfs-provisioner-operator.v0.0.8` for cross-node distribution support.

### Step 2: Create an NFSProvisioner Instance

1. Navigate to **Operators → Installed Operators**
2. Click on **NFS Provisioner Operator**
3. Go to the **NFSProvisioner** tab
4. Click **Create NFSProvisioner**
5. In the spec, configure:

| Field | Value | Description |
|-------|-------|-------------|
| `scForNFS` | `nfs-rwx` | Name of the NFS StorageClass to be created |
| `scForNFSPvc` | `gp3-csi` | Name of your existing block StorageClass |
| `storageSize` | `500Gi` | Size of the NFS server storage |

6. Click **Create**

### Step 3: Verify Installation

1. Navigate to **Storage → StorageClasses**
2. Confirm the new StorageClass (e.g., `nfs-rwx`) appears
3. Check **Workloads → Pods** to verify the NFS provisioner pod is **Running**

---

## Verification

Test NFS provisioning with a DaemonSet to verify RWX works across multiple nodes simultaneously.

### Step 1: Create a Test PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-nfs-rwx
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-rwx
  resources:
    requests:
      storage: 1Gi
```

```bash
kubectl apply -f test-pvc.yaml
kubectl get pvc test-nfs-rwx -w
```

### Step 2: Create a Test DaemonSet

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: test-nfs-rwx
  namespace: default
spec:
  selector:
    matchLabels:
      app: test-nfs-rwx
  template:
    metadata:
      labels:
        app: test-nfs-rwx
    spec:
      containers:
      - name: writer
        image: busybox
        command:
        - /bin/sh
        - -c
        - |
          NODE_NAME=$(cat /etc/hostname)
          echo "Node $NODE_NAME mounted NFS at $(date)" >> /mnt/shared/test-log.txt
          echo "Successfully wrote from $NODE_NAME"
          while true; do
            cat /mnt/shared/test-log.txt
            sleep 30
          done
        volumeMounts:
        - name: nfs-volume
          mountPath: /mnt/shared
      volumes:
      - name: nfs-volume
        persistentVolumeClaim:
          claimName: test-nfs-rwx
      tolerations:
      - operator: Exists
```

```bash
kubectl apply -f test-daemonset.yaml
kubectl rollout status daemonset/test-nfs-rwx
kubectl get pods -l app=test-nfs-rwx -o wide
```

### Step 3: Validate Cross-Node Access

```bash
kubectl logs -l app=test-nfs-rwx --tail=10
```

Expected output shows entries from multiple nodes:
```
Node ip-172-20-10-140 mounted NFS at Tue Dec 24 10:30:01 UTC 2024
Node ip-172-20-10-229 mounted NFS at Tue Dec 24 10:30:02 UTC 2024
Node ip-172-20-10-156 mounted NFS at Tue Dec 24 10:30:03 UTC 2024
```

### Step 4: Cleanup

```bash
kubectl delete daemonset test-nfs-rwx
kubectl delete pvc test-nfs-rwx
```

---

## Troubleshooting

### Mount fails with "bad option" or "mount.nfs not found"

**Cause:** NFS client not installed on worker node (vanilla K8s only).

**Solution:** Deploy the NFS client installer DaemonSet from Step 1 of the vanilla installation.

---

### PVC stuck in Pending

**Cause:** Provisioner not running or StorageClass misconfigured.

**Solution:**
```bash
kubectl get pods -n nfs-provisioner
kubectl logs -n nfs-provisioner -l app=nfs-server-provisioner
```

---

### Permission denied when writing

**Cause:** UID/GID mismatch.

**Solution:** Add to pod spec:
```yaml
securityContext:
  fsGroup: 1000
```
