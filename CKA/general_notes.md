# general notes for CKA exam
### create static pod
```
cat <<EOF >/etc/kubernetes/manifests/static-web.yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-busybox
spec:
  containers:
    - name: static-busybox
      image: busybox
      command: ["sleep", "1000"]
EOF
```
```
systemctl restart kubelet
```
### expose deployment using nodeport
```
apiVersion: v1
kind: Service
metadata:
  name: hr-web-app-service
  labels:
    app: hr-web-app
spec:
  type: NodePort
  selector:
    app: hr-web-app
  ports:
    - protocol: TCP
      port: 8080          ### The port on which the service is exposed internally
      targetPort: 8080     ### The port on which the application is listening in the pod
      nodePort: 30082      ### The port that will be exposed on the node
```

### create hostpath volume
```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-analytics
spec:
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: /pv/data-analytics
```

### etcd backup:
```
export ETCDCTL_API=3;
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/etcd-backup.db;
ls -lah /opt/etcd-backup.db
```
### create pod with emptydir volume
```
apiVersion: v1
kind: Pod
metadata:
  name: redis-storage
spec:
  containers:
    - name: redis-storage
      image: redis:alpine
      volumeMounts:
      - name: main-vol
        mountPath: /data/redis
  volumes:
  - name: main-vol
    emptyDir: {}
```
### create pod with system_time capabilites
```
apiVersion: v1
kind: Pod
metadata:
  name: super-user-pod
spec:
  containers:
  - name: super-user-pod
    image: busybox:1.28
    securityContext:
      capabilities:
        add: ["SYS_TIME"]
    command: ["sleep", "4800"]
```
### modify pod mainfest to mount pv
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  volumeName: pv-1
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: use-pv
  name: use-pv
spec:
  containers:
  - image: nginx
    name: use-pv
    volumeMounts:
    - name: my-pvc
      mountPath: /data
  volumes:
  - name: my-pvc
    persistentVolumeClaim: 
      claimName: my-pvc
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```
```
k exec -it use-pv -- df -h
```
### create deploy then change image using rolling update
```
kubectl create deployment nginx-deploy --image=nginx:1.16 --replicas=1
kubectl set image deployment/nginx-deploy nginx=nginx:1.17
kubectl rollout status deployment/nginx-deploy
kubectl get deploy -o wide
```
### RBAC basics task:
> Create a new user called john. Grant him access to the cluster. 
> John should have permission to create, list, get, update and delete pods in the development namespace .
> The private key exists in the location: /root/CKA/john.key and csr at /root/CKA/john.csr.
> Important Note: As of kubernetes 1.19, the CertificateSigningRequest object expects a signerName.
```
kubectl --namespace=development create role developer --resource=pods --verb=create,list,get,update,delete
kubectl --namespace=development create rolebinding developer-role-binding --role=developer --user=john
```
You can encode the CSR file with:
grab the encoded csr, and place in spec.request, using:
```
cat /root/CKA/john.csr | base64 | tr -d '\n'
```
CSR manifest:
```
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john-developer
spec:
  signerName: kubernetes.io/kube-apiserver-client
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1ZEQ0NBVHdDQVFBd0R6RU5NQXNHQTFVRUF3d0VhbTlvYmpDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRApnZ0VQQURDQ0FRb0NnZ0VCQUt2Um1tQ0h2ZjBrTHNldlF3aWVKSzcrVVdRck04ZGtkdzkyYUJTdG1uUVNhMGFPCjV3c3cwbVZyNkNjcEJFRmVreHk5NUVydkgyTHhqQTNiSHVsTVVub2ZkUU9rbjYra1NNY2o3TzdWYlBld2k2OEIKa3JoM2prRFNuZGFvV1NPWXBKOFg1WUZ5c2ZvNUpxby82YU92czFGcEc3bm5SMG1JYWpySTlNVVFEdTVncGw4bgpjakY0TG4vQ3NEb3o3QXNadEgwcVpwc0dXYVpURTBKOWNrQmswZWhiV2tMeDJUK3pEYzlmaDVIMjZsSE4zbHM4CktiSlRuSnY3WDFsNndCeTN5WUFUSXRNclpUR28wZ2c1QS9uREZ4SXdHcXNlMTdLZDRaa1k3RDJIZ3R4UytkMEMKMTNBeHNVdzQyWVZ6ZzhkYXJzVGRMZzcxQ2NaanRxdS9YSmlyQmxVQ0F3RUFBYUFBTUEwR0NTcUdTSWIzRFFFQgpDd1VBQTRJQkFRQ1VKTnNMelBKczB2czlGTTVpUzJ0akMyaVYvdXptcmwxTGNUTStsbXpSODNsS09uL0NoMTZlClNLNHplRlFtbGF0c0hCOGZBU2ZhQnRaOUJ2UnVlMUZnbHk1b2VuTk5LaW9FMnc3TUx1a0oyODBWRWFxUjN2SSsKNzRiNnduNkhYclJsYVhaM25VMTFQVTlsT3RBSGxQeDNYVWpCVk5QaGhlUlBmR3p3TTRselZuQW5mNm96bEtxSgpvT3RORStlZ2FYWDdvc3BvZmdWZWVqc25Yd0RjZ05pSFFTbDgzSkljUCtjOVBHMDJtNyt0NmpJU3VoRllTVjZtCmlqblNucHBKZWhFUGxPMkFNcmJzU0VpaFB1N294Wm9iZDFtdWF4bWtVa0NoSzZLeGV0RjVEdWhRMi80NEMvSDIKOWk1bnpMMlRST3RndGRJZjAveUF5N05COHlOY3FPR0QKLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  usages:
  - digital signature
  - key encipherment
  - client auth
