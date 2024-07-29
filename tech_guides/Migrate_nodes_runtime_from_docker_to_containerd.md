# Migrate nodes runtime from docker to containerd

## Official reference:

[https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/](https://kubernetes.io/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/)

## Rancher cluster configuration:

Here's an example of how the **`kubelet`** section may look in the Rancher cluster configuration file (**`cluster.yaml`** or **`rancher-cluster.yaml`**):

```yaml
kubernetesVersion: <desired-kubernetes-version>
...
kubelet:
  ...
  extraArgs:
    container-runtime: containerd
```

- **`extraArgs`** section is used to pass additional arguments to the kubelet.
- **`container-runtime`** option is set to **`containerd`**
indicating that containerd should be used as the container runtime.

Once you have modified the Rancher cluster configuration file to include the **`container-runtime`** option for containerd, you would apply the changes to the cluster. This can typically be done through the Rancher UI or by using the Rancher CLI tool (**`rancher`**).

After applying the changes, the kubelet on each node in the Rancher cluster will be configured to use containerd as the container runtime.