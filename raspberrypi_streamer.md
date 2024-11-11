# Setup Raspberrypi as media server

## Mount USB HDD

To detect and mount a USB hard drive (HDD) to `/mnt/zata` on your Raspberry Pi, follow these steps:

### **Step 1: Insert the USB HDD**
- Plug in your USB HDD into one of the Raspberry Pi’s USB ports.

### **Step 2: List the Available Drives**
- Open a terminal on your Raspberry Pi and use the following command to list all available drives:
  ```bash
  sudo lsblk
  ```
  This will show you a list of storage devices attached to the system. You should see something like this:

  ```bash
  NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
  sda      8:0    0  500G  0 disk
  └─sda1   8:1    0  500G  0 part
  sdb      8:16   0  1.5T  0 disk
  └─sdb1   8:17   0  1.5T  0 part
  ```
  Here, `sda` or `sdb` represents the USB drive. `sda1` or `sdb1` would be the partition you want to mount.

### **Step 3: Find the Filesystem Type**
- Once you've identified the correct device (e.g., `/dev/sda1`), you need to find the filesystem type of the USB HDD to mount it properly. Run:
  ```bash
  sudo blkid /dev/sda1
  ```
  This command will return details about the filesystem, such as:
  ```bash
  /dev/sda1: LABEL="MyDrive" UUID="1234-5678" TYPE="ext4"
  ```

  The **TYPE** will indicate the filesystem type (`ext4`, `ntfs`, `vfat`, etc.).

