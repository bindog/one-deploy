# 魔改版cortex编译

```shell
# 准备golang环境
sudo yum install golang  # sudo apt-get install golang
# 配置阿里云代理加速
go env -w GO111MODULE=on
go env -w GOPROXY=https://mirrors.aliyun.com/goproxy/,direct
# 确认当前环境有代理加速
go env | grep GOPROXY
# GOPROXY="https://mirrors.aliyun.com/goproxy/,direct"
# 编译
cd ~
git clone https://github.com/bindog/cortex.git
cd ~/cortex
sh build/cli.sh
# 编译结束得到一个cortex的可执行二进制文件，可复制到系统目录下
sudo cp cortex /usr/local/bin/cortex
```
