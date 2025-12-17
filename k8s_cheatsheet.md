# k8s cheatsheet

## preparation & definition

create alias in current terminal session:

```bash
alias k="kubectl"
```

for example, an alias to kube-system namespace:
```bash
alias ks="kubectl -n kube-system"
```

add the alias to bashrc/zshrc:

```bash
echo 'alias kc="kubectl "' >> ~/.bashrc
echo 'alias kc="kubectl "' >> ~/.zshrc
```

### Setting kubeconfig file
there are few approaches for defining the kubeconfig file you want to work with:

- stating it explicitly it in each command:
  ```bash
  k --kubeconfig=/home/kcs/blabla.yaml get pods
  ```

- defining it as the default kubeconfig file per terminal session using env:
  ```bash
  export KUBECONFIG=/home/kcs/blabla.yaml
  ```
  
- set the kubeconfig file in the default location which applies globally for all terminal sessions:
  ```bash
  vim ~/.kube/config
  ```

## frequently used resources

| object | alias | description |
| --- | --- | --- |
| pod | po |  |
| deployment | deploy |  |
| replicaset | rs |  |
| daemonset | ds |  |
| statefulset | sts |  |
| persistentvolumeclaim | pvc |  |
| persistentvolume | pv |  |
| storageclass | sc |  |
| cronjob | cj |  |
| horizontalpodautoscaler | hpa |  |
| service | svc |  |
| virtualservice | vs |  |
| configmap | cm |  |
| secret |  |  |
| node | no |  |

## vieweing & displaying

describing an object:

```bash
k describe pod POD_NAME
```

getting the object’s yaml:

```bash
k get pod POD_NAME -o yaml
```

### Logs

getting logs from pod:

```bash
k logs POD_NAME -c CONTAINER_NAME
```

if you need logs from a pod which has a single replica in its deployment,
or from a deployment which has multiple replicas, but not any of them needed specifically,
you can refer to the deployment directly, without specifying the exact pod name:

```bash
k logs deploy/app
```

or from a specific container:
```bash
k logs deploy/app -c container01
```

to add timestamps for each log line:

```bash
k logs --timestamps deploy/app
```

to stream logs as they’re printed:

```bash
k logs -f deploy/app
```

to show only 100 last rows of output:
```bash
k logs --tail 100 deploy/app
```

**script to export logs for an entire namespace**
usage: `bash log_saver.sh mycoolnamespace` will export logs to sub-folder `./mycoolnamespace-logs/`
```bash
#!/bin/bash

NAMESPACE=$1
LOG_DIR="./$NAMESPACE-logs"
mkdir $LOG_DIR

PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')

for POD in $PODS; do
  CONTAINERS=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}')
  
  for CONTAINER in $CONTAINERS; do
    LOG_FILE="$LOG_DIR/${POD}_${CONTAINER}.log"
    
    echo "Collecting logs for Pod: $POD, Container: $CONTAINER"
    kubectl logs --timestamps $POD -c $CONTAINER -n $NAMESPACE > "$LOG_FILE"
  done
done

echo "Logs saved to $LOG_DIR"
```

## editing & modifying

…

## YAML’s

### apply directly from terminal

```yaml
kubectl apply -f - <<EOF
/// YAML-CONTENT ///
EOF
```

## 🗡️ swiss army knife one-liners 🗡️

## run pod 🌶️

this command will start a pod with the image chosen, and will exec you into its bash terminal:
```bash
kubectl run -i --tty debugger --image=wbitt/network-multitool -- bash
```

run pod only, without exec:
```bash
kubectl run test --image=nginx --command -- sleep infinity
```

## run pod on specific node
```bash
kubectl run test-dgx05 --image=nginx --overrides='{"spec": {"nodeName": "dgx05"}}'
```

## debug pod 🌶️🌶️🌶

this command will "inject" a new container into an existing pod. allowing you to debug that pod without harming its operation:
```
kubectl -n kube-system debug my-pod -c debugger --image wbitt/network-multitool -- sleep infinity
```
exec into that container after its up:
```
kubectl -n kube-system exec -it my-pod -c debugger -- bash
```

## debug node 🌶️🌶️🌶
this creates a pod on the node with root access - super useful!
```bash
kubectl debug node/ip-172-20-10-13 -it --image=ubuntu -- chroot /host bash
```

