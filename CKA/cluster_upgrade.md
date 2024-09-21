# upgrade cluster
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

- from version 1.29 to version 1.30
- using kubeadm
- 2 ubuntu nodes: **controlplane** and **node01**

### add repo
**define k8s version**

edit sources list:
```bash
vim /etc/apt/sources.list.d/kubernetes.list
```
make sure the target version is set, i.e `1.30` in our case:
```
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
```
update and check available versions:
```bash
sudo apt update
sudo apt-cache madison kubeadm
```
for example:
```
   kubeadm | 1.30.1-1.1 | https://pkgs.k8s.io/core:/stable:/v1.30/deb  Packages
   kubeadm | 1.30.0-1.1 | https://pkgs.k8s.io/core:/stable:/v1.30/deb  Packages
   kubeadm | 1.29.9-1.1 | https://pkgs.k8s.io/core:/stable:/v1.29/deb  Packages
   kubeadm | 1.29.8-1.1 | https://pkgs.k8s.io/core:/stable:/v1.29/deb  Packages
```
in this case we want version `1.30.0`, so we'll set it from the list:
```
KUBEADM_VERSION="1.30.0-1.1"
```
### upgrade control plane node
The upgrade procedure on control plane nodes should be executed one node at a time. 

Pick a control plane node that you wish to upgrade first. 

It must have the `/etc/kubernetes/admin.conf` file.
```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && sudo apt-get install -y kubeadm=$KUBEADM_VERSION && \
sudo apt-mark hold kubeadm
```

Verify that the download works and has the expected version:
```
kubeadm version
```
Verify the upgrade plan:
```
sudo kubeadm upgrade plan
```

it'll show what possible upgrades candidates are, and which components should be manually upgraded:
```
controlplane ~ ➜  sudo kubeadm upgrade plan
[upgrade/config] Making sure the configuration is correct:
[preflight] Running pre-flight checks.
[upgrade/config] Reading configuration from the cluster...
[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[upgrade] Running cluster health checks
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.29.0
[upgrade/versions] kubeadm version: v1.30.0
I0921 14:43:28.081679   16822 version.go:256] remote version is much newer: v1.31.1; falling back to: stable-1.30
[upgrade/versions] Target version: v1.30.5
[upgrade/versions] Latest version in the v1.29 series: v1.29.9

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE           CURRENT   TARGET
kubelet     controlplane   v1.29.0   v1.29.9
kubelet     node01         v1.29.0   v1.29.9

Upgrade to the latest version in the v1.29 series:

COMPONENT                 NODE           CURRENT    TARGET
kube-apiserver            controlplane   v1.29.0    v1.29.9
kube-controller-manager   controlplane   v1.29.0    v1.29.9
kube-scheduler            controlplane   v1.29.0    v1.29.9
kube-proxy                               1.29.0     v1.29.9
CoreDNS                                  v1.10.1    v1.11.1
etcd                      controlplane   3.5.10-0   3.5.12-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.29.9

_____________________________________________________________________

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE           CURRENT   TARGET
kubelet     controlplane   v1.29.0   v1.30.5
kubelet     node01         v1.29.0   v1.30.5

Upgrade to the latest stable version:

COMPONENT                 NODE           CURRENT    TARGET
kube-apiserver            controlplane   v1.29.0    v1.30.5
kube-controller-manager   controlplane   v1.29.0    v1.30.5
kube-scheduler            controlplane   v1.29.0    v1.30.5
kube-proxy                               1.29.0     v1.30.5
CoreDNS                                  v1.10.1    v1.11.1
etcd                      controlplane   3.5.10-0   3.5.12-0

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply v1.30.5

Note: Before you can perform this upgrade, you have to update kubeadm to v1.30.5.

_____________________________________________________________________


The table below shows the current state of component configs as understood by this version of kubeadm.
Configs that have a "yes" mark in the "MANUAL UPGRADE REQUIRED" column require manual config upgrade or
resetting to kubeadm defaults before a successful upgrade can be performed. The version to manually
upgrade to is denoted in the "PREFERRED VERSION" column.

API GROUP                 CURRENT VERSION   PREFERRED VERSION   MANUAL UPGRADE REQUIRED
kubeproxy.config.k8s.io   v1alpha1          v1alpha1            no
kubelet.config.k8s.io     v1beta1           v1beta1             no
_____________________________________________________________________

```

**upgrade node:**

run:
```
kubeadm upgrade apply 1.30.0
```
this can take a few minutes. Once the command finishes you should see:
```
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.30.0". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```


### drain node01
> reference: https://v1-30.docs.kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
```bash
kubectl drain --ignore-daemonsets node01
```

### reschedule node01 deploys on controlplane
```bash
...
```

### upgrade node01
```bash
...
```

### verify upgrade
```bash
systemctl status kubelet
journalctl -xeu kubelet
```