### **Step 4: Create the Mount Point**
- Now create the mount point (if it doesn't already exist):
  ```bash
  sudo mkdir -p /mnt/zata
  ```

### **Step 5: Mount the USB HDD**
- Mount the USB HDD using the appropriate filesystem type. For example, if the partition is `ext4`:
  ```bash
  sudo mount -t ext4 /dev/sda1 /mnt/zata
  ```
  Or if the filesystem is `ntfs`:
  ```bash
  sudo mount -t ntfs-3g /dev/sda1 /mnt/zata
  ```

- If everything is set up correctly, the drive should now be mounted at `/mnt/zata`.

### **Step 6: Verify the Mount**
- Check that the drive is mounted by running:
  ```bash
  df -h
  ```
  You should see `/mnt/zata` listed as a mounted filesystem with the appropriate size and usage.

### **Step 7: Automate Mounting at Boot (Optional)**
If you want the USB HDD to mount automatically on boot, you can add an entry to `/etc/fstab`.

1. Open `/etc/fstab` with a text editor:
   ```bash
   sudo vim /etc/fstab
   ```

2. Add a new line for your USB HDD (replace `/dev/sda1` and `ext4` with the correct device and filesystem type):
   ```bash
   /dev/sda1  /mnt/zata  ext4  defaults  0  2
   ```

3. Save the file and exit (`CTRL+X`, then `Y` and `Enter`).

4. To test the fstab entry, unmount and mount all entries:
   ```bash
   sudo umount /mnt/zata
   sudo mount -a
   ```

This will ensure your USB HDD is mounted automatically each time the Raspberry Pi reboots.

### **Troubleshooting**:
- **Permissions Issue**: If you can't write to the USB HDD after mounting it, you might need to adjust permissions:
  ```bash
  sudo chmod -R 777 /mnt/zata
  ```
- **Filesystem Compatibility**: If the drive is formatted with a filesystem type that isn’t supported out-of-the-box (like `exFAT`), you might need to install additional tools:
  ```bash
  sudo apt install exfat-fuse exfat-utils
  ```

Following these steps will allow you to detect, mount, and use your USB HDD on the Raspberry Pi at `/mnt/zata`.

## Setup SMB server
To set up a **passwordless Samba server** on your Raspberry Pi, here’s a detailed guide that combines the relevant steps for configuring the server, allowing you to stream media files to your Android TV box using **VLC** without entering a password every time.

### **Steps to Set Up a Passwordless Samba Server on Raspberry Pi**:

#### **Step 1: Install Samba on Raspberry Pi**

1. **Update Package List**:
   First, update the package list to ensure you're installing the latest versions:
   ```bash
   sudo apt update
   ```

2. **Install Samba**:
   Install the Samba package, which allows sharing files over the network:
   ```bash
   sudo apt install samba samba-common-bin -y
   ```

#### **Step 2: Configure the Samba Share**

1. **Create a Shared Folder** (if you don't have one already):
   For this example, we will use `/mnt/zata`. Replace it with your actual directory if needed.
   ```bash
   sudo mkdir -p /mnt/zata
   sudo chmod -R 777 /mnt/zata  # Make it writable for anyone
   ```

2. **Stop the Samba Service**:
   Before modifying the configuration, stop the Samba service:
   ```bash
   sudo systemctl stop smbd
   ```

3. **Edit the Samba Configuration File**:
   Open the Samba configuration file for editing:
   ```bash
   sudo vim /etc/samba/smb.conf
   ```

4. **Add the Share Configuration**:
   Add the following lines to the end of the file to configure the share with passwordless access:
   ```ini
   [Zata]
   path = /mnt/zata
   read only = no
   guest ok = yes
   force user = pi
   public = yes
   browseable = yes
   writable = yes
   create mask = 0777
   directory mask = 0777
   ```

5. **Enable Guest Access Globally**:
   In the `[global]` section, add or ensure the following lines to enable guest access:
   ```ini
   map to guest = Bad User
   guest account = nobody
   ```

6. **Save and Exit**:
   Save the changes and exit by pressing `CTRL+X`, then `Y`, and finally `Enter`.

#### **Step 3: Restart the Samba Service**

After configuring Samba, restart the service to apply the changes:
```bash
sudo systemctl restart smbd
```

#### **Step 4: Adjust Folder Permissions**

Ensure the shared folder has appropriate permissions for guest access:
```bash
sudo chmod -R 777 /mnt/zata
```

#### **Step 5: Access the Samba Share from VLC on Android TV**

1. **Open VLC on Your Android TV Box**.
2. Go to **Browsing** > **Local Network** > **Samba Shares**.
3. You should see the `Zata` folder listed under the Raspberry Pi share.
4. Click on it to browse and stream files without being prompted for a username or password.

---

### **Explanation of the Key Configurations**:
- **`guest ok = yes`**: Allows access to the share without requiring authentication.
- **`force user = pi`**: Forces the share to always use the `pi` user for permissions, even when accessing as a guest.
- **`map to guest = Bad User`**: Maps all failed logins to a guest account, allowing anyone on the network to connect.
- **`create mask = 0777` and `directory mask = 0777`**: Ensure full read/write permissions for everyone.

By following these steps, you set up a **passwordless Samba share** on your Raspberry Pi, enabling you to access the shared folder from your Android TV box using VLC without having to enter a username or password. This allows for easy and convenient media streaming.


## Setup transmission (torrent client)
To set up **Transmission** (a lightweight and popular torrent client) on your Raspberry Pi, follow these steps:

### **Step 1: Install Transmission**
1. **Update Your Package List**:
   First, update the package list to ensure you get the latest versions:
   ```bash
   sudo apt update
   ```

2. **Install Transmission**:
   Install the Transmission daemon and the web interface:
   ```bash
   sudo apt install transmission-daemon transmission-cli transmission-common
   ```

### **Step 2: Configure Transmission**
By default, Transmission runs as a background service. You need to configure it for your network, as the web interface is password-protected by default.

1. **Stop the Transmission Daemon**:
   To modify the configuration file, stop the Transmission service first:
   ```bash
   sudo systemctl stop transmission-daemon
   ```

2. **Edit the Configuration File**:
   The configuration file is located at `/etc/transmission-daemon/settings.json`. Open it with your preferred text editor (e.g., vim):
   ```bash
   sudo vim /etc/transmission-daemon/settings.json
   ```

   Key changes you should make:
   - **"rpc-authentication-required"**: Set this to `false` to allow passwordless access.
     ```json
     "rpc-authentication-required": false,
     ```
   - **"rpc-bind-address"**: Set to `0.0.0.0` to allow access from any device on your local network.
     ```json
     "rpc-bind-address": "0.0.0.0",
     ```
   - **"rpc-whitelist"**: Set this to `*.*.*.*` to allow connections from any IP address (you can restrict this if you prefer).
     ```json
     "rpc-whitelist": "*.*.*.*",
     ```

   Save and exit by pressing `CTRL+X`, then `Y`, and finally `Enter`.

3. **Adjust Folder Permissions (Optional)**:
   Ensure Transmission can write to the directory you want to save torrents to. For example, if you want to use `/mnt/zata`:
   ```bash
   sudo chmod -R 777 /mnt/zata
   ```

### **Step 3: Restart Transmission**
After modifying the configuration, restart the Transmission service to apply the changes:
```bash
sudo systemctl start transmission-daemon
```

### **Step 4: Access Transmission Web Interface**
Now you can access the Transmission web interface from any browser (including the browser on your Android TV) by entering the Raspberry Pi's IP address followed by port `9091`:
```
http://<raspberry-pi-ip>:9091
```

You should now see the Transmission web interface where you can add, manage, and monitor torrents. If you disabled authentication (`rpc-authentication-required: false`), it should be passwordless.

### **Step 5: Add Torrents**
You can now add torrent files or magnet links through the web interface. 

- **To add a torrent file**: Click on the "Open Torrent" button in the web interface and select the file.
- **To add a magnet link**: Click the "Add Magnet" button and paste the magnet link.

### **Step 6: Monitor and Control Transmission**
Transmission will continue running as a background service, and you can control it via the web interface.

### **Optional: Access Transmission via SSH**
If you need to manage Transmission via command line (using the CLI), you can interact with it via the `transmission-remote` command:

- To see the current torrent status:
  ```bash
  transmission-remote -l
  ```

- To add a torrent from a URL:
  ```bash
  transmission-remote -a <torrent-url>
  ```

### **Summary**:
- Install Transmission via `apt`.
- Configure settings for passwordless access via the web interface.
- Restart the service and access the UI on your local network.
