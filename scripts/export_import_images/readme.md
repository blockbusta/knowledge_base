# sending docker images to air-gapped envs



## your side

1. create a list of docker images, save it as `images-full.txt`. for example:

    ```
    docker.io/ubuntu:latest
    docker.io/python:3.9
    docker.io/busybox:latest
    ```
        
2. run the save script: 

    ```bash
    bash save-images.sh
    ```
    this script pulls all images listed in file, then archives them in a `tar.gz`` file.

3. send following files to air-gapped side:
    
    ```bash
    images-full.txt
    images.tar.gz
    load-images.sh
    ```
    

## air-gapped side:

1. retrieve the following files to an empty folder:
    
    ```bash
    images-full.txt
    images.tar.gz
    load-images.sh
    ```
    
2. run the load script, with the target registry provided:
    
    ```bash
    bash load-images.sh -r "my.registry.com:5000/bla"
    ```

    this script loads the archive, re-tags all images to the new destination registry, then pushes them to it.
    for example, using previously provided image list, these images will be pushed:
    ```
    my.registry.com:5000/bla/ubuntu:latest
    my.registry.com:5000/bla/python:3.9
    my.registry.com:5000/bla/busybox:latest
    ```
    
3. verify images were uploaded to the destination registry.

## notes
⛔ to delete all local images:
```bash
docker rmi -f $(docker images -aq)
```
