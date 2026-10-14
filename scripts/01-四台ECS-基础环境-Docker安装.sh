#!/bin/bash
# ============================================================
# 01 - 四台 ECS 基础环境：安装 Docker
# 说明：这是部署过程的操作记录（含命令输出），不是可直接执行的自动化脚本。
#      在 ecs-host / harbor / nacos / rocketmq 四台机器上都要执行。
# ============================================================

# 配置阿里云 Docker CE 源
wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum search docker-ce

# 安装并启动
yum -y install docker-ce
systemctl enable --now docker

# 验证
docker --version

# ------------------------------------------------------------
# 约定：四台机器的内网地址与主机名
#   ecs-host  172.18.176.252  构建 + NFS 共享
#   harbor    172.18.176.30   私有镜像仓库
#   nacos     172.18.176.13   注册中心 / 配置中心
#   rocketmq  172.18.176.14   消息队列
#
# 需要互相解析主机名的机器上补 hosts：
#   vim /etc/hosts
#   172.18.176.30 harbor
# ------------------------------------------------------------
