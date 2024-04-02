#!/bin/bash

### requirements for running this script:
# (1) # python 3.7 or above # https://www.python.org/downloads
# (2) # kubectl # https://kubernetes.io/docs/tasks/tools/#kubectl
# (3) # helm curl # https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# (4) # kubeconfig # export KUBECONFIG=/path/to/kubeconfig
# (5) # define the cluster domain, PYPI server username and protocol (HTTP/S)

### after all requirements are met, save and execute this file:
### CLUSTER_DOMAIN="aks-cicd-21332.cicd.me" PYPI_USERNAME="itayosadm1n0s" PROTOCOL="https" bash deploy_pypi_server.sh

# Checks if any var is empty
variables=("CLUSTER_DOMAIN" "PYPI_USERNAME" "PROTOCOL")
for var in "${variables[@]}"; do
    if [[ -n "${!var}" ]]; then
        echo "$var = ${!var}"
    else
        echo "$var is empty."
        empty=true
    fi
done

# Checks if all vars are populated
if [[ -z $empty ]]; then
    echo "* All variables populated! moving on... *"
else
    echo "* One or more variables are empty :( *"
    exit 1
fi

# check utilities
check_version() {
    local tool_name="$1"
    local version_command="$2"

    if command -v "$tool_name" > /dev/null; then
        echo -n "$tool_name version: "
        $version_command || {
            echo "Error getting $tool_name version."
            exit 1
        }
    else
        echo "$tool_name not found. Please install $tool_name."
        exit 1
    fi
}

check_version "kubectl" "kubectl version --short --client"
check_version "helm" "helm version --short"
check_version "python" "python --version"
echo "All required tools found."

# add helm repo
helm repo add owkin https://owkin.github.io/charts

# create credentials secret
PYPI_PASSWORD=$(echo -n $PYPI_USERNAME | md5sum | cut -c 1-32)
FULL=$PYPI_USERNAME:$PYPI_PASSWORD

mkdir pypi_tmp && cd pypi_tmp
echo $FULL > .htpasswd

kubectl create ns pypi
kubectl -n pypi create secret generic pypi-creds --from-file=.htpasswd

# install pypi server    
helm install -n pypi pypiserver owkin/pypiserver \
--set persistence.enabled=true \
--set persistence.size="3Gi" \
--set pypiserver.extraArgs={"--overwrite"} \
--set auth.existingSecret=pypi-creds \
--set resources.requests.cpu="100m" \
--set resources.requests.memory="100Mi" \
--debug

# expose pypi server using istio VS
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: pypi
  namespace: pypi
spec:
  gateways:
    - istio-gw
  hosts:
    - pypi.$CLUSTER_DOMAIN
  http:
    - retries:
        attempts: 5
        perTryTimeout: 172800s
      route:
        - destination:
            host: pypiserver-pypiserver.pypi.svc.cluster.local
      timeout: 864000s
EOF

# install twine utility (for uploading python packages to server)
pip install twine

# download packages:
pip download --dest . --no-cache-dir \
tensorboard jupyterlab jupyterlab-git gunicorn dash \
dash-daq voila pygments flask pika plumber faust-streaming dataclasses

# upload packages to pypi server
twine upload --repository-url \
$PROTOCOL://pypi.$CLUSTER_DOMAIN \
--username $PYPI_USERNAME --password $PYPI_PASSWORD \
*.whl

cd .. && rm -rf pypi_tmp/
echo "PYPI server is ready!"

# pypi index url will be:
PYPI_INDEX_URL="$PROTOCOL://pypi.$CLUSTER_DOMAIN/simple"
echo "index URL: $PYPI_INDEX_URL"

# use this link to access in browser:
PYPI_INDEX_UI="$PROTOCOL://pypi.$CLUSTER_DOMAIN/packages"
echo "browse WHL folder: $PYPI_INDEX_UI"

echo "username: $PYPI_USERNAME"
echo "password: $PYPI_PASSWORD"