# aptly linux packages server

<aside>
💡 **official link**: [https://www.aptly.info/download/](https://www.aptly.info/download/)
**air-gapped tutorial**: [https://www.youtube.com/watch?v=rZsJZ_1vX3o](https://www.youtube.com/watch?v=rZsJZ_1vX3o)

</aside>

**download and install:**

```bash
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A0546A43624A8331
wget -qO - https://www.aptly.info/pubkey.txt | sudo apt-key add -
apt-get update
apt-get install aptly -y
```

**mirror existing repository:**

*mirror = a link to an existing repository. this step does not download any package.*

```bash
aptly mirror create <name> <archive url> <distribution> [<component1> ...]
```

[https://www.aptly.info/doc/aptly/mirror/create/](https://www.aptly.info/doc/aptly/mirror/create/)

```bash
aptly mirror create \
-filter="python3-h5py" \
-filter-with-deps \
-with-installer \
-with-sources \
debian-main \
http://deb.debian.org/debian \
pool main
```

```bash
root@network-debugger:/# apt-get --print-uris --yes install python3-h5py
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libaec0 libblas3 libgfortran5 libhdf5-103-1 libhdf5-hl-100 liblapack3 libsz2 python3-h5py-serial
  python3-numpy python3-pkg-resources
Suggested packages:
  python-h5py-doc gfortran python3-dev python3-pytest python3-setuptools
The following NEW packages will be installed:
  libaec0 libblas3 libgfortran5 libhdf5-103-1 libhdf5-hl-100 liblapack3 libsz2 python3-h5py
  python3-h5py-serial python3-numpy python3-pkg-resources
0 upgraded, 11 newly installed, 0 to remove and 54 not upgraded.
Need to get 10.9 MB of archives.
After this operation, 48.6 MB of additional disk space will be used.
'http://deb.debian.org/debian/pool/main/liba/libaec/libaec0_1.0.6-1%2bb1_amd64.deb' libaec0_1.0.6-1+b1_amd64.deb 21144 MD5Sum:42611bf8032dad2d74c26d8dc084d322
'http://deb.debian.org/debian/pool/main/l/lapack/libblas3_3.11.0-2_amd64.deb' libblas3_3.11.0-2_amd64.deb 148592 MD5Sum:b39744800600a80ae852251a16c03d09
'http://deb.debian.org/debian/pool/main/g/gcc-12/libgfortran5_12.2.0-14_amd64.deb' libgfortran5_12.2.0-14_amd64.deb 792504 MD5Sum:88d98d0096bbfcc0763a2e4426e5ca92
'http://deb.debian.org/debian/pool/main/liba/libaec/libsz2_1.0.6-1%2bb1_amd64.deb' libsz2_1.0.6-1+b1_amd64.deb 7804 MD5Sum:6ab72da8580d02d7cb0d8c968fc83c36
'http://deb.debian.org/debian/pool/main/h/hdf5/libhdf5-103-1_1.10.8%2brepack1-1_amd64.deb' libhdf5-103-1_1.10.8+repack1-1_amd64.deb 1236980 MD5Sum:99fa047a59160d481d5c8623e66d5b5b
'http://deb.debian.org/debian/pool/main/h/hdf5/libhdf5-hl-100_1.10.8%2brepack1-1_amd64.deb' libhdf5-hl-100_1.10.8+repack1-1_amd64.deb 67788 MD5Sum:16fd3bf27d8e53d8f65f5fe2b4585dbb
'http://deb.debian.org/debian/pool/main/l/lapack/liblapack3_3.11.0-2_amd64.deb' liblapack3_3.11.0-2_amd64.deb 2322744 MD5Sum:9f13955c7feaec22a05d6491c3bc2730
'http://deb.debian.org/debian/pool/main/s/setuptools/python3-pkg-resources_66.1.1-1_all.deb' python3-pkg-resources_66.1.1-1_all.deb 296344 MD5Sum:77d4f3bebb451c0933e9959a5f4778f6
'http://deb.debian.org/debian/pool/main/n/numpy/python3-numpy_1.24.2-1_amd64.deb' python3-numpy_1%3a1.24.2-1_amd64.deb 5208968 MD5Sum:89fc714778dbb2290a0e7d1d34ea69fc
'http://deb.debian.org/debian/pool/main/h/h5py/python3-h5py-serial_3.7.0-8_amd64.deb' python3-h5py-serial_3.7.0-8_amd64.deb 803984 MD5Sum:579a9bb18f58c33793bfd69f40a3dea7
'http://deb.debian.org/debian/pool/main/h/h5py/python3-h5py_3.7.0-8_all.deb' python3-h5py_3.7.0-8_all.deb 10324 MD5Sum:8158d1d7e9d1356f1a7c8ac68b76badd
```

```bash
Success downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-arm64/Packages.gz
Downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-armel/Packages.gz...
Success downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-armel/Packages.gz
Downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-armhf/Packages.gz...
Success downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-armhf/Packages.gz
Downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-i386/Packages.gz...
Success downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-i386/Packages.gz
Downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-mips64el/Packages.gz...
Success downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-mips64el/Packages.gz
Downloading http://ftp.debian.org/debian/dists/bullseye/non-free/binary-mipsel/Packages.gz...
```

```bash
aptly mirror create \
-filter="nginx" \
-filter-with-deps \
wheezy-required \
http://mirror.yandex.ru/debian/ \
wheezy main
```

**list existing mirrors:**

```bash
aptly mirror list
```

describe mirror and how many packages it includes:

```bash
aptly mirror show <name>
```

**download packages:**

*this will fetch any packages from that mirror, that don’t exist locally. you can run this each time to make sure your local repo us updated with the remote.*

```bash
aptly mirror update <name>
```

**publish:**

```bash
...
```

**start server:**

```bash
aptly serve -listen=:8080
```

service:

```bash
kind: Service
apiVersion: v1
metadata:
  name: test-zone
  namespace: lolz
  uid: 23a8e901-9431-4f3e-860c-ca53e830bd9a
  resourceVersion: '187083356'
  creationTimestamp: '2024-03-02T21:48:35Z'
  managedFields:
    - manager: Mozilla
      operation: Update
      apiVersion: v1
      time: '2024-03-02T21:48:35Z'
      fieldsType: FieldsV1
      fieldsV1:
        'f:spec':
          'f:internalTrafficPolicy': {}
          'f:ports':
            .: {}
            'k:{"port":80,"protocol":"TCP"}':
              .: {}
              'f:port': {}
              'f:protocol': {}
              'f:targetPort': {}
          'f:selector': {}
          'f:sessionAffinity': {}
          'f:type': {}
spec:
  clusterIP: 172.30.157.191
  ipFamilies:
    - IPv4
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  internalTrafficPolicy: Cluster
  clusterIPs:
    - 172.30.157.191
  type: ClusterIP
  ipFamilyPolicy: SingleStack
  sessionAffinity: None
  selector:
    app: test-zone
status:
  loadBalancer: {}

```