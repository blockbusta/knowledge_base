# test new VScode version

## Pre-requisites

- CICD env
- A running VScode workspace (small template, v5 image)
- New VScode binary version to test
- New VScode extensions versions to test

1. Obtain the VSCode binary:
    
    [https://github.com/cdr/code-server/releases/](https://github.com/cdr/code-server/releases/)
    
    click on **Assets** & grab the link with `linux-amd64.tar.gz` suffix
    

1. Obtain the VSCode extensions:
    
    <aside>
    ✅ **OpenVSX extension marketplace** [https://open-vsx.org/](https://open-vsx.org/)
    in-use since version `3.12`
    
    **python**: [https://open-vsx.org/extension/ms-python/python](https://open-vsx.org/extension/ms-python/python)
    
    **jupyter**: [https://open-vsx.org/extension/ms-toolsai/jupyter](https://open-vsx.org/extension/ms-toolsai/jupyter)
    
    **gitlens**: [https://open-vsx.org/extension/eamodio/gitlens](https://open-vsx.org/extension/eamodio/gitlens)
    
    </aside>
    
    <aside>
    ℹ️ keep in mind that the **extensions** and the **binary** have to match.
    while there is no exact way of checking it prior to installation, in case an extension version won’t match the binary, its installation process will fail and an appropriate error will be displayed. if so, grab an earlier version and try again.
    
    </aside>
    
    <aside>
    👉🏻 **official microsoft extension marketplace:** 
    [https://marketplace.visualstudio.com/vscode](https://marketplace.visualstudio.com/vscode)
    
    **python extension github:**
    [https://github.com/microsoft/vscode-python/releases](https://github.com/microsoft/vscode-python/releases)
    
    **jupyter extension github:**
    [https://github.com/microsoft/vscode-jupyter/releases](https://github.com/microsoft/vscode-jupyter/releases)
    
    **gitlens extension github:**
    [https://github.com/eamodio/vscode-gitlens/releases](https://github.com/eamodio/vscode-gitlens/releases)
    
    </aside>
    

## 1st test - manual:

1. exec into the main container of the running VScode workspace pod:
    
    ```bash
    k exec -it **POD** -c main -- bash
    ```
    

1. replace placeholder links with new versions of vscode and each extension:
    
    ```bash
    VSCODE_LINK=https://vscode.com/code-server-linux-amd64.tar.gz
    MSPYTHON_LINK=https://vscode.com/ms-python.python.vsix
    JUPYTER_LINK=https://vscode.com/ms-toolsai.jupyter.vsix
    GITLENS_LINK=https://vscode.com/eamodio.gitlens.vsix
    ```
    
    ```bash
    VSCODE_LINK=https://github.com/coder/code-server/releases/download/v4.15.0/code-server-4.15.0-linux-amd64.tar.gz
    MSPYTHON_LINK=https://open-vsx.org/api/ms-python/python/2023.12.0/file/ms-python.python-2023.12.0.vsix
    JUPYTER_LINK=https://open-vsx.org/api/ms-toolsai/jupyter/2023.4.1001091014/file/ms-toolsai.jupyter-2023.4.1001091014.vsix
    GITLENS_LINK=https://open-vsx.org/api/eamodio/gitlens/14.0.1/file/eamodio.gitlens-14.0.1.vsix
    ```
    

1. run the following in the vscode workspace main container to launch the new version:
    
    ```bash
    kill -9 $(ps -ef | grep code-server | head -1 | awk '{ print $2 }')
    
    rm -rf /conf/code-server*
    rm -rf /conf/*.vsix
    
    wget -O /conf/vscode.tar.gz $VSCODE_LINK
    cd /conf && tar -xvzf vscode.tar.gz
    
    wget -O /conf/ms-python.vsix $MSPYTHON_LINK
    wget -O /conf/jupyter.vsix $JUPYTER_LINK
    wget -O /conf/gitlens.vsix $GITLENS_LINK
    
    cd /conf/code-server* && \
    ./bin/code-server --install-extension /conf/ms-python.vsix && \
    ./bin/code-server --install-extension /conf/jupyter.vsix && \
    ./bin/code-server --install-extension /conf/gitlens.vsix
    ```
    

1. launch VScode process in background
    
    ```bash
    nohup bin/code-server /my_workdir --auth none --user-data-dir /conf/.code-server &
    ```
    

1. head over to the workspace page and refresh it, wait for the new VScode UI to load. 

1. **test the following cases:**
    - verify the new version by clicking **help**→**about** in the toolbar
    - run `*.py` file from debugger (i.e click the “play” button ▶️)
    - upload files to file explorer using drag and drop
    - download files from file explorer (right click→download)
    - open `*.ipynb` jupyter notebook
    - open bash terminal and run some echo command
    - test the gitlens extension connectivity to git (by running in git integrated project)

5. deploy image to CICD env
6. run a new VScode workspace
7. check the test cases again

# finalizing after both tests were successful

<aside>
🚧 WARNING ⚠️ this step interferes with production resources
**perform this step only after 2 previous tests were 100% successful!**

</aside>

1. upload the files to the main production bucket:
    
    [https://s3.console.aws.amazon.com/s3/buckets/public](https://s3.console.aws.amazon.com/s3/buckets/public?region=us-west-2&tab=objects)
    
    make sure you keep the **exact** file names, else they won’t be installed!
    
    ```ruby
    gitlens.vsix
    jupyter.vsix
    ms-python-release.vsix
    vscode.tar.gz
    ```
    

1. build new image from master branch and deploy it to CICD
2. create new VScode workspace
3. verify you are on new version, run test cases again for the last time

# notes

### test VScode setup commands as is:

1. define app url:
    
    ```bash
    CICD_APP_URL="http://app.aks-rofl20428.cicd.webapp.me"
    ```
    
2. download and extract binary and extensions:
    
    ```bash
    cd /conf && \
    if [ -d 'code-server'* ]; then exit 0; fi && \
    wget --no-check-certificate $CICD_APP_URL/vscode.tar.gz && \
    wget --no-check-certificate $CICD_APP_URL/gitlens.vsix && \
    wget --no-check-certificate $CICD_APP_URL/ms-python-release.vsix && \
    wget --no-check-certificate $CICD_APP_URL/jupyter.vsix && \
    tar -xvzf vscode.tar.gz && \
    rm vscode.tar.gz
    ```
    
3. install binary and extensions:
    
    ```bash
    cd /conf && cd code-server* && \
    mkdir -p /root/.local/share/code-server && \
    if [ -d 'root' ]; then cp -r root/.local/share/code-server/extensions/ /root/.local/share/code-server && rm -rf root; fi && \
    if [ -d '/conf/.code-server/extensions' ]; then echo 'ext dir exists'; else mkdir -p /conf/.code-server/extensions; fi && \
    ./bin/code-server --disable-telemetry --install-extension /conf/gitlens.vsix --extensions-dir /conf/.code-server/extensions && \
    ./bin/code-server --disable-telemetry --install-extension /conf/ms-python-release.vsix --extensions-dir /conf/.code-server/extensions && \
    ./bin/code-server --disable-telemetry --install-extension /conf/jupyter.vsix --extensions-dir /conf/.code-server/extensions
    ```
    
4. launch code server:
    
    ```bash
    cd /conf/code-server* && \
    bin/code-server /my_workdir --auth none --user-data-dir /conf/.code-server
    ```