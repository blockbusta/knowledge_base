# Data performance becnhmark

install fio

```json
apt-get update -y && apt-get install -y fio
```

create test config

```
[write_test]
rw=write
size=1G
directory=/path/to/directory
filename=testfile
```

You can then run the test with:

```bash
fio my_test_conf.fio
```

example results:

```json
write_test: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=psync, iodepth=1
fio-3.25
Starting 1 process
write_test: Laying out IO file (1 file / 30720MiB)
Jobs: 1 (f=1): [W(1)][100.0%][eta 00m:00s]                           
write_test: (groupid=0, jobs=1): err= 0: pid=679: Wed Sep 20 12:17:35 2023
  write: IOPS=21.3k, BW=83.3MiB/s (87.4MB/s)(30.0GiB/368672msec); 0 zone resets
    clat (usec): min=2, max=9700.0k, avg=46.57, stdev=7916.61
     lat (usec): min=2, max=9700.0k, avg=46.62, stdev=7916.61
    clat percentiles (usec):
     |  1.00th=[    3],  5.00th=[    3], 10.00th=[    4], 20.00th=[    4],
     | 30.00th=[    4], 40.00th=[    4], 50.00th=[    4], 60.00th=[    5],
     | 70.00th=[    5], 80.00th=[    7], 90.00th=[   10], 95.00th=[   11],
     | 99.00th=[   61], 99.50th=[   87], 99.90th=[  198], 99.95th=[  247],
     | 99.99th=[35390]
   bw (  KiB/s): min=    8, max=1150400, per=100.00%, avg=117474.98, stdev=138811.74, samples=536
   iops        : min=    2, max=287600, avg=29368.57, stdev=34702.95, samples=536
  lat (usec)   : 4=59.20%, 10=35.47%, 20=2.97%, 50=1.15%, 100=0.81%
  lat (usec)   : 250=0.35%, 500=0.02%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2000=0.01%, >=2000=0.01%
  cpu          : usr=1.98%, sys=12.38%, ctx=16977, majf=1, minf=39
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,7864320,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=83.3MiB/s (87.4MB/s), 83.3MiB/s-83.3MiB/s (87.4MB/s-87.4MB/s), io=30.0GiB (32.2GB), run=368672-368672msec

Disk stats (read/write):
  rbd0: ios=4/8906, merge=0/11959, ticks=9/30220865, in_queue=30203148, util=99.47%
```

**docker image pull:**

1.2 GB image in 20 seconds =

```json
60.8 MB/s
```