# create SSH key

create ssh key in default path ****`~/.ssh`

```bash
ssh-keygen -t rsa -b 4096 -C "rke-test@blabla.com"
```

creates 2 files:

```bash
id_rsa # private key
id_rsa.pub # public key
```