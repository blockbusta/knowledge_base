# GKE TPU

**official docs:**

[https://cloud.google.com/tpu/docs/kubernetes-engine-setup](https://cloud.google.com/tpu/docs/kubernetes-engine-setup)

- enable TPU in cluster settings
- set CIDR range for TPU devices

**env:**

[http://app.jackson-tpu-test.gcpops.webapp.me/](http://app.jackson-tpu-test.gcpops.webapp.me/)

```bash
test@testing.zzz
123456
```

<aside>
⚠️ no transmission of status back to app from workflow pods, need to check

</aside>

# TESTS

**allocation & utilization:**

<aside>
⚠️ The Cloud TPUs that will be created for this Job will support TensorFlow 2.6.0. This version MUST match the TensorFlow version that your model is built on.
[https://cloud.google.com/tpu/docs/supported-tpu-versions](https://cloud.google.com/tpu/docs/supported-tpu-versions)

</aside>

```bash
kubectl  apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: gke-tpu-pod
  annotations:
     tf-version.cloud-tpus.google.com: "2.6.0"
spec:
  restartPolicy: Never
  containers:
  - name: gke-tpu-container
    image: tensorflow/tensorflow:2.6.0
    command:
    - python
    - -c
    - |
      import tensorflow as tf
      print("Tensorflow version " + tf.__version__)

      tpu = tf.distribute.cluster_resolver.TPUClusterResolver('$(KUBE_GOOGLE_CLOUD_TPU_ENDPOINTS)')
      print('Running on TPU ', tpu.cluster_spec().as_dict()['worker'])

      tf.config.experimental_connect_to_cluster(tpu)
      tf.tpu.experimental.initialize_tpu_system(tpu)
      strategy = tf.distribute.TPUStrategy(tpu)

      @tf.function
      def add_fn(x,y):
          z = x + y
          return z

      x = tf.constant(1.)
      y = tf.constant(1.)
      z = strategy.run(add_fn, args=(x,y))
      print(z)
    resources:
      limits:
        cloud-tpus.google.com/preemptible-v2: 8
EOF
```

**output was successful as explained in docs:**

(exported by running kc logs on the completed 0/1 pod)

```bash
# kc logs gke-tpu-pod

2022-10-16 11:39:58.788470: I tensorflow/core/platform/cpu_feature_guard.cc:142] This TensorFlow binary is optimized with oneAPI Deep Neural Network Library (oneDNN) to use the following CPU instructions in performance-critical operations:  AVX2 FMA. To enable them in other operations, rebuild TensorFlow with the appropriate compiler flags.
2022-10-16 11:39:58.795345: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:272] Initialize GrpcChannelCache for job worker -> {0 -> 172.16.0.10:8470}
2022-10-16 11:39:58.795485: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:272] Initialize GrpcChannelCache for job localhost -> {0 -> localhost:32769}
2022-10-16 11:39:58.812969: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:272] Initialize GrpcChannelCache for job worker -> {0 -> 172.16.0.10:8470}
2022-10-16 11:39:58.813104: I tensorflow/core/distributed_runtime/rpc/grpc_channel.cc:272] Initialize GrpcChannelCache for job localhost -> {0 -> localhost:32769}
2022-10-16 11:39:58.813794: I tensorflow/core/distributed_runtime/rpc/grpc_server_lib.cc:427] Started server with target: grpc://localhost:32769

Tensorflow version 2.6.0
Running on TPU  ['172.16.0.10:8470']
PerReplica:{
  0: tf.Tensor(2.0, shape=(), dtype=float32),
  1: tf.Tensor(2.0, shape=(), dtype=float32),
  2: tf.Tensor(2.0, shape=(), dtype=float32),
  3: tf.Tensor(2.0, shape=(), dtype=float32),
  4: tf.Tensor(2.0, shape=(), dtype=float32),
  5: tf.Tensor(2.0, shape=(), dtype=float32),
  6: tf.Tensor(2.0, shape=(), dtype=float32),
  7: tf.Tensor(2.0, shape=(), dtype=float32)
}
```

**termination:**

TPU resource takes about 2-3 min to allocate, but scales down as soon as pod is terminated.

```bash
# kc get tpu

NAME           AGE
tpu-9e6c89ff   14s
```

another test

```bash
kubectl  apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: jackson-tpu-pod-test
  annotations:
     tf-version.cloud-tpus.google.com: "2.6.0"
spec:
  restartPolicy: Never
  containers:
  - name: shiguim2000
    image: tensorflow/tensorflow:2.6.0
    command:
    - which python
    resources:
      limits:
        cloud-tpus.google.com/preemptible-v2: 8
EOF
```

**conclusion**: no other command (besides an explicit execution of tensorflow python code) is possible within this template.

# Logs, Monitoring and metrics

[https://cloud.google.com/tpu/docs/troubleshooting/tpu-node-monitoring](https://cloud.google.com/tpu/docs/troubleshooting/tpu-node-monitoring)

we’ll need to scrape from GCP API



[https://docs.datadoghq.com/integrations/google_cloud_tpu/](https://docs.datadoghq.com/integrations/google_cloud_tpu/)