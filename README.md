# 一步 one-deploy

## 简介

深度学习自动部署框架，整合了多个优秀开源项目，简 **易(Yi)** 轻松完成 **部(Bu)** 署

## 特性

- 支持多种模型推理(PyTorch/ONNX/TF)
- API服务情况监控
- 微服务架构/容器化部署
- 服务自动注册/发现
- 反向代理/动态负载均衡

## 短期计划

- nginx零重启更新upstream
- 自动弹性扩展
- 增加压测脚本
- 增加支持其他类型反向代理和负载均衡工具，如[traefik](https://github.com/traefik/traefik/)
- 增加CV方向的Demo和测试模型
- 文档说明

## 长期计划

- 支持本地k8s集群
- 模型修改工具
- 网页前端进行配置管理

## 整合开源项目列表

- 官方[cortex](https://github.com/cortexlabs/cortex), 魔改[cortex](https://github.com/bindog/cortex)
- 官方[registrator](https://github.com/gliderlabs/registrator), 魔改[registrator](https://github.com/bindog/registrator)
- [consul](https://github.com/hashicorp/consul)
- [consul-template](https://github.com/hashicorp/consul-template)

# 快速开始

## 代码结构

```shell
one-deploy
├── code-hub                        # 预留
│   └── README.md
├── cortex_cls.yaml                 # 文本分类yaml示例
├── cortex_ner.yaml                 # 命令实体识别yaml示例
├── cortex_seg.yaml                 # 分词yaml示例
├── cortex_trans.yaml               # 翻译yaml示例
├── cortex.yaml.tmpl                # yaml模板文件
├── dependencies                    # pip requirements(与示例对应)
│   ├── requirements_cls.txt
│   ├── requirements_ner.txt
│   ├── requirements_seg.txt
│   └── requirements_trans.txt
├── image-build                     # 镜像构建目录
│   ├── cached_whl                  # 本地缓存的whl文件
│   ├── images                      # 不同类型镜像Dockerfile
│   ├── pip.conf                    # pip配置
│   ├── pkg                         # cortex服务端代码
│   └── README.md
├── LICENSE
├── model-hub                       # 本地模型文件
│   └── README.md
├── predictors                      # 预测/推理代码(与示例对应)
│   ├── predictor_cls.py
│   ├── predictor_ner.py
│   ├── predictor_seg.py
│   └── predictor_trans.py
├── README.md
└── srd                             # 服务发现与负载均衡
    ├── docker-compose.yml          # docker-compose文件
    ├── load_balancing_nginx        # nginx负载均衡
    ├── load_balancing_tengine      # tengine负载均衡(可选)
    └── README.md
```

## 环境准备

1. 准备魔改后的cortex可执行文件，请参考[文档](./docs/cortex-build.md)

2. 准备所需各种镜像，请参考[文档](./docs/images-build.md)

3. 准备docker swarm集群，请参考[文档](./docs/docker-swarm-cluster.md)

## Ready to go

```shell
cd srd
# 创建overlay网络
docker network create -d overlay ai_service_proxy --attachable
# 创建服务注册&自动发现&负载均衡的集群
docker stack deloy -c docker-compose.yml ai
cd ..
# 部署服务
cortex deploy cortex_seg.yaml
cortex deploy cortex_cls.yaml
...
# 在docker swarm集群的其他机器上也可
cortex deploy cortex_ner.yaml
```
