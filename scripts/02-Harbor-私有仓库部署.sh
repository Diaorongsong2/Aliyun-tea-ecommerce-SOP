#!/bin/bash
# ============================================================
# 02 - Harbor 私有镜像仓库部署
# 主机：harbor（172.18.176.30）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

# 上传 harbor-offline-installer-v2.5.3.tgz 后解压
tar -xf harbor-offline-installer-v2.5.3.tgz
cd harbor/
docker load -i harbor.v2.5.3.tar.gz

# 生成自签 HTTPS 证书（Harbor 默认走 443，证书是必须的）
mkdir tls
openssl genrsa -out tls/cert.key 2048
openssl req -new -x509 -days 3650 \
  -key tls/cert.key -out tls/cert.crt \
  -subj "/C=CN/ST=BJ/L=BJ/O=Tedu/OU=NSD/CN=harbor"

# 改配置：主机名、HTTPS 证书路径、管理员口令（改动项见 configs/harbor.yml）
mv harbor.yml.tmpl harbor.yml
vim harbor.yml

# 检查配置
./prepare
# Successfully called func: create_root_cert
# Generated configuration file: /compose_location/docker-compose.yml
# Clean up the input dir

# 拉起全套容器
docker compose -f docker-compose.yml up -d
docker ps

# 开机自启
chmod 0755 /etc/rc.d/rc.local
echo "/usr/bin/docker compose -p harbor start" >>/etc/rc.d/rc.local

# ------------------------------------------------------------
# 浏览器访问 https://<harbor 公网IP>
# 一开始打不开，是安全组没放行 443，放行后正常。
#
# 登录后在「项目」里新建项目 tea，访问级别选公开，
# 用来存放后端服务共用的 jar 运行时镜像。
# ------------------------------------------------------------