### get an entire secret decoded at once 🌶️🌶️🌶️🌶️🌶️
using kubectl:
```bash
kubectl get secret my-secret \
-o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

using kubectl + jq:
```bash
kubectl get secret my-secret \
-o jsonpath="{.data}" | jq -r 'to_entries[] | "\(.key): \(.value | @base64d)"'
```

### Taints & Labels

label GPU nodes
```bash
kubectl label nodes <NODE> accelerator=nvidia
```

taint node:
```bash
kubectl taint nodes <node-name> kubernetes.co.il/priority=spot:NoSchedule
```

un-taint node:
```bash
kubectl taint nodes <node-name> kubernetes.co.il/priority:NoSchedule-
```

### copy files

from local machine to pod:
```bash
kubectl cp /local/file/path.txt <DESTINATION_POD_NAME>:/ -c main
```

copy between 2 pods:
```bash
kubectl cp -c main <NAMESPACE>/<SOURCE_POD>:/PATH/TO/FILE <DESTINATION_POD>:/ -c main
```

### sort pods by age
```bash
kget pods --sort-by=.status.startTime
```

### delete stubborn namespace with finalizers 🌶️
<aside>
⚠️ run this only after deleting any visible resource left on that namespace. replace `delete-me` with the namespace.
</aside>

1st terminal (or use htop in a single terminal):
```bash
kubectl proxy
```

2nd terminal:
```bash
kubectl get ns **** -o json | \
  jq '.spec.finalizers=[]' | \
  curl -X PUT http://localhost:8001/api/v1/namespaces/****/finalize -H "Content-Type: application/json" --data @-
```

### create docker credentials secret
```bash
kubectl create secret docker-registry **app-registry** \
--docker-server=docker.io \
--docker-username=myuser \
--docker-password=mypass
```

### acknowledge OCP 4.11 to 4.12 upgrade
```bash
oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.11-kube-1.25-api-removals-in-4.12":"true"}}' --type=merge
```

## loops / batch

### batch execute command on several pods
for example: check `nvidia-smi` output on all pods named blabla
```bash
k get pods -o name | grep blabla | xargs -I{} kubectl exec {} -- nvidia-smi
```

### delete all evicted pods
```bash
kubectl get pods | grep Evicted | awk '{print $1}' | xargs kubectl delete pod $1
```

### looping thru objects using JSONPATH
```yaml
JSONPATH='{range .items[*]}{@.metadata.name}{"\n"}{@.spec.template.spec.containers[*].resources}{"\n"}{end}' && \
kget deploy -o jsonpath="$JSONPATH"
```

### check all external IP’s of cluster:
```bash
#!/bin/bash

NAMESPACE=""

for POD_NAME in $(kubectl get pods -n $NAMESPACE -o=name); do
  POD_NAME=$(basename "$POD_NAME")
  echo "Checking IP address for pod: $POD_NAME"
  kubectl exec -n $NAMESPACE $POD_NAME -- sh -c 'curl -s ifconfig.me && curl -s ipinfo.io'
  echo "--------------------------------------------------"
  echo ""
done
```

### check times on all nodes (without SSH access)
```bash
NODE_LIST=$(kubectl get nodes -o jsonpath='{range .items[*]}{@.metadata.name}{" "}{end}')

echo $NODE_LIST | while IFS=' ' read -A NODES; do
  for node in "${NODES[@]}"; do
    echo "checking time on $node"
    echo "current time on local machine: $(date -u)"
	  pod=$(kubectl describe node $node | awk '/Non-terminated Pods/{getline; getline; getline; print $2}')
	  namespace=$(kubectl describe node $node | awk '/Non-terminated Pods/{getline; getline; getline; print $1}')
	  kubectl exec -it $pod -n $namespace -- /bin/sh -c "echo current time on $node: \$(date)"
	  echo ""
  done
done
```

### patch secret using clear text

```bash
kubectl patch secret my-secret \
-p '{"stringData": {"my-key": "new-secret-value"}}'
```

### re-create secret in another namespace
```bash
kubectl -n SOURCE_NAMESPACE get secret my-secret -o yaml | \
yq eval '
  .metadata.namespace = "TARGET_NAMESPACE" |
  del(.metadata.creationTimestamp) |
  del(.metadata.resourceVersion) |
  del(.metadata.selfLink) |
  del(.metadata.uid)
