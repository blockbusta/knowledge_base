# elastic search

get info about job query:

```bash
http://34.219.53.247:9200/data_mangos_staging/data_mango/JOB_ID
```

delete jobs:

```
curl -X DELETE http://172.31.3.46:9200/data_mangos_staging
```

```
curl -X DELETE http://172.31.3.46:9200/data_mangos_app
```

in DB:

```bash
BananaVersion.reindex
```