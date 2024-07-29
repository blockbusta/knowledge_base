# docker

build image (from local **`Dockerfile`**)

```bash
docker build .
```

**FIX**: when `apt-get update` command fails during build

```bash
docker build --network=host .
```

ingore existing layers and build again

```bash
docker build --no-cache .
```

tag image

```bash
# find image ID
docker images

# tag it (repo should exist)
docker tag **IMAGE_ID** **USER/REPO:TAG**
```

run container locally, without network connectivity (simulate offline machine)

```bash
docker run -it --network none ubuntu:16.04
```

save a running container as new image

```bash
# get container id:
docker ps

# commit (save) the container as a new image:
docker commit **CONTAINER_ID USER/REPO:TAG**
```

push image to repo

```bash
docker push **USER/REPO:TAG**
```

check docker credentials in app

```bash
kc edit app

# credentials should be here:

registry:
    name: registry
    password: *
    url: docker.io
    user: *
```

save image as file

```bash
docker save **IMAGE** -o **FILENAME**
```

load image from file

```bash
docker load < **FILENAME**
```

see all running containers with full entrypoint command

```yaml
docker ps --no-trunc
```