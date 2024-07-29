# Elasticsearch Cleanup Policy

The following guide follow the procedure of creating a cleanup policy for lolz index in Elasticsearch

## A) Debugging Elasticsearch

Using Kubectl command we need to check if Elasticsearch has disk pressure when Elasticsearch is under disk pressure it will mark all his indices as “read-only” if it passes 5%. in order to check this search elasticsearch-0 pod using the log command for the example output line:

```bash
kubectl -n lolz logs elasticsearch-0
```

Example [Warn] message indicating on a disk pressure:

```bash

[DiskThresholdMonitor] [elasticsearch-0] high disk watermark [90%] exceeded on [UPg75WpGT1mEEseJfB2f8g][elasticsearch-0][/usr/share/elasticsearch/data/data/nodes/0] free: 19.1gb[4.8%], shards will be relocated away from this node; currently relocating away shards totalling [0] bytes; the node is expected to continue to exceed the high disk watermark when these relocations are complete
```

If the log is full with the above warning messages continue to section (B), else skip to (C).

## B)  Enable write request to Elasticsearch

If elastic has entered read-only mode, we can revert it using the following commands:

```elm
curl -XPUT -u  "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" -H "Content-Type: application/json" http://localhost:9200/_cluster/settings -d '{ "transient": { "cluster.routing.allocation.disk.threshold_enabled": false } }'

curl -XPUT -u  "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
```

for using kibana dev tools, run this:

```jsx
PUT _cluster/settings
{
  "transient": {
    "cluster.routing.allocation.disk.threshold_enabled": false
  }
}
```

```jsx
PUT _all/_settings
{
  "index.blocks.read_only_allow_delete": null
}
```

Expected outputs:

```bash
# **1st command**: 

{"acknowledged":true,"persistent":{},"transient":{"cluster":{"routing":{"allocation":{"disk":{"threshold_enabled":"false"}}}}}}

# **2nd command**: 

{"acknowledged":true}
```

## C) Creating a cleanup policy in Kibana

Enter Kibana UI and navigate to “Dev Tools” and use the Console for the following steps:

First, we will create the policy, you can change the age of the logs by specifying “min_age”:

```bash
PUT _ilm/policy/cleanup-history
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {}
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

Second, assign the policy to the lolz index:

```bash
PUT /lolz/_settings?pretty
{
  "lifecycle.name": "cleanup-history"
}
```

Monitor the status of elastic using the following GET using the Console:

```bash
GET _cat/indices
```

Example output:

```bash
yellow open elastalert_status_status             yESK7s41RZ68lBa0izqLEA 1 1      0    0    208b    208b
yellow open elastalert_status                    PU1hgQGESEu5rUATYoX2Ng 1 1      0    0    208b    208b
yellow open lolz                                c1vorpO3TRqGcs1oUXCJVw 1 1 949055    0 218.9mb 218.9mb
yellow open elastalert_status_past               B2HNGgzfTeOSHETleZP_Ew 1 1      0    0    208b    208b
yellow open elastalert_status_silence            8lMH-JudTyCFoo4Fupdx2w 1 1      0    0    208b    208b
yellow open data_mangos_20210202153627437 sZ7DIKu9ScqoW-92ySr7Jg 1 1   7149 1113  17.3mb  17.3mb
yellow open elastalert_status_error              tJ8G9CRuQeaoE3ZifxdGug 1 1      0    0    208b    208b
green  open .kibana_1                            rWV3bomhRkKa46xbF95tXA 1 0    441   62   129kb   129kb
green  open .tasks                               sS-c63sBTBCf2NsqnAhlvA 1 0      6    0  86.1kb  86.1kb
```

you should see the **lolz** index size got reduced dramatically.

## Done!

# Delete/Remove log rotation policy from customer

Delete the cleanup policy:

```bash
DELETE _ilm/policy/cleanup-history
```

Enable dis threshold:

```bash
PUT _cluster/settings
{
  "transient": {
    "cluster.routing.allocation.disk.threshold_enabled": true
  }
}
```