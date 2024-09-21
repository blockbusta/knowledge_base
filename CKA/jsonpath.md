
### get specific items from list:
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
## use JSONPATH in kubectl
### get all pod names:
```
kubectl get pods -o jsonpath{'items[*].metadata.name'}
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
