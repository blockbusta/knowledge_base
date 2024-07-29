# install k3s cluster on workstation

<aside>
👨🏻‍🚒 reference: [https://docs.k3s.io/quick-start](https://docs.k3s.io/quick-start)

</aside>

# Pre-requisites

- ubuntu machine
- at least 4 CPU 8GB RAM
- public IP

## Install k3s

1. switch to root:
    
    ```bash
    sudo su
    ```
    
2. update and install packages:
    
    ```bash
    apt-get update -y && apt-get install -y \
    htop curl wget dnsutils vim nload
    ```
    
3. install k3s:
    
    ```bash
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.13+k3s1 sh -
    ```
    
    <aside>
    🔥 choose the relevant k8s version, refer to the name of the official k3s release tags:
    [https://github.com/k3s-io/k3s/releases](https://github.com/k3s-io/k3s/releases)
    in this example we used the `v1.24.13+k3s1` tag:
    [https://github.com/k3s-io/k3s/releases/tag/v1.24.13%2Bk3s1](https://github.com/k3s-io/k3s/releases/tag/v1.24.13%2Bk3s1)
    
    </aside>
    
4. define kubeconfig env var:
    
    ```bash
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    ```
    
5. verify installation:
    
    ```bash
    kubectl get nodes;
    systemctl status k3s | grep Active -A 3;
    k3s --version
    ```
    
6. add aliases:
    
    ```bash
    echo 'alias k="kubectl"' >> ~/.bashrc
    echo 'alias kc="kubectl -n lolz"' >> ~/.bashrc
    echo 'alias kwatch="watch kubectl -n lolz get pods | grep -e app -e kiq"' >> ~/.bashrc
    echo 'alias app="kubectl -n lolz exec -it deploy/app -c lolz-app -- bash -l"' >> ~/.bashrc
    echo 'alias ks="kubectl -n kube-system"' >> ~/.bashrc
    source ~/.bashrc
    ```
    

## install lolz worker

1. install helm
    
    ```bash
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```
    
2. create lolz namespace
    
    ```bash
    kc create ns lolz
    ```
    
3. run helm install as cited here:
[https://github.com/Samba/Brazilero/blob/main/examples/helm_install/workstation-minimal.sh](https://github.com/Samba/Brazilero/blob/main/examples/helm_install/workstation-minimal.sh)
4. add the **internal IP** of the machine here:
    
    ```bash
    --set "networking.istio.externalIp={172.10.20.30}" \
    ```
    
5. set the **public IP** of the machine in the wildcard DNS record
6. grab prometheus password (username is always `lolz`)
    
    ```bash
    PROM_PASS=$(kubectl -n lolz get secret prom-creds -o jsonpath="{.data.lolz_PROMETHEUS_PASS}" | base64 -d)
    echo $PROM_PASS
    ```
    
    check the prometheus virtualservice and access its domain
    
    ```bash
    kc get virtualservices | grep prom
    ```
    
    if you’re able to login, then lolz installed successfully
    

### Create publicly-accessible kubeconfig

1. from VM, print the content of the kubeconfig, and copy:
    
    ```bash
    cat /etc/rancher/k3s/k3s.yaml
    ```
    
2. in your machine, create the new kubeconfig file:
    
    ```bash
    vim my_k3s_cluster.yaml
    ```
    
3. replace the internal kubeapi server with the **IPv4 public DNS**:
    
    ```bash
    server: https://127.0.0.1:6443
    ```
    
    ```bash
    server: https://ec2-9-9-9-9.ap-shamalama-2.compute.amazonaws.com:6443
    ```
    
4. in the VM security group, add an inbound rule for port 6443


## Uninstall k3s

```bash
/usr/local/bin/k3s-uninstall.sh
```