# GPU utilization stress test

# Single GPU

1) start a workspace with any stock nvidia pytorch image

2) open an IPYNB notebook & run this script:

```bash
import torch

x = torch.linspace(0, 4, 16*1024**2).cuda()

while True:
    x = x * (1.0 - x)
```

**OR** execute this single bash command from terminal:

```bash
nohup python -c '
import torch

x = torch.linspace(0, 4, 16*1024**2).cuda()

while True:
    x = x * (1.0 - x)
' &
```

**OR** run this as an experiment, for stopping after 5min:

```python
import time
import subprocess
import torch

x = torch.linspace(0, 4, 16*1024**2).cuda()
start_time = time.time()

while True:
    x = x * (1.0 - x)
    
    elapsed_time = time.time() - start_time
    if elapsed_time >= 300:
        break
    
    # Print the current time and GPU utilization percentage every 5 seconds
    if elapsed_time % 5 == 0:
        gpu_utilization = int(nvidia_smi_output.decode('utf-8').strip().split('\n')[0].replace(' %', ''))
        print(f"Current time: {time.strftime('%Y-%m-%d %H:%M:%S')}, GPU utilization: {gpu_utilization}%")
        time.sleep(1)
```

3) watch nvidia-smi to monitor:

```bash
watch nvidia-smi
```

**utilization should be at 100%**


# Multiple GPU’s

```bash
git clone https://github.com/wilicc/gpu-burn
cd gpu-burn
make
```

then

```bash
gpu_burn -d 3600
```

<aside>
⚠️ if the `gpu_burn` command isn’t recognized, make sure you’ve added to `PATH`, the output of `make` command should have it printed out, sth like this:

</aside>

```bash
PATH=/usr/local/nvm/versions/node/v16.6.1/bin:/opt/conda/lib/python3.8/site-packages/torch_tensorrt/bin:/opt/conda/bin:/usr/local/mpi/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/ucx/bin:/opt/tensorrt/bin::. /usr/local/cuda/bin/nvcc  -I/usr/local/cuda/include -arch=compute_50 -ptx compare.cu -o compare.ptx
```

then open 2nd terminal in parallel to monitor:

```bash
watch nvidia-smi
```

**all GPU cards utilization should be at 100%**

example:

![Untitled](GPU%20utilization%20stress%20test%20133fac9685cf4c29b54e8f49d0716f8e/Untitled.png)