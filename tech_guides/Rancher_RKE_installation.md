# Rancher RKE installation

# Machine requirements


- should be able to communicate with each other (on same network)
- should be able to ssh to each other using internal IP, without password/pemkey
- one host should have large disk capacity and be configured as an NFS

### Enable SSH as root on Ubuntu EC2 Instance

1. login to ubuntu user:
    
    ```
    ssh -i private-key.pem ubuntu@1.2.3.4
    ```
    
2. switch to the root account:
    
    ```
    sudo su -
    ```
    
3. edit `/root/.ssh/authorized_keys` file:
    
    ```bash
    vim /root/.ssh/authorized_keys
    ```
    
4. remove highlighted text:
    
    ```
    no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="
    echo 'Please login as the user "ubuntu" rather than the user "root".';
    echo;sleep 10" ssh-rsa KEY tecadmin.net
    
    ```
    
5. file should look like this:
    
    ```
    ssh-rsa KEY tecadmin.net
    
    ```
    
6. save file, then exit the shell.
7. try to ssh with the root account:
    
    ```
    ssh -i private-key.pem root@1.2.3.4
    ```
    
    you should be able to access.
    

<aside>
⚠️ run same steps on all machines you wish to add as nodes

</aside>

<aside>
⚠️ Alternative method to defining the RSA private key
In the cluster.yaml file you can add the .pem private key you define/download when creating an EC2 instance. Here is how the yaml file looks. Update the ssh_key and ssh_key_path keys. Simply cat the .pem file and add the RSA private key then enter the path to the .pem file.

</aside>

```jsx
nodes:
- address: dud3-rke-01.dud3.net
  port: "22"
  internal_address: 172.31.21.239
  role:
  - controlplane
  - worker
  - etcd
  hostname_override: ""
  user: ubuntu
  docker_socket: /var/run/docker.sock
  ssh_key: |-
    -----BEGIN RSA PRIVATE KEY-----
    -----END RSA PRIVATE KEY-----
  ssh_key_path: /home/Documents/code/aws_eks/rancher_rke
```

### Install docker

[https://ranchermanager.docs.rancher.com/v2.5/getting-started/installation-and-upgrade/installation-requirements/install-docker](https://ranchermanager.docs.rancher.com/v2.5/getting-started/installation-and-upgrade/installation-requirements/install-docker)

```bash
curl https://releases.rancher.com/install-docker/20.10.sh | sh
```

check version after install

```bash
docker version --format '{{.Server.Version}}'
```

add user to docker group

```bash
sudo usermod -aG docker ${USER}
```

restart docker service for changes to take effect

```bash
sudo su -; 
systemctl restart docker
```

### configure SSH

on **server01**, generate SSH key:

```bash
ssh-keygen
```

copy the public key content

```bash
cat ~/.ssh/id_rsa.pub
```

append it to `~/.ssh/authorized_keys` on each machine you want to add as node:

```bash
vim ~/.ssh/authorized_keys
```

<aside>
⚠️ do the same for **server01** as well if you wish to add it as a node.

</aside>

restart SSH daemon, and check status to verify its running:

```bash
systemctl restart ssh.service;
systemctl status ssh.service
```

### Install RKE CLI

grab relevant binary from latest stable release of type `linux-amd64`

[https://github.com/rancher/rke/releases](https://github.com/rancher/rke/releases)

check `$PATH`

```bash
echo $PATH
```

rename to rke, change to executable, move to `$PATH`

```bash
chmod +x rke_linux-amd64
mv rke_linux-amd64 rke
mv rke /usr/local/bin
```

**Install kubectl too:**

```yaml
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
echo 'alias kc="kubectl -n lolz"' >> ~/.bashrc
echo 'alias app="kubectl -n lolz exec -it deploy/app -c lolz-app -- bash -l"' >> ~/.bashrc
echo 'alias app-v="kc get pods -l app=app -o jsonpath='{.items[0].spec.containers[0].image}'; echo"' >> ~/.bashrc
echo 'alias kwatch="watch 'kubectl -n lolz get pods'"' >> ~/.bashrc
```

**and helm:**

```yaml
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Install cluster

create `cluster.yml` dynamically

```bash
rke config
```

go over `cluster.yml` to patch anything you might have missed

```bash
vim cluster.yml
```

install cluster according to the configuration in `cluster.yml` 

```bash
rke up
```

once install is done, the kubeconfig file will be generated in the directory.

### Install NFS server

on the NFS machine with larger disk, install NFS server:

[Create NFS server & configure as NFS cache](https://www.notion.so/Create-NFS-server-configure-as-NFS-cache-2ea06af23b2d47e1be490b8c60da8d09?pvs=21)

### rke config walkthrough

default values are in square brackets.

settings per host:

```bash
[+] SSH Address of host (1) [none]: **172.31.35.172**
[+] SSH Port of host (1) [22]:
[+] SSH Private Key Path of host () [none]:
[-] You have entered empty SSH key path, trying fetch from SSH key parameter
[+] SSH Private Key of host () [none]:
[-] You have entered empty SSH key, defaulting to cluster level SSH key: ~/.ssh/id_rsa
[+] SSH User of host () [ubuntu]: **root**
[+] Is host () a Control Plane host (y/n)? [y]: **y**
[+] Is host () a Worker host (y/n)? [n]: **y**
[+] Is host () an etcd host (y/n)? [n]: **y**
[+] Override Hostname of host () [none]: **server01**
[+] Internal IP of host () [none]:
[+] Docker socket path on host () [/var/run/docker.sock]:
```

global settings:

```bash
[+] Network Plugin Type (flannel, calico, weave, canal, aci) [canal]:
[+] Authentication Strategy [x509]:
[+] Authorization Mode (rbac, none) [rbac]:
[+] Kubernetes Docker image [rancher/hyperkube:v1.24.8-rancher1]:
[+] Cluster domain [cluster.local]:
[+] Service Cluster IP Range [10.43.0.0/16]:
[+] Enable PodSecurityPolicy [n]:
[+] Cluster Network CIDR [10.42.0.0/16]:
[+] Cluster DNS Service IP [10.43.0.10]:
[+] Add addon manifest URLs or YAML files [no]:
```

you can set the version of Kubernetes by using the tags from docker hub:

[https://hub.docker.com/r/rancher/hyperkube/tags](https://hub.docker.com/r/rancher/hyperkube/tags)

Update the `kubernetes` key in the `cluster.yml` or define when running `rke config`

### Set DNS record

create a wildcard DNS record of A type (of the cluster domain mentioned in helm)

then point it to the **public IP** address of **machine1**

### Connect to private registry

for private registry:

<aside>
⚠️ need to enable HTTP in containerD
[https://github.com/containerd/containerd/blob/main/docs/cri/registry.md](https://github.com/containerd/containerd/blob/main/docs/cri/registry.md)

</aside>

### Upgrades

run `rke config --list-version --all` to view all available versions.

Modify your `cluster.yml`  file with the desired version:

```ruby
kubernetes_version: "v1.26.8-rancher1"
```

run `rke up --config cluster.yml` 

# notes

if you get this error during `rke up`

```bash
Failed to fetch cluster certs from nodes, aborting upgrade: Certificate /etc/kubernetes/.tmp/kube-admin.pem is not found
```

run:

```bash
rke util get-state-file
```

rancher uses docker for installation, which is being ran from a docker container.

Then it installs kubernetes v1.24 and containerd runtime. **is there a conflict???**

hyperkube dockerhub (get versions)

`rke config --list-version --all`

[Docker](https://hub.docker.com/r/rancher/hyperkube/tags)