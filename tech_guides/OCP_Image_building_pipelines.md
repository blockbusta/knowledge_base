# OCP Image building pipelines

## Create a BuildConfig

a BuildConfig is an object that holds all settings of the image you intend to build.

In console left pane, click on **Builds** → **BuildConfigs**, then **Create a new BuildConfig** on the right.

In **Source** select **Dockerfile** and provide the Dockerfile content.

In **Build from** select **External container image**, provide the source image address.

In **Image registry** select **External container image**, provide the destination image address.

Once done, click **Create**.

## Create a docker credentials secret for remote repository

run to create the secret in the same namespace:

```bash
kubectl -n lolz create secret \
  docker-registry zebra-creds \
  --docker-server=docker.io \
  --docker-username=<DOCKER_USERNAME> \
  --docker-password=PASSWORD \
  --docker-email=bla@bla.net
```

edit the builder serviceAccount in the same namespace:

```bash
kubectl -n lolz edit sa builder
```

then add the secret to it:

```bash
apiVersion: v1
imagePullSecrets:
- name: builder-dockercfg-6ffrp
kind: ServiceAccount
metadata:
  name: builder
  namespace: lolz
secrets:
- name: builder-dockercfg-6ffrp
**- name: zebra-creds**
```

## Build the image

Head back to the **BuildConfig** created earlier, in its 3 dot menu select **Start Build**.

This will generate a new **Build** object, redirects you to it and starts the build process.

Head over to **Logs** in the **Build** object, to see the build process stdout stream.

If the build is successful, the image will be pushed to the tag provided.

<aside>
🔥 Unlike manually running `docker/podman build` command, there is no cache, and steps aren’t being cached. So each time your build fails, and you fix the step in the BuildConfig and run it again, all prior steps will be run again from scratch.

</aside>