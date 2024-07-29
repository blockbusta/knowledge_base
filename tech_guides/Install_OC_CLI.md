# Install OC CLI

1. go here: [https://mirror.openshift.com/pub/openshift-v4/clients/ocp](https://mirror.openshift.com/pub/openshift-v4/clients/ocp)

2. navigate to the folder with the server version you have
    
    <aside>
    👉🏻 For this example, we are using `4.12.9` on our ARO env at this moment
    
    </aside>
    
3. then choose the relevant OS version file
    
    **linux**
    
    ```bash
    **openshift-client-linux**-4.12.19.tar.gz
    ```
    
    **macos**
    
    ```bash
    **openshift-client-mac**-4.12.19.tar.gz
    ```
    
    **windows**
    
    ```bash
    **openshift-client-windows**-4.12.19.zip
    ```
    
4. extract the archive and place the executable in one of `$PATH` entries
    
    ```bash
    tar -xzvf **openshift-client-linux**-4.12.19.tar.gz
    mv ./oc /bin
    ```
    
5. run `oc --help` to verify installation is done.