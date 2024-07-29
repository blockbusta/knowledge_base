# NFS provisioner

<aside>
💡 [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)

</aside>

add repo:

```yaml
helm repo add nfs-subdir-external-provisioner \
		https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
```

install:

```yaml
helm install nfs-provisioner \
	nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
	-n lolz \
    --set nfs.server=4.242.26.34 \
    --set nfs.path=/mnt/data \
    --set storageClass.name=lolz-nfs \
    --set storageClass.provisionerName=beer.co.uk/nfs \
    --set storageClass.defaultClass=true \
    --set storageClass.reclaimPolicy=Retain \
    --debug
```