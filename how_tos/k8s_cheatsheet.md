# k8s cheatsheet

# preparation & definition

create the kc alias in current terminal session:

```bash
alias kc="kubectl "
```

<aside>
⚠️ this alias points to the **** namespace in the kubernetes cluster.
in case you need a different namespace, such as **default** or **kube-system**, make sure you state it explicitly in the command **OR** create another alias for your own comfort.

</aside>

add the kc alias to bashrc for adding it globally to each new terminal sessions:

```bash
echo 'alias kc="kubectl "' >> ~/.bashrc
```

default kubeconfig path:

```bash
~/.kube/config
```

<aside>
⚠️ **“config”** being the file name.

</aside>

there are 2 approaches for defining a kubeconfig file:

**explicit**: defining it in each command

```bash
kc --kubeconfig=/home/kcs/blabla.yaml get pods
```

**global**: defining it as the default kubeconfig that kubectl will use (**best practice**)

within the global approach, there are 2 options:

- **set using environment variable**: applies only for the current terminal session
    
    ```bash
    export KUBECONFIG=/home/kcs/blabla.yaml
    ```
    
- **set the kubeconfig file in the default location**: applies globally for all terminal sessions
    
    ```bash
    vim ~/.kube/config # then paste the kubeconfig file content and save
    ```
    

# frequently used resources

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

# vieweing & displaying

describing an object:

```ruby
kc describe pod POD_NAME
```

getting the object’s yaml:

```ruby
kc get pod POD_NAME -o yaml
```

### Logs

getting logs from pod:

```ruby
kc logs POD_NAME -c CONTAINER_NAME
```

if you need logs from a pod which has a single replica in its deployment,

or from a deployment which has multiple replicas, but not any of them needed specifically,

you can refer to the deployment directly, without specifying the exact pod name:

```ruby
kc logs deploy/app
```

to add timestamps for each log line:

```ruby
kc logs --timestamps deploy/app
```

to stream logs as they’re printed:

```ruby
kc logs -f deploy/app
```

# editing & changing

…

# YAML’s

### apply directly from terminal

```yaml
kubectl apply -f - <<EOF
/// YAML-CONTENT ///
EOF
```

### PVC

```yaml
kubectl apply -f - <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfsv2
  namespace: my-webapp
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: "nfs-qa"
EOF
```

### pod to consume PVC

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pvc-consumer-test
spec:
  volumes:
    - name: pvc-vol
      persistentVolumeClaim:
        claimName: <PVC>
  containers:
    - name: ubuntu
      image: ubuntu:22.04
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/data/sababa"
          name: pvc-vol
EOF
```

# 🗡️ swiss army knife one-liners 🗡️


### label GPU nodes

```bash
kubectl label nodes <NODE> accelerator=nvidia
```

### taint / un-taint nodes

```jsx
kubectl taint nodes <node-name> kubernetes.co.il/priority=spot:NoSchedule
```

```jsx
kubectl taint nodes <node-name> kubernetes.co.il/priority:NoSchedule-
```

### copy files

from local machine to remote pod

```bash
kubectl cp /local/file/path.txt <DESTINATION_POD_NAME>:/ -c main
```

copy between 2 remote pods

```bash
kubectl cp -c main <NAMESPACE>/<SOURCE_POD>:/PATH/TO/FILE <DESTINATION_POD>:/ -c main
```

## run pod

this command will start a pod with the image chosen, and will exec you into its bash terminal:

**stock ubuntu**

```yaml
kc run -i --tty ubuntu22-test --image=ubuntu:22.04 -- bash
```

**network debugger**🌶️ (contains common network utilities: `ping`,`nslookup`,`telnet`, etc)

```bash
kc run -i --tty network-debugger --image=docker.io/<DOCKER_USERNAME>/swiss_army_knife:latest -- bash
```

network debugger as init container:

```bash
spec:
  initContainers:
  - name: network-debugger
    image: docker.io/<DOCKER_USERNAME>/swiss_army_knife:latest
    command: ["sleep", "infinity"]
```

### get an entire secret decoded at once 🌶️🌶️🌶️🌶️🌶️

```bash
kubectl  get secret **pg-creds** -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

### get a clean YAML manifest of an object 🌶️🌶️

<aside>
⚠️ requires both `jq` and `yq` utilities to run

```json
brew install jq
brew install yq
```

</aside>

```json
kc get **<TYPE>** **<NAME>** -o json | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.selfLink,.metadata.creationTimestamp,.metadata.annotations,.metadata.generation,.metadata.ownerReferences,.metadata.managedFields,.status)' | yq eval . --prettyPrint
```

### batch execute command on several pods

example: check `nvidia-smi` output on all  jobs

```bash
kc get pods -o name | grep job | xargs -I{} kubectl  exec {} -c main -- nvidia-smi
```

### sort pods by age

```bash
kc get pods --sort-by=.status.startTime
```

### delete all evicted pods

```bash
kubectl  get pods | grep Evicted | awk '{print $1}' | xargs kubectl  delete pod $1
```

### looping thru objects using JSONPATH

```yaml
JSONPATH='{range .items[*]}{@.metadata.name}{"\n"}{@.spec.template.spec.containers[*].resources}{"\n"}{end}' && \
kc get deploy -o jsonpath="$JSONPATH"
```

### save certificate files from TLS certificate secret

```bash
TLS_CRT_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.crt}")
TLS_KEY_B64=$(kubectl  get secret ocp-funkyzebra-space-tls -o jsonpath="{.data.tls\.key}")
echo $TLS_CRT_B64 | base64 -d > tls.crt
echo $TLS_KEY_B64 | base64 -d > tls.key
```

### create TLS certificate secret

```yaml
kc create secret tls istio-ingressgateway-certs \
--key private.key \
--cert certificate.crt
```

### bonus: check domain certificate expiry date 😻

```python
DOMAIN="openai.com";
openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" -showcerts </dev/null 2>/dev/null | openssl x509 -noout -enddate
```

### delete stubborn namespace with finalizers 🌶️

<aside>
⚠️ run this only after deleting any visible resource left on that namespace.
replace `delete-me` with the namespace.

</aside>

1st terminal:

```bash
kubectl proxy
```

2nd terminal:

```bash
kubectl get ns **** -o json | \
  jq '.spec.finalizers=[]' | \
  curl -X PUT http://localhost:8001/api/v1/namespaces/****/finalize -H "Content-Type: application/json" --data @-
```

### get “all” for real

```bash
kubectl get all,service,pvc,ingress,configmap,\
secret,daemonset,statefulset,cronjob --namespace **<namespace>**
```

### create docker credentials secret

```bash
kubectl  create secret docker-registry **app-registry** \
--docker-server=**docker.io** \
--docker-username=**myuser** \
--docker-password=**mypassword**
```

### acknowledge OCP 4.11 to 4.12 upgrade

```bash
oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.11-kube-1.25-api-removals-in-4.12":"true"}}' --type=merge
```

### loop to check all external IP’s of cluster

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

### loop to check times on all nodes (without SSH access)

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

```
kubectl patch secret my-secret \
-p '{"stringData": {"my-key": "new-secret-value"}}'
```