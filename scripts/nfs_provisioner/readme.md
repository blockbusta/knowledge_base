# Install NFS Provisioner

### config:

```bash
NFS_SERVER="1.2.3.4"
NFS_PATH="/mnt/bla/nfs-data"
```

### apply:

```yaml
kubectl apply -f manifest.yaml
```

**OPTIONAL:** make storage class default:

```yaml
kubectl patch storageclass nfs-storageclass -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```