' - | \
kubectl apply -f -
```

### check TLS certificate 🌶️🌶️🌶️
from secret:
```bash
kubectl get secret <secret-name> -o jsonpath="{.data['tls\.crt']}" | base64 --decode | openssl x509 -noout -subject -issuer -dates
```
from domain:
```bash
DOMAIN="google.com"; openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

### save certificate files from TLS secret
```bash
TLS_CRT_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.crt}")
TLS_KEY_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.key}")
echo $TLS_CRT_B64 | base64 -d > tls.crt
echo $TLS_KEY_B64 | base64 -d > tls.key
```

### create TLS secret
```bash
k create secret tls istio-ingressgateway-certs \
--key tls.key \
--cert tls.crt
```

### list full path URL's for all ingresses
```bash
NAMESPACE=default && kubectl get ingress -n $NAMESPACE -o json | jq -r '.items[] | (.metadata.namespace + "/" + .metadata.name) as $id | (.spec.tls // [] | length > 0) as $tls | .spec.rules[] | .host as $host | .http.paths[] | $id + ": " + (if $tls then "https://" else "http://" end) + $host + .path'
```

### list nodes resources 🌶️🌶️🌶
```bash
kubectl get nodes "-o=custom-columns=NAME:.metadata.name,CPUs:.status.capacity.cpu,RAM:.status.capacity.memory,GPU-cap:.status.capacity.nvidia\.com\/gpu,GPU-aloc:.status.allocatable.nvidia\.com\/gpu,GPU-type:.metadata.labels.nvidia\.com\/gpu\.product,OS:.status.nodeInfo.osImage,K8S:.status.nodeInfo.kubeletVersion,RUNTIME:.status.nodeInfo.containerRuntimeVersion"
```

example output:
```
NAME               CPUs   RAM          GPU-cap   GPU-aloc   GPU-type     OS                   K8S       RUNTIME
ip-172-20-10-233   8      32387572Ki   <none>    <none>     <none>       Ubuntu 20.04.6 LTS   v1.28.9   containerd://1.7.27
ip-172-20-10-26    8      32387568Ki   <none>    <none>     <none>       Ubuntu 20.04.6 LTS   v1.28.9   containerd://1.7.27
ip-172-20-10-28    8      32043504Ki   <none>    <none>     <none>       Ubuntu 20.04.6 LTS   v1.28.9   containerd://1.7.27
ip-172-20-10-92    8      32043504Ki   16        16         Tesla-V100   Ubuntu 20.04.6 LTS   v1.28.9   containerd://1.7.27
```

## GPU

### get all pods with GPU request/limit
```bash
kubectl get pods --all-namespaces -o=jsonpath='{range .items[?(@.spec.containers[*].resources.requests.nvidia\.com/gpu)]}{.metadata.namespace}{" | "}{.metadata.name}{" | "}{.spec.containers[*].resources.requests.nvidia\.com/gpu}{" | "}{.spec.containers[*].resources.limits.nvidia\.com/gpu}{"\n"}{end}'
```

### get all pods with fraction GPU
```bash
kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,POD NAME:.metadata.name,GPU FRACTION:.metadata.annotations.gpu-fraction" | grep -v '<none>'
```

### get nodes' total & allocated GPU amount
```bash
NODE_NAME="ip-172-20-10-247"
gpu_total=$(kubectl describe node $NODE_NAME | grep "nvidia.com/gpu:" -m1 | awk '{print $2}')
gpu_allocated=$(kubectl describe node $NODE_NAME | grep "nvidia.com/gpu " -m1 | awk '{print $2}')
echo "node: $NODE_NAME, total GPUs: $gpu_total, Allocated GPUs: $gpu_allocated"
```
example output:
```
node: ip-172-20-10-247, total GPUs: 1, Allocated GPUs: 0
```

## AWS

### run AWS CLI commands, from node that runs on EC2 instance / EKS node:
for example: `aws sts get-caller-identity`
```bash
# Quick one-liner to run aws-cli in a pod on a specific node
kubectl run aws-cli-test --rm -i --tty \
  --image=amazon/aws-cli \
  --overrides='{"spec":{"nodeSelector":{"kubernetes.io/hostname":"YOUR_NODE_NAME"}}}' \
  -- sts get-caller-identity
```
