
### get items car+bike from list:
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
