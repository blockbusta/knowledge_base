To check the read/write speed of a hard drive in Linux, you can use several methods. Here are some commonly used tools:

### 1. **Using `hdparm`**
This is a straightforward method but mainly tests cached read speeds:
```bash
sudo hdparm -Tt /dev/sdX
```
- Replace `/dev/sdX` with your drive (e.g., `/dev/sda`).
- `-T` tests cached reads.
- `-t` tests direct reads.

### 2. **Using `dd` Command**
This method uses file-based tests and can give a better indication of actual write/read performance:
```bash
# Write speed test
sudo dd if=/dev/zero of=/mnt/testfile bs=1G count=1 oflag=direct
# Read speed test
sudo dd if=/mnt/testfile of=/dev/null bs=1G count=1 iflag=direct
```
- `bs=1G` sets the block size to 1 GB, and `count=1` writes/reads just one block of this size.
- `oflag=direct` and `iflag=direct` bypass cache for a more accurate measurement.

**Note**: Remember to delete the test file after the test:
```bash
sudo rm /mnt/testfile
```

### 3. **Using `fio`**
For a more comprehensive and configurable benchmark:
```bash
sudo apt install fio
fio --name=randwrite --ioengine=libaio --rw=randwrite --bs=4k --size=1G --numjobs=4 --runtime=60 --group_reporting
```
- This command tests random write speed using 4KB block size for 60 seconds.

### 4. **Using `ioping`**
This tool tests the I/O latency and speed:
```bash
sudo apt install ioping
ioping -c 10 /mnt/zata
```
- `-c 10` will run 10 tests on the specified mount point.

These tools provide good insights into the drive's performance. For real-time data, you can use `iostat`:
```bash
sudo apt install sysstat
iostat -d /dev/sdX 1
```
- This shows disk statistics every second.