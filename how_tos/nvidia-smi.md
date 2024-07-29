# nvidia-smi

```bash
nvidia-smi --query-gpu=utilization.gpu,utilization.memory --format=csv
```

A command line utility tool, which monitors and manages NVIDIA GPUs such as Tesla, Quadro, GRID and GeForce. It is installed along with CUDA toolkit and provides you meaningful insights.

Example output of nvidia-smi:


Two tables are generated as the output where first reflects the information about all available GPUs (above example states 1 GPU). Second table tells you about the processes using GPUs.

Let’s go one by one.

# **Table I**



***Temp:*** Core GPU temperature is in degrees Celsius. We need not to worry about it since it will be controlled by AWS datacentres except to care about your hardware. The above “44C” in table shown is normal but give a call when it reaches 90+ C.

***Perf:*** Denotes GPU’s current performance state. It ranges from P0 to P12 referring to maximum and minimum performance respectively.

***Persistence-M:*** The value of Persistence Mode flag where “On” means that no NVIDIA driver will remain loaded(persist) even when no active client such as nvidia-smi is running. This reduces thedriver load latency with dependent apps such as CUDA programs.

***Pwr:Usage/Cap:** It refers* to the GPU’s current power usage out of total power capacity. *It s*amples in Watts.

***Bus-Id:*** GPU’s PCI bus id as “domain:bus:device.function”, in hex format which is used to filter out the stats of particular device.

***Disp.A**:* Display Active is a flag which decides if you want to allocate memory on GPU device for display i.e. to initialize the display on GPU. Here, “Off” indicates that there isn’t any display using GPU device.

***Memory-Usage:*** Denotes the memory allocation on GPU out of total memory. Tensorflow or Keras(tensorflow backend) automatically allocates whole memory when getting launched, even though it doesn’t require. Hence, have a glance on [GPU on Keras and Tensorflow](https://medium.com/@shachikaul35/gpu-on-keras-and-tensorflow-357d629fb7e2) targeting its solution with more interesting information.

***Volatile Uncorr. ECC:*** ECC stands for Error Correction Code which verifies data transmission by locating and correcting transmission errors. NVIDIA GPUs provides error count of ECC errors. Here, Volatile error counter detect error count since last driver loaded.

***GPU-Util:*** It indicates the percent of GPU utilization i.e. percent of time when kernels were using GPU. *For instance*, output in table above shown 13% of the time. In case of low percent, GPU was under-utilised when if code spends time in reading data from disk (mini-batches).

***Compute M.***: Compute Mode of specific GPU refers to the shared access mode where compute mode sets to default after each reboot. “Default” value allows multiple clients to access CPU at a same time

# **Table II**


***GPU:*** Indicates the GPU index, beneficial for multi-gpu setup. This determine that which process is utilizing which GPU. This index represents NVML Index of the device.

**PID:** Refers to the process by its ID using GPU.

***Type**:* Refers to the type of process such as “C” (Compute), “G” (Graphics) and “C+G” (Compute and Graphics context).

***Process Name:*** Self-explanatory

**GPU Memory Usage:** Memory of specific GPU utilized by each process.

*Other metrics and detailed description is stated in nvidia-smi manual page.*