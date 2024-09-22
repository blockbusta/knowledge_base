# Specs:
- k8s 1.31
- ubuntu nodes (1 master + 2 workers)
# Provision VM’s
## install virtualbox and vagrant
**Virtualbox**
> hypervisor for VM’s, running the VM’s

install virtualbox: [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)

**Vagrant**
> automation tool for provisioning VM’s, relies on hypervisor (Virtualbox)

Install vagrant: [https://developer.hashicorp.com/vagrant/install](https://developer.hashicorp.com/vagrant/install)

then modify Vagrantfile:

```
https://github.com/kodekloudhub/certified-kubernetes-administrator-course/blob/master/kubeadm-clusters/virtualbox/Vagrantfile

$ vim kubeadm-clusters/virtualbox/Vagrantfile
```

key configurations in Vagrantfile:

-   `NUM_MASTER_NODE` = how many master nodes, 1 by default
    
-   `NUM_WORKER_NODE` = how many worker nodes, 2 by default
    
-   `IP_NW` = the network IP range used, 192.168.56. by default
    

check vagrant status:

```
vagrant status
```

provision VM’s: (provisions master node, then the 2 worker nodes)

```
vagrant up
```

SSH into one of the VM’s:

```
vagrant ssh <VM>
```

# Install container runtime

[https://kubernetes.io/docs/setup/production-environment/container-runtimes/](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)

**Pre-requisites:**

-   Linux host
    
-   2GB RAM memory, or more
    
-   2 CPU’s, or more
    

**TIP**: to check what OS is running:

```
cat /etc/os-release
```

Run each step detailed here, on all VM’s:

### **Prepare:**

[https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisite-ipv4-forwarding-optional](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisite-ipv4-forwarding-optional)

```
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

Verify its applied by checking the output equals to 1:

```
sysctl net.ipv4.ip_forward
```

### **Install containerd:**

[https://github.com/containerd/containerd/blob/main/docs/getting-started.md](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)

for ubuntu, we rely on the docker installation process, but without actually installing the docker runtime packages at the end: [https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

configure docker apt repo:

```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

install containerd packages:

```
sudo apt-get install -y containerd.io
```

check installation:

```
systemctl status containerd
```

### **Install cgroup drivers:**

[https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd)

control groups (cgroup) are linux components responsible for limits and constraints of resource usage.

the kubelet and container runtime interface with them in order to enforce requests/limits/etc.

the cgroup driver used in the container runtime, has to match the one in the kubelet.

check if the init system in your VM is systemd or cgroupfs (in our case its systemd)

```
ps -p 1
```

so we’re gonna set it to systemd on containerd:  
[https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd-systemd)

backup existing config:

```
mv /etc/containerd/config.toml /etc/containerd/config_toml_backup
```

verify backup:

```
cat /etc/containerd/config_toml_backup 
```

reate new config file:

```
vim /etc/containerd/config.toml 
```

add the following:

```
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```

restart containerd:

```
sudo systemctl restart containerd
```

check status:

```
sudo systemctl status containerd
```

# Install k8s tools

[https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-0](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-0)

You will install these packages on all of your machines:

-   kubeadm: the command to bootstrap the cluster.
    
-   kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
    
-   kubectl: the command line util to talk to your cluster.
    

**Run the following on all nodes:**

Update the apt package index and install packages needed to use the Kubernetes apt repository:

```
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

set the k8s version:
```
KUBERNETES_VERSION="1.31"
```

Download the public signing key for the Kubernetes package repos:
> If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command:

> `sudo mkdir -p -m 755 /etc/apt/keyrings`
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Add the appropriate Kubernetes apt repo:
> This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /' |\
sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Update index and retrieve version list:
```
sudo apt-get update;
sudo apt-cache madison kubeadm | grep $KUBERNETES_VERSION
```
select the desired patch-level version, and set in var:
```
KUBEADM_VERSION="1.31.0-1-1"
```
install kubelet, kubeadm and kubectl, and pin their version (prevents auto-updates):
```
sudo apt-get update && sudo apt-get install -y \
kubelet=$KUBEADM_VERSION \
kubeadm=$KUBEADM_VERSION \
kubectl=$KUBEADM_VERSION && \
sudo apt-mark hold kubelet kubeadm kubectl
```
(**Optional**) Enable the kubelet service before running kubeadm:
```
sudo systemctl enable --now kubelet
```
verify install:

```
kubelet --version
kubectl version
kubeadm version
```

# Create the cluster

note that the **kubelet** has to match the init system used in the **container runtime**.  
from k8s v1.22 onward, the default is **systemd**, so in this case there is no need to explicitly configure that.

for older k8s version, you have to set it explicitly:  
[https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver)

[https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#initializing-your-control-plane-node)

**run these ONLY on master node VM:**

**Initiate the ctrl plane**

to check api-server-advertise-address, run:

```
ip add
```

most of the time you’ll need the eth0 device:

```
ip add | grep eth0
```

grab it from the response:

```
...
inet 192.168.56.2/24 brd 192.168.56.255 scope link
...
```

then run to init:

```
kubeadm init \
--pod-network-cidr=10.244.0.0/16 \
--apiserver-advertise-address=192.168.56.2
```

optional: add the hostname of the ctrl plane node as an extra SAN (Subject Alternative Names)

```
--apiserver-cert-extra-sans=controlplane
```

Once complete, you will see several steps and commands in the output, save it aside (IMPORTANT!)

run the 1st step listed, to copy the kubeconfig file, should look like:

```
mkdir ...
sudo cp ...
sudo chown ...
```

check there is connectivity to the cluster:

```
kubectl cluster-info
kubectl get pods
```

**Install network plugin**

[https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)

out of all options, we’ll install Weave:

[https://github.com/rajch/weave#using-weave-on-kubernetes](https://github.com/rajch/weave#using-weave-on-kubernetes)

```
kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.31/net.yaml
```

change the k8s version number accordingly.

check the deployment status:

```
kubectl get pods -A
```

now we need to set the same IP CIDR as we used to init the cluster, in weave settings as well, using the IPALLOC_RANGE env var.

[https://github.com/weaveworks/weave/blob/master/site/kubernetes/kube-addon.md#manually-editing-the-yaml-file](https://github.com/weaveworks/weave/blob/master/site/kubernetes/kube-addon.md#manually-editing-the-yaml-file)

the range is already set in the `kube-apiserver` command flag, i.e
```
$ ps -auxww | grep "service-cluster-ip-range"

--service-cluster-ip-range=10.96.0.0/12
```

we’ll modify it in the weave daemonset:

```
kubectl -n kube-system edit ds weave-net
```

and we’ll add that env to the container:

```
      containers:
        - name: weave
          env:
            - name: IPALLOC_RANGE
              value: 10.244.0.0/16 
```

wait for new pods to start.

**Join worker nodes to the cluster**

from the output of kubeadm init, we’ll run the kubeadm join command on each worker node:

```
kubeadm join ...
```

now back to master node, we can check the new worker nodes joined succesffully:

```
kubectl get nodes -o wide
```

test cluster by running nginx:

```
kubectl run nginx --image=nginx
```

and see that the pod is running:

```
kubectl get pods
```
