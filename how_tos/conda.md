# conda

stock image with jupyter + pre-activated conda env (works with both **jupyter** & **vscode**)

```bash
jupyter/base-notebook:latest
```

## install conda on-the-fly

### download conda installation
```bash
cd /data && wget "https://repo.anaconda.com/archive/Anaconda3-2020.11-Linux-x86_64.sh"
```
### install conda
```bash
sudo chmod +x /data/Anaconda3-2020.11-Linux-x86_64.sh
bash /data/Anaconda3-2020.11-Linux-x86_64.sh -b -p
```
### initiate conda in bash
```bash
echo 'source /root/anaconda3/etc/profile.d/conda.sh 2> /dev/null' >> ~/.bashrc
echo 'conda create -n my_cool_env -y' >> ~/.bashrc
echo 'conda activate my_cool_env' >> ~/.bashrc
```

## notes

if the image is initiated with `/bin/sh` add this env var to change to shell to bash:

```bash
SHELL=/bin/bash
```