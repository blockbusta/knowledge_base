# kibana

# dev tools

click on 3 stripes button ("burger") → **Dev Tools**

check index size:

```python
GET /_cat/indices
```

delete index:

```python
DELETE /<index_name>
```

### get app pod logs:

add filter:

→ field: `pod_name`

→ operator: **is**

→ value: `*app*`

![kibana%20516b8a492fc048c4aa39f5282ca97d8d/Untitled.png](kibana%20516b8a492fc048c4aa39f5282ca97d8d/Untitled.png)