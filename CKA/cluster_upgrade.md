# upgrade cluster
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
> helpful video: https://www.youtube.com/watch?v=NgrNxoAGOEs

- from version `1.29.0` to version `1.30.0`
- using kubeadm
- 2 ubuntu nodes: **controlplane** and **node01**

## add repo & set target version
set the target minor version:
```
KUBERNETES_VERSION="1.30.0"
```
edit sources list:
```bash
vim /etc/apt/sources.list.d/kubernetes.list
```
make sure the target minor version `1.30` is set:
```
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /
```
update and check available versions:
```bash
sudo apt update
```
set the kubeadm version according to available versions:
```
KUBEADM_VERSION=$(sudo apt-cache madison kubeadm | grep $KUBERNETES_VERSION | awk '{ print $3 }')
```
check version:
```
echo $KUBEADM_VERSION
```
# upgrade node
The upgrade procedure on control plane nodes should be executed one node at a time. 

Pick a control plane node that you wish to upgrade first. 

> It must have the `/etc/kubernetes/admin.conf` file.

## upgrade 1st (or only) control plane node

### upgrade kubeadm:
```bash
sudo apt-mark unhold kubeadm && \
sudo apt-get update && \
sudo apt-get install -y kubeadm=$KUBEADM_VERSION && \
sudo apt-mark hold kubeadm
```
Verify upgrade:
```
kubeadm version
```

### check cluster upgrade plan:
```
sudo kubeadm upgrade plan $KUBERNETES_VERSION
```

it'll show what possible upgrades candidates are, and which components should be manually upgraded:
```
...
[upgrade] Fetching available versions to upgrade to
[upgrade/versions] Cluster version: 1.29.0
[upgrade/versions] kubeadm version: v1.30.0
[upgrade/versions] Target version: 1.30.0
[upgrade/versions] Latest version in the v1.29 series: 1.30.0

Components that must be upgraded manually after you have upgraded the control plane with 'kubeadm upgrade apply':
COMPONENT   NODE           CURRENT   TARGET
kubelet     controlplane   v1.29.0   1.30.0
kubelet     node01         v1.29.0   1.30.0
...

You can now apply the upgrade by executing the following command:

        kubeadm upgrade apply 1.30.0
```
As we see, the upgrade plan was checked, and we can go ahead, using the command provided. Just note that kubelet & kubectl require manual upgrade afterwards.

### upgrade cluster:

run:
```
kubeadm upgrade apply $KUBERNETES_VERSION
```
this can take a few minutes. Once the command finishes you should see:
```
[upgrade/successful] SUCCESS! Your cluster was upgraded to "v1.30.0". Enjoy!

[upgrade/kubelet] Now that your control plane is upgraded, please proceed with upgrading your kubelets if you haven't already done so.
```
### upgrade kubelet + kubectl:
```
sudo apt-mark unhold kubelet kubectl && \
sudo apt-get update && sudo apt-get install -y \
kubelet=$KUBEADM_VERSION kubectl=$KUBEADM_VERSION && \
sudo apt-mark hold kubelet kubectl
```
restart the system-daemon and the kubelet service:
```
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
check upgrade:
```
kubectl version
kubelet --version
```
### upgrade CNI provider plugin:
check if your netwrok plugin requires an upgrade too.

in this case, we have **weave** deployed, and it was set to use 1.29, so we'll upgrade it to the corresponding version for 1.30:
```
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.30/net.yaml
```
for this case, there is the env `IPALLOC_RANGE` that we must add to the ds after weave is upgraded:
```
        - name: IPALLOC_RANGE
          value: 10.244.0.0/16
```

## upgrade rest of control plane nodes:
>in this case we have a single control plane node

Do the same as you did for the first control plane node - BUT:
-  use: `sudo kubeadm upgrade node`,

    instead of: `sudo kubeadm upgrade apply`
- calling `kubeadm upgrade plan` & upgrading the CNI provider plugin is no longer needed

## upgrade worker node (node01)
https://v1-30.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/

same as before, but some steps differ so pay attention:

1. set version and repo
2. upgrade kubeadm
3. continue to next step

### get upgrade config from control plane:
```
sudo kubeadm upgrade node
```
### drain worker node (node01)
> reference: https://v1-30.docs.kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/
```bash
kubectl drain --ignore-daemonsets node01
```

4. upgrade kubelet + kubectl

> verify node01 existing workloads have been rescheduled on other available node (controlplane)



uncordon the node:
```
kubectl uncordon node01
```

### verify upgrade
```bash
systemctl status kubelet
journalctl -xeu kubelet
```