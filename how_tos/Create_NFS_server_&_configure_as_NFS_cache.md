# Create NFS server

## Create a new server

1. Create a machine with sufficient storage for your NFS purposes
**AWS:** for instance type it’s recommended to select **`m5a.xlarge`** EC2 instance,
for storage select `**io1**` disk type and provide the amount of storage needed.
2. Make sure port **2049** is accessible from the cluster to the NFS machine
**AWS:** in the security group created for the EC2 instance, edit inbound rules and add a rule for port `2049`, from source `0.0.0.0/0`

## Configure NFS server (ubuntu)

- SSH into the machine and install the NFS server:
    
    ```bash
    sudo apt-get update -y && sudo apt-get install -y nfs-kernel-server
    ```
    

- create a new directory:
    
    ```bash
    sudo mkdir -p /mnt/**data;**
    sudo chown nobody:nogroup /mnt/data
    ```
    

- Edit `/etc/exports` file:
    
    ```bash
    sudo vim /etc/exports
    ```
    

- Add the new path (the same one you created in step 1):
    
    ```bash
    /mnt/data  *(rw,async,insecure,no_subtree_check,no_root_squash,anonuid=1001,anongid=1001)
    ```
    

- Save the file, and restart nfs
    
    ```bash
    sudo systemctl restart nfs-kernel-server
    ```
    

## Configure NFS server (centos/AmazonLinux)

- SSH into the machine and install the NFS server:

```bash
sudo yum update && sudo yum install -y nfs-utils
```

- create a new directory & change permissions:

```bash
sudo mkdir -p /var/**nfs**
sudo chmod -R 755 /var/nfs
sudo chown nfsnobody:nfsnobody /var/nfs
```

- start NFS services:

```bash
sudo systemctl enable rpcbind
sudo systemctl enable nfs-server
sudo systemctl enable nfs-lock
sudo systemctl enable nfs-idmap
sudo systemctl start rpcbind
sudo systemctl start nfs-server
sudo systemctl start nfs-lock
sudo systemctl start nfs-idmap
```

- Edit `/etc/exports` file:

```bash
sudo vim /etc/exports
```

- Add the new path (the same one you created in step 1):

```bash
/var/nfs  *(rw,async,insecure,no_subtree_check,no_root_squash,anonuid=1001,anongid=1001)
```

- Save the file, and restart NFS server:

```bash
sudo systemctl restart nfs-server
```