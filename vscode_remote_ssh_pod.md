Here's a script that you can run *inside* your pod to install the SSH server and set it up for VS Code Remote:

```bash
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define a secure password for the user (replace with something strong!)
PASSWORD="123456"

# Username
USERNAME="developer"

# Install SSH server
apt-get update
apt-get install -y openssh-server sudo

# Create user
useradd -m -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG sudo "$USERNAME"  # Add user to sudo group

# Create SSH directory
mkdir /home/"$USERNAME"/.ssh
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh

# Generate SSH keys (if you don't have them already, this is insecure!)
# ssh-keygen -t rsa -b 4096 -N "" -f /home/"$USERNAME"/.ssh/id_rsa
# cat /home/"$USERNAME"/.ssh/id_rsa.pub  # Print the public key

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config

# Add public SSH key to authorized_keys (replace with your actual public key)
# echo "your_ssh_public_key" > /home/"$USERNAME"/.ssh/authorized_keys  # REPLACE THIS
# chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh/authorized_keys
# chmod 600 /home/"$USERNAME"/.ssh/authorized_keys


#Allow password authentication for vscode-ssh(ONLY IN DEV)
sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Restart SSH service
service ssh restart

echo "SSH server installed and configured."
echo "User: $USERNAME"
echo "Remember to forward port 22 from your pod!"
echo "Use VS Code Remote - SSH to connect."
```

**Port Forwarding:** After running the script, you still need to set up port forwarding from your local machine to the pod's SSH port (usually 22):
```bash
nohup kubectl port-forward <pod-name> 2222:22 &
```

**Connect with VS Code:**
Use the VS Code Remote - SSH extension to connect to the pod using
```
ssh://developer@localhost:2222
```
(or whatever port you forwarded).
with password `123456`

This script provides a way to set up SSH within a running pod. Remember the security implications and use it with extreme caution.
