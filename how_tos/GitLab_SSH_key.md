# GitLab SSH key

1) generate the keys (provide **KEYNAME**)

```bash
ssh-keygen -t rsa -b 4096 -C "your@mail.com"
```

2) Start the ssh-agent

```bash
eval "$(ssh-agent -s)"
```

3) Add your SSH private key to the ssh-agent

```bash
ssh-add -K ~/.ssh/**KEYNAME**
```

4) copy your public key

```bash
cat **KEYNAME**.pub | pbcopy
```

5) go to your GitLab profile

[https://gitlab.com/profile/keys](https://gitlab.com/profile/keys)

and paste your public key in new key section, add **title** and **expiry date** if needed:


6) click **Add Key**

7) copy the private key

```bash
cat **KEYNAME** | pbcopy
```

8) in  project, go to **project settings** → **git integration**


and paste the private key in **SSH private key** field, then click **Save**