```
auth csr & verify permissions
```
kubectl certificate approve john-developer
kubectl auth can-i update pods --as=john --namespace=development
```
### create pod ...
```
kubectl run nginx-resolver --image=nginx --restart=Never --port=80
kubectl label pod nginx-resolver app=nginx-resolver
```
?
```
kubectl expose pod nginx-resolver --name=nginx-resolver-service --port=80 --target-port=80 --type=ClusterIP
```
DNS stuff?
```
k run dns-check --image=busybox:1.28 --command -- sleep 1000000

k exec -it dns-check -- nslookup 10-244-192-4.default.pod > /root/CKA/nginx.pod
k exec -it dns-check -- nslookup nginx-resolver-service > /root/CKA/nginx.svc
```

> REMEMBER: pod names aren't resolvable! replace pod ip dots with hyphen:

> ```nslookup P-O-D-I-P.namespace.pod```

> ```nslookup 10-244-5-7.default.pod```

### create static pod on node01
```
ssh node01

cd /etc/kubernetes/manifests

vim nginx-critical.yaml

apiVersion: v1
kind: Pod
metadata:
  name: nginx-critical
  labels:
    app: nginx
spec:
  containers:
    - name: web
      image: nginx
      ports:
        - name: web
          containerPort: 80
          protocol: TCP
  restartPolicy: Always
```
### if static pod doesnt create - check static pod path in kubelet config:
```
ps -ef | grep kubelet | grep config
cat /var/lib/kubelet/config.yaml | grep -i static
```
### if not there, add and restart kubelet
```
echo "staticPodPath: /etc/kubernetes/manifests" >> /var/lib/kubelet/config.yaml
systemctl restart kubelet
```
### exam 3 question 1
### create sa, cluster role with list pv, then assign it to pod, and verify permissions
```
kubectl create serviceaccount pvviewer
kubectl --namespace=development create clusterrole pvviewer-role --resource=persistentvolumes --verb=list
kubectl --namespace=development create clusterrolebinding pvviewer-role-binding --clusterrole=pvviewer-role --user=pvviewer

k run pvviewer --image=redis --serviceaccount=pvviewer

apiVersion: v1
kind: Pod
metadata:
  name: pvviewer
spec:
  containers:
    - name: pvviewer
      image: redis
  serviceAccountName: pvviewer

kubectl auth can-i list persistentvolumes --as=pvviewer
```
### exam 3 question 2
> List the InternalIP of all nodes of the cluster. Save the result to a file /root/CKA/node_ips.
```
InternalIP of controlplane<space>InternalIP of node01

kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' > /root/CKA/node_ips
```
### exam 3 question 3
> Create a pod called multi-pod with two containers.

> Container 1: name: alpha, image: nginx

> Container 2: name: beta, image: busybox, command: sleep 4800
```
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
spec:
  containers:
    - name: alpha
      image: nginx
      env:
      - name: name
        value: alpha
    - name: beta
      image: busybox
      command: ["sleep", "4800"]
      env:
      - name: name
        value: beta
```
### exam 3 question 4
> Create a Pod called non-root-pod , image: redis:alpine

> runAsUser: 1000

> fsGroup: 2000
```
apiVersion: v1
kind: Pod
metadata:
  name: non-root-pod
spec:
  securityContext:
    runAsUser: 1000
    fsGroup: 2000
  containers:
    - name: non-root-pod
      image: redis:alpine
```
### exam 3 question 5
> Create NetworkPolicy, by the name ingress-to-nptest that allows incoming connections to the service over port 80.
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-to-nptest
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: np-test-1  ### Ensure this label matches your pods' labels
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector: {}  ### Allows traffic from any pod
      ports:
        - protocol: TCP
          port: 80
---
apiVersion: networking.k8s.io/v1 ### and allow dns resolve too
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: default
spec:
  podSelector:
    matchLabels:
      run: debug ### pod from which nslookup is ran
  policyTypes:
    - Egress
  egress:
    - to:
      - ipBlock:
          cidr: 10.96.0.10/32 ### Replace with the DNS service IP
      ports:
      - protocol: UDP
        port: 53
```
### create ingress
```
kubectl create ingress ingress-test --rule="wear.my-online-store.com/wear*=wear-service:80"
```
### pay ingress
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
  name: ingress-app-main
  namespace: app-space
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: video-service
            port:
              number: 8080
        path: /watch
        pathType: Prefix
      - backend:
          service:
            name: wear-service
            port:
              number: 8080
        path: /wear
        pathType: Prefix
```

### steps to install k8s:
- create vm (using vagrant)
- install containerd
- configure cgroup
- install kubeadm & kubelet
- initialize cluster (kubeadm init) on master node
- install CNI
- join worker nodes (kubeadm join)

systemctl status containerd

### create pod with red-only mounted secret
```
apiVersion: v1
kind: Pod
metadata:
  name: secret-1401
  namespace: admin1401
spec:
  containers:
    - name: secret-1401
      image: busybox
      command: 
      - sleep
      - "4800"
      volumeMounts:
      - name: secret-volume
        mountPath: /etc/secret-volume
        readOnly: true
  volumes:
  - name: secret-volume
    secret:
      secretName: dotfile-secret
```