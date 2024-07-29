# OKD open-source OCP

[https://www.okd.io/installation/](https://www.okd.io/installation/)

# Installation

the preferred option is IPI.

- **IPI (**Installer-provisioned infrastructure)
    
    For clusters with **installer-provisioned infrastructure**, you delegate the infrastructure bootstrapping and provisioning to the installation program instead of doing it yourself. The installation program creates all of the networking, machines, and operating systems that are required to support the cluster.
    
- **UPI** (User-provisioned infrastructure)
    
    If you provision and manage the infrastructure for your cluster, you must provide all of the cluster infrastructure and resources, including the bootstrap machine, networking, load balancing, storage, and individual cluster machines.
    

# IPI using AWS

**AWS resources that installer provisions:**

[https://www.okd.io/guides/aws-ipi/](https://www.okd.io/guides/aws-ipi/)

**Configure AWS prior to installation:**

[https://docs.okd.io/latest/installing/installing_aws/installing-aws-account.html](https://docs.okd.io/latest/installing/installing_aws/installing-aws-account.html)

**OKD installation steps on AWS:**

[https://docs.okd.io/latest/installing/installing_aws/installing-aws-default.html](https://docs.okd.io/latest/installing/installing_aws/installing-aws-default.html)

verify you are logged in to aws cli and that youre creds file is populated:

```bash
cat ~/.aws/credentials
```

download the `openshift-install` tar.gz archive for the OS your’e running on, extract files:

```bash
tar -xf openshift-install*.tar
```

create the installation config in current dir:

```bash
./openshift-install create install-config --dir=.
```

edit and patch the config file as needed:

```bash
vim install-config.yaml
```

<aside>
⚠️ if using temporary AWS credentials, add this to the manifest:
`credentialsMode: Manual`

</aside>

install cluster:

```bash
./openshift-install create cluster --dir=. --log-level=info
```

How to create a install config file for install

```bash
./openshift-install create install-config --dir .
```

Example of output

```bash
cat install-config.yaml
additionalTrustBundlePolicy: Proxyonly
apiVersion: v1
baseDomain: apps.beer.co.uk
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: dud3-okd
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-east-2
```

# UPI on bare metal

[https://docs.okd.io/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html](https://docs.okd.io/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html)

# OKD on GCP

Prereqs:

- You need access to a serviceaccount json file.
    
    The service account will need permissions to DNS, Compute and the ability to create service accounts for the installation. I created a osd SA in GCP you can use. Shown below.
    
    
- You will also need a predefined DNS zoned which can be used for the install. For example here is my zone in GCP DNS.


- You will need an OpenShift account with red hat to get a pull secret for the install. [https://console.redhat.com/openshift](https://console.redhat.com/openshift)
- Download the openshift-installer from the Redhat console under DOWNLOADS or view the releases page to download a specific version of OCP/K8s.

```bash
https://github.com/okd-project/okd/releases
```

Use the following service account in GCP for cluster creation.

```bash
osd-ccs-admin@developmentlolz.iam.gserviceaccount.com
```

You can generate a key and download the .json file for the SA which you will use later during installation.

You can create the cluster configuration file ahead of time in case you want to modify number of instances, ect.

```bash
./openshift-install create install-config --dir .
```

This will prompt for your rsa public key, dns zone, compute region, service account json file and the name of the OCP cluster.

```bash
./openshift-install create install-config
? SSH Public Key /home/.ssh/id_rsa.pub
? Platform gcp
INFO Credentials loaded from file "/home/.gcp/osServiceAccount.json"
? Project ID lolz-dev (developmentlolz)
? Region us-east1
? Base Domain ocp.dud3.net
? Cluster Name dud3-okd
? Pull Secret [? for help] ********************************************************************************
INFO Install-Config created in: .
```

Example of my config file without the certs and secret

```bash
cat install-config.yaml
additionalTrustBundlePolicy: Proxyonly
apiVersion: v1
baseDomain: ocp.dud3.net
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 1
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 1
metadata:
  creationTimestamp: null
  name: dud3-okd
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  gcp:
    projectID: developmentlolz
    region: us-central1
```

Once the configuration file is built simply run install. Make sure your in the directory that contains the install-config file, or use the “dir” flag to point to the location.

```bash
./openshift-install create cluster --dir=. --log-level=debug
```

Enable scheduling on Master Nodes after install.

```bash
oc edit schedulers.config.openshift.io cluster
```

Openshift install releases. To deploy older versions than 4.13.

```bash
https://github.com/okd-project/okd/releases
```

To delete and clean up cluster:

```bash
./openshift destroy cluster
```

To update the cluster using the oc cli tool. You can view the status in the console or use the `oc adm upgrade` cli command.

```jsx
oc adm upgrade --to=4.13.0-0.okd-2023-05-22-052007 --force
```

To add an unsupported release. 

```jsx
oc adm upgrade channel stable-4.14;
oc adm upgrade --to-latest=true
```

You can get specific image info with the following command:

```jsx
oc adm release info 4.14.7 --pullspecs
```

If you want to use that image to upgrade to run:

```jsx
oc adm upgrade --to-image=quay.io/openshift-release-dev/ocp-release@sha256:a346fc0c84644e64c726013a98bef0f75e58f246fce1faa83fb6bbbc6d4050aa --allow-explicit-upgrade
```

## Troubleshooting / Notes

Current User Permissions - Being migrated to new Service Account



![Untitled](OKD%20open-source%20OCP%20ace86a6a20ce4436bd3bcc3fb2e7cfc8/Untitled%204.png)