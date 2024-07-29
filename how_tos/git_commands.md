# git commands

### usage in 

each job loads the git access token defined in user settings (regardless of private/public repo)

- theres no need for credentials if its a public repo with write access

git credentials are available at:

```bash
~/.git-credentials
```

and the git config at:

```bash
//.git/config
```

when pushing to github from workspace, and cloning the repo back, you will encounter errors.

the `.gitignore` file should contain:

```bash
.
.ignore
```

so these files wont be pushed back to remote repo, and they'll get created each time as needed

### basic commands

check remote repo connectivity (command will display list of commits):

```bash
git ls-remote **REPO_URL**

# for http token:
git ls-remote https://x-access-token:**TOKEN**@github.com/**USER**/**REPO**.git

# for ssh key:
git ls-remote git@github.com:**USER**/**REPO**
```

clone remote repo:

```bash
git clone **REPO_URL**
```

checkout to different branch:

```bash
git checkout -b **BRANCH_NAME**
```

add files to track:

```bash
git add .
```

remove file from track:

```bash
git rm --cached **FILE**
```

check status:

```bash
git status
```

check diff:

```bash
git diff --name-only
```

commit files:

```bash
git commit -m "your commit message"
```

push files to remote repo:

```bash
git push
```

show current branches:

```ruby
git branch
```

show current git info:

```ruby
git config --list
```

link directory to existing git repo and push to it:

```bash
git init
git add *
git commit -a -m 'init commit'
git remote add origin **git@github.com:username/repo.git**
```

### submodules

add submodule to current git repo:

```bash
git submodule add https://github.com/**USER/SUBMODULE_REPO**
```

to push back changes:

```python
git add -N .gitmodules
git pineapple...
git push
```

clone submodule:

```bash
git submodule update --init
```

if submodule clone requires login, change **.gitmodules** file from HTTPS to SSH:

```sql
[submodule "SUBMODULE_REPO_NAME"]
        path = SUBMODULE_REPO_NAME
        url = SUBMODULE_REPO_URL_SSH
```

if **error: RPC failed; curl 55 The requested URL returned error: 401**

```ruby
git config http.postBuffer 524288000
```