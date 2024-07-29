# azure devops code repository

# get repo URL

in repo, click on “**clone**” and copy the URL:


```bash
https://jacksontestorg@dev.azure.com/jacksontestorg/duffyduck/_git/duffyduck
```

<aside>
⚠️ if you don’t have a token yet, click “**generate git credentials**” and save the token aside.

</aside>

# integrate with  project

remove the username section from the URL we copied before, i.e:

```bash
https://**jacksontestorg@**dev.azure.com/jacksontestorg/duffyduck/_git/duffyduck
```

will be:

```bash
https://dev.azure.com/jacksontestorg/duffyduck/_git/duffyduck
```

**in project git settings:** provide the 

- new URL
- branch
- your token (if not already provided in user profile)

click “save” to verify connectivity/authentication.

![Untitled](azure%20devops%20code%20repository%205c8b14290b1341a0965534bcacc03d49/Untitled%201.png)