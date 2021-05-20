## 服务注册&发现与自动负载均衡 (Service Registration & Service Discovery / Load Balancing)

## 1 环境

### 1.1 创建网络

```bash
docker network create -d overlay --attachable ai_service_proxy
```

构建镜像请参考[镜像构建文档](../docs/images-build.md)

### 1.2 启动

启动前确保docker swarm集群中每个节点都**包含了所需镜像且版本一致**

```bash
docker stack deploy -c docker-compose.yml ai
```

### 1.3 查看状态
```bash
docker stack services ps ai
```

### 1.4 停止

```bash
docer stack rm ai
```

## 2 管理

注：现版本为测试版本，计划有两套自动负载均衡方案（正在调试中）：

- 基于`nginx`和`consul-template`的方案，暴露端口为8900，需要reload
- 基于`tengine`和`ngx_http_dyups_module`的方案，暴露端口为9900，不需要reload

### 2.1 consul管理界面

```bash
http://host_ip:8500
```

## 3 服务注册&发现

### 3.1 基本流程

1. 利用cortex部署算法服务容器(容器必须包含`SERVICE_*`打头的一系列环境变量)
2. `registrator`通过监控`/var/run/docker.sock`文件获取所有启动/停止的容器情况
3. `registrator`根据容器的`SERVICE_*`环境变量向`consul`集群注册该服务
4. `consul-template`监控到`consul`集群中服务状态发生变化，根据预设模板生成新的`nginx.conf`文件并触发nginx服务reload

### 3.2 `SERVICE_*`环境变量说明

- `SERVICE_NAME`: 服务名
- `SERVICE_NETWORK`: 服务网络(docker network)
- `SERVICE_TAGS`: 服务标签
- `SERVICE_xxx`: xxx可以为任意值，其他属性
- `SERVICE_CHECK_HTTP`: HTTP健康状态检查endpoint
- `SERVICE_CHECK_INTERVAL`: 检查间隔
- `SERVICE_CHECK_INITIAL_STATUS`: 服务初始状态
- `SERVICE_CHECK_DEREGISTER_AFTER`: 多长时间内无响应自动注销服务

若一个容器中包含多个服务，可通过在环境变量中加入端口号进行指定，如`SERVICE_443_NAME`, `SERVICE_80_CHECK_HTTP`等

示例：
```yaml
env:
  SERVICE_NAME: "ais_seg"
  SERVICE_NETWORK: "ai_service_proxy"
  SERVICE_TAGS: "chinese,seg"
  SERVICE_LANG: "zh-cn"
  SERVICE_CHECK_HTTP: "/"
  SERVICE_CHECK_INTERVAL: "15s"
  SERVICE_CHECK_INITIAL_STATUS: "critical"
  SERVICE_CHECK_DEREGISTER_AFTER: "3m"
```

## 4 自动负载均衡

`consul-template`与`nginx`在同一个docker内，`consul-template`通过监控consul集群中的服务状态变化情况，根据模板生成对应的`nginx.conf`文件（包含upstream中的server）并触发reload。但这种方式在reload时会有部分负载升高的情况，无法做到真正的无缝切换
