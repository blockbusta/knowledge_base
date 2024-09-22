> visual aid to better understand queries: https://jsonpath.com/
> point and click to get jpath: https://jsonpathfinder.com/

### get specific items from list:
`data.json`
```json
[
    "car",
    "bus",
    "truck",
    "bike"
]
```

```bash
cat data.json | jpath '$[0,3]'
```

output:
```json
[
  "car",
  "bike"
]
```
### get items from list using a condition:
get first names of directors of movies released in 2014
```
cat data.json | jpath '$.movies[?(@.year == 2014)].directors[*].firstname'
```
break it down:
- `$.movies` in the root, movies element (list of dicts)
- `[?(@.year == 2014)]`
iterate all items in the list, and find the one which its `year` equals to `2014`
- `directors[*].firstname` fetch all `firstname` valuesfrom `directors` dict (for each item that matched previous criterea)

## use JSONPATH in kubectl
simple jpath query:
```bash
jpath '$[0,3]'
```
placed in the kubectl command:
```bash
kubectl get RESOURCE -o jsonpath{'[0,3]'}
```
> the $ sign isn't required here
### get all pod names:
```
kubectl get pod -o jsonpath{'items[*].metadata.name'}
```
### sort PV's by size
```
kubectl get pv --sort-by=.spec.capacity.storage
```
output
```
NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-log-4   40Mi       RWX            Retain           Available                          <unset>                          22m
pv-log-1   100Mi      RWX            Retain           Available                          <unset>                          22m
pv-log-2   200Mi      RWX            Retain           Available                          <unset>                          22m
pv-log-3   300Mi      RWX            Retain           Available                          <unset>                          22m
```
### display a custom table showing only PV name+capacity:

```
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage
```
output
```
NAME       CAPACITY
pv-log-1   100Mi
pv-log-2   200Mi
pv-log-3   300Mi
pv-log-4   40Mi
```

### get the context name, of the context that is using the `aws-user`
```
kubectl config view -o jsonpath={'.contexts[?(@.context.user == "aws-user")].name'}
```

### loop over range & custom formatting:
> add new line using `{"\n"}` between each query
```bash
kubectl get nodes -o=jsonpath='{.items[*].metadata.name}{"\n"}{.items[*].status.capacity.cpu}'
```
output:
```
master node01
4 4
```



k -n admin2406 get deploy --sort-by=.metadata.name -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[0].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace