# PyPi python packages server

<aside>
🔥 **we now have this end-to-end script that does it all:**
[https://github.com/Samba/Brazilero/blob/main/scripts/deploy_pypi_server.sh](https://github.com/Samba/Brazilero/blob/main/scripts/deploy_pypi_server.sh)

</aside>

1. add helm repo
    
    ```bash
    helm repo add owkin https://owkin.github.io/charts
    ```
    
2. create credentials and secret
    
    ```bash
    PYPI_USERNAME="jacksonadmin"
    PYPI_PASSWORD=$(echo -n $PYPI_USERNAME | md5sum | cut -c 1-32)
    FULL=$PYPI_USERNAME:$PYPI_PASSWORD
    
    echo $PYPI_USERNAME
    echo $PYPI_PASSWORD
    
    echo $FULL > .htpasswd
    
    kubectl create ns pypi
    kubectl -n pypi create secret generic pypi-creds --from-file=.htpasswd
    ```
    
3. install
    
    ```bash
    helm install -n pypi pypiserver owkin/pypiserver \
    --set persistence.enabled=true \
    --set pypiserver.extraArgs={"--overwrite"} \
    --set auth.existingSecret=pypi-creds \
    --debug
    ```
    
4. create virtualservice to expose
    
    ```bash
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: pypi
      namespace: lolz
    spec:
      gateways:
        - istio-gw-lolz
      hosts:
        - pypi.aks-rofl17212.cicd.ginger.cn
      http:
        - retries:
            attempts: 5
            perTryTimeout: 172800s
          route:
            - destination:
                host: pypiserver-pypiserver.pypi.svc.cluster.local
          timeout: 864000s
    ```
    

the pypi index url will be:

```bash
http://pypi.aks-rofl17212.cicd.ginger.cn/simple
```

and the WHL files will be stored in:

```bash
http://pypi.aks-rofl17212.cicd.ginger.cn/packages
```

## Upload python packages to server

install twine

```bash
pip install twine
```

to download pip packages locally

```bash
pip download --dest . tesnorboard # add --no-deps to prevent dependencies
```

upload packages to your pypi server

```bash
twine upload --repository-url \
http://pypi.aks-rofl17212.cicd.ginger.cn \
--username $PYPI_USERNAME --password $PYPI_PASSWORD \
/path/to/my_package-1.0.0-py3-none-any.whl # or *.whl for batch
```

<aside>
⚠️ by default, only uploading to the server requires authentication.
listing and downloading are open for all.

</aside>

### Delete package from pypi server

```ruby
curl --form ":action=remove_pkg"  --form "name=<package>" --form "version=<version>"  https://<pypi-server-url>
```