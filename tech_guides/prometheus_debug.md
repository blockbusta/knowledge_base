# prometheus debug

### case: node-exporter targets are down

a rare occurrence, only witnessed twice (Dell, on-premise environment)


change the `hostNetwork` to `false`, in node-exporter daemonset:

```ruby
prometheus-node-exporter:
  hostNetwork: false
```