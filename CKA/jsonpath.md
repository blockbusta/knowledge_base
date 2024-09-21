
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
