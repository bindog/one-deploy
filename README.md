# 一步 one-deploy

## 简介

深度学习自动部署框架，整合了多个优秀开源项目，让部署变成简易轻松

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
- 官方[registrator](https://github.com/gliderlabs/registrator), 魔改[registrator]()
- [consul](https://github.com/hashicorp/consul)
- [consul-template](https://github.com/hashicorp/consul-template)
