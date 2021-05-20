# 镜像构建

这里所需要用到的镜像分为两类，一类是AI推理服务需要用到的镜像，另一类是服务注册&自动发现&负载均衡集群所需要的镜像

**注意：构建镜像过程中可能出现速度缓慢，甚至无法访问国外域名等情况，你可以：**
- 自行准备拥有魔法的机器，构建完把镜像拷贝回来
- 自行准备拥有魔法的代理，在执行build时通过`--build-arg "HTTP_PROXY=http://xxxx:xx" --build-arg "HTTPS_PROXY=http://xxxx:xx"`注入代理

# 构建推理服务镜像

```shell
git clone https://github.com/bindog/one-deploy.git
cd one-deploy/image-build
# 假设已经编译了cortex可执行文件
cp -r ~/cortex/pkg .
# 构建cpu推理镜像
docker build . -f images/python-predictor-cpu/Dockerfile -t cortexlabs/python-predictor-cpu:0.25.0
# 其他镜像同理
```

# 构建集群所需要镜像

这里涉及的镜像有三个，一个是支持多种网络的服务注册镜像`registrator`，另外两个是负载均衡所需镜像(触发式自动刷新配置)

1. registrator镜像

```shell
git clone https://github.com/bindog/registrator.git
cd registrator
docker build . -f Dockerfile -t gliderlabs/registrator:multinetwork
```

2. 负载均衡镜像

```shell
cd one-deploy/srd
docker build ./load_balancing_nginx -t load_balancing/nginx
docker build ./load_balancing_tengine -t load_balancing/tengine
```
