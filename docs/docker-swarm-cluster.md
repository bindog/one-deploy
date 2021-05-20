# 搭建docker swarm集群

三台机器，均为CentOS 7.9，其IP和角色分别为

- 192.168.20.190 管理节点
- 192.168.20.191 普通节点
- 192.168.20.192 普通节点

## firewall配置

在每台机器上执行

```shell
firewall-cmd --zone=public --add-port=2377/tcp --permanent &&
firewall-cmd --zone=public --add-port=7946/tcp --permanent &&
firewall-cmd --zone=public --add-port=7946/udp --permanent &&
firewall-cmd --zone=public --add-port=4789/udp --permanent &&
firewall-cmd --reload
```

## 创建集群

```shell
# 在管理节点上执行
[root@localhost ~]# docker swarm init --advertise-addr 192.168.20.190
Swarm initialized: current node (ykiyahkjoq3q0dn2rrnqd4ery) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-4ggr6t9qpoipck2ksobnphhwe0kcr47idiwaezh9uu672ueokf-7vchqxxkk4p7vavh9h4hijydw 192.168.20.190:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

# 在其他节点上分别执行
[root@localhost ~]# docker swarm join --token SWMTKN-1-4ggr6t9qpoipck2ksobnphhwe0kcr47idiwaezh9uu672ueokf-7vchqxxkk4p7vavh9h4hijydw 192.168.20.190:2377
```

## 安装管理面板

```shell
docker run -d --name portainer --restart=always -p 8000:8000 -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v /home/data/portainer/data:/data portainer/portainer
systemctl restart docker
# 重启docker
sudo systemctl restart docker 
```

## 参考

https://learnku.com/articles/37840
