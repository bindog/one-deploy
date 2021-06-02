files from here: https://github.com/AliyunContainerService/gpushare-scheduler-extender/blob/master/docs/install.md

but there may be bind error, 500

so we should build our own images from:

- https://github.com/k8s-gpushare/gpushare-scheduler-extender
- https://github.com/k8s-gpushare/gpushare-device-plugin

1. gpushare-scheduler-extender

```bash
docker build -t gpushare-scheduler-extender:may .
```

2. gpushare-device-plugin

```bash
# remove line 70 in file pkg/gpu/nvidia/nvidia.go: statu, err := d.Status()
docker build -t gpushare-plugin:may .
```
