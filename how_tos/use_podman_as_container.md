# use podman as container

### apply this yaml:

```yaml
kc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
 name: podman-ops
spec:
 containers:
   - name: podman
     image: quay.io/podman/stable
     args:
       - sleep
       - infinity
     securityContext:
       privileged: true
EOF
```

exec to pod:

```bash
kc exec -it podman-ops -- bash
```

from the pod terminal, you can execute all **podman commands (same as with docker)**

```ruby
podman login --username=<DOCKER_USERNAME> --password=<PASSWORD> docker.io

podman build .

podman images

podman tag b65fdfc3e83a docker.io/<DOCKER_USERNAME>/podman-test:lolz-v1

podman save -o podman-test-lolz b65fdfc3e83a

podman push docker.io/<DOCKER_USERNAME>/podman-test:lolz-v1
```

<aside>
⚠️ if you get these errors during build:

```yaml
WARN[0126] SHELL is not supported for OCI image format,
[/bin/bash --login -c] will be ignored. Must use `docker` format
```

run the build command with docker format:

```yaml
podman build --format=docker .
```

</aside>