# PVC migration

### Install

download for linux:

```bash
wget https://github.com/utkuozdemir/pv-migrate/releases/download/v1.7.1/pv-migrate_v1.7.1_linux_x86_64.tar.gz
```

download for macos:

```bash
wget https://github.com/utkuozdemir/pv-migrate/releases/download/v1.7.1/pv-migrate_v1.7.1_darwin_x86_64.tar.gz
```

install:

```bash
tar -xvzf pv-migrate_v1.7.1_*.tar.gz;
mv pv-migrate /usr/local/bin;
pv-migrate --help
```

### **Migration methods**

the tool will attempt one of these methods, according to the conditions faced:

- **`lbsvc`:** Load Balancer Service, this will run rsync+ssh over a Kubernetes Service type *LoadBalancer*. This is the method you want to use if you're migrating PVC from **different** **Kubernetes clusters**.
- **`mnt2`:** Mounts both PVCs in a single pod and runs a regular rsync. This is only usable if source and destination PVCs are in the **same namespace**.
- **`svc`:** Service, Runs rsync+ssh in a Kubernetes Service (ClusteRIP). Only applicable when the source and destination PVCs are in the **same Kubernetes cluster**.

### Migration command

**example:**

```bash
pv-migrate migrate \
--source-namespace lolz \
--dest-namespace lolz \
--ignore-mounted \
source-pvc destination-pvc
```

the tool copies the files from **source-pvc**, appending them if they don’t exist in **destination-pvc**, while keeping existing files intact.

```bash
pv-migrate migrate \
--source-kubeconfig /home/.kube/source-cluster \
--source-namespace lolz \
--dest-kubeconfig /home/.kube/target-cluster \
--dest-namespace lolz \
--ignore-mounted --log-level debug  \
ox4pkdzhtzeqlxb4je7c-new-pvc ox4pkdzhtzeqlxb4je7c-new-pvc
```

this copies from one cluster to the other

**check for additional options:**

```bash
pv-migrate migrate --help
```