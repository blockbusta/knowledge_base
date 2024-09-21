# upgrade from 1.29 to 1.30 using kubeadm on ubuntu nodes
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

[add repo](#add-repo)

### add repo
```bash
sudo apt update
sudo apt-cache madison kubeadm
```

### define k8s version
check that sdfsdf
sdfsdf
sdfsdf

### For the first control plane node
```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm='1.30.0-*' && \
sudo apt-mark hold kubeadm
```

