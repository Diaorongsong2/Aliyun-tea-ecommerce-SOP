#!/bin/bash
# ============================================================
# 03 - 制作并推送 jar 运行时基础镜像
# 主机：ecs-host（172.18.176.252）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

# 让 ecs-host 能解析到 Harbor
vim /etc/hosts
# 172.18.176.30 harbor

# 导入 RockyLinux 基础镜像
docker load -i rockylinux.tar.gz
docker images
# REPOSITORY   TAG    IMAGE ID       CREATED      SIZE
# rockylinux   8.5    210996f98b85   3 years ago  205MB

# 构建只含 JDK 的 jar 运行时镜像（Dockerfile 见 configs/Dockerfile-jar-base）
mkdir /root/jar-package
cd /root/jar-package/
vim Dockerfile

docker build -t jar:base .
docker images
# REPOSITORY   TAG    IMAGE ID       CREATED         SIZE
# jar          base   5bb91253b6c7   26 seconds ago  457MB

# 打标签指向 Harbor
docker tag jar:base harbor:443/tea/jar:base

# 绕过自签证书（见 configs/docker-daemon.json）
vim /etc/docker/daemon.json
systemctl restart docker

# 登录并推送
docker login harbor:443
# Username: admin
# Password: <YOUR_PASSWORD>
docker push harbor:443/tea/jar:base

# ------------------------------------------------------------
# 后面四个后端服务全部复用这一个镜像，
# 业务 jar 不打进镜像，而是放在 NFS 上挂进容器（见 09）。
# ------------------------------------------------------------
