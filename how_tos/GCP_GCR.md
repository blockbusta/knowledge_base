# GCP GCR

read here on how to create a json keyfile for authentication:

[https://cloud.google.com/container-registry/docs/advanced-authentication#json-key](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key)

after json keyfile generated, create the registry in , and provide the details:

**user:**

```python
_json_key
```

**password:**

```python
# content of json file:
cat keyfile.json
```