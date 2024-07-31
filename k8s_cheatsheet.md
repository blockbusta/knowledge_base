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

## debug pod 🌶️

this command will "inject" a new container into an existing pod. allowing you to debug that pod without harming its operation:
```
kubectl -n kube-system debug my-pod -c debugger --image wbitt/network-multitool -- sleep infinity
```
exec into that container after its up:
```
kubectl -n kube-system exec -it my-pod -c debugger -- bash
```

### get an entire secret decoded at once 🌶️🌶️🌶️🌶️🌶️
```bash
kubectl get secret my-secret \
-o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
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

## run pod

this command will start a pod with the image chosen, and will exec you into its bash terminal:
```bash
k run -i --tty ubuntu22-test --image=ubuntu:22.04 -- bash
```

### sort pods by age
```bash
kget pods --sort-by=.status.startTime
```

### save certificate files from TLS certificate secret
```bash
TLS_CRT_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.crt}")
TLS_KEY_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.key}")
echo $TLS_CRT_B64 | base64 -d > tls.crt
echo $TLS_KEY_B64 | base64 -d > tls.key
```

### create TLS certificate secret
```bash
k create secret tls istio-ingressgateway-certs \
--key tls.key \
--cert tls.crt
```

### bonus: check domain certificate expiry date 😻
```bash
DOMAIN="openai.com";
openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" -showcerts </dev/null 2>/dev/null | openssl x509 -noout -enddate
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

Export the existing secret:
```bash
kubectl get secret my-secret -n source-namespace -o yaml > secret_old.yaml
```

Clean up and modify the YAML (using `yq` utility)
Make sure to replace `target-namespace`:
```bash
yq eval '
  .metadata.namespace = "target-namespace" |
  del(.metadata.creationTimestamp) |
  del(.metadata.resourceVersion) |
  del(.metadata.selfLink) |
  del(.metadata.uid)
' secret_old.yaml > secret_new.yaml
```

Create the new secret in the target namespace
```bash
kubectl apply -f secret_new.yaml
```