# stress test for memory + CPU

install:

```yaml
apt-get update && apt-get install stress-ng -y
```

CPU stress:

```bash
stress-ng --cpu $(nproc) --metrics-brief &
```

memory stress:

```python
stress-ng --vm 1 --vm-bytes 95% --vm-method all --verify -t 10m -v &
```