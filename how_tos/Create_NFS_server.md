# Create NFS Server

## Create a New Server

1. Create a machine with sufficient storage for your NFS purposes
   - **AWS:** Instance type `m5a.xlarge` recommended. For storage, use `io1` disk type.

2. Ensure port **2049** is accessible from the cluster to the NFS machine
   - **AWS:** Edit the EC2 security group inbound rules, add port `2049` from source `0.0.0.0/0`

---

## Configure NFS Server (Ubuntu)

1. SSH into the machine and install NFS server:

    ```bash
    sudo apt-get update -y && sudo apt-get install -y nfs-kernel-server
    ```

2. Create export directory:

    ```bash
    sudo mkdir -p /mnt/data
    sudo chown nobody:nogroup /mnt/data
    ```

3. Edit `/etc/exports`:

    ```bash
    sudo vim /etc/exports
    ```

4. Add the export path:

    ```
    /mnt/data  *(rw,async,insecure,no_subtree_check,no_root_squash,anonuid=1001,anongid=1001)
    ```

5. Restart NFS:

    ```bash
    sudo systemctl restart nfs-kernel-server
    ```

---

## Configure NFS Server (CentOS/Amazon Linux)

1. SSH into the machine and install NFS server:

    ```bash
    sudo yum update && sudo yum install -y nfs-utils
    ```

2. Create export directory:

    ```bash
    sudo mkdir -p /var/nfs
    sudo chmod -R 755 /var/nfs
    sudo chown nfsnobody:nfsnobody /var/nfs
    ```

3. Enable and start NFS services:

    ```bash
    sudo systemctl enable --now rpcbind nfs-server nfs-lock nfs-idmap
    ```

4. Edit `/etc/exports`:

    ```bash
    sudo vim /etc/exports
    ```

5. Add the export path:

    ```
    /var/nfs  *(rw,async,insecure,no_subtree_check,no_root_squash,anonuid=1001,anongid=1001)
    ```

6. Restart NFS:

    ```bash
    sudo systemctl restart nfs-server
    ```
