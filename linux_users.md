Here are the main commands to list users in Linux:

1. View all users:
```bash
cat /etc/passwd
```

2. View just usernames:
```bash
cut -d: -f1 /etc/passwd
```

3. List users currently logged in:
```bash
who
```

4. View detailed info about current user:
```bash
id
```

5. View groups:
```bash
cat /etc/group
```

6. View all users with login shells (actual users vs system users):
```bash
grep -v '/usr/sbin/nologin\|/bin/false' /etc/passwd
```

7. View current user and their groups:
```bash
whoami
groups
```

Most containers will have a minimal set of these, typically just root and maybe a service user. In OpenShift, you'll often see that your effective UID is a high number (like 1000680000) due to OpenShift's security context constraints, even if the container's /etc/passwd shows different users.
