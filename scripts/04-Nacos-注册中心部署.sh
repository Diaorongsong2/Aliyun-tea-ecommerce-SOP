#!/bin/bash
# ============================================================
# 04 - Nacos 注册中心部署
# 主机：nacos（172.18.176.13）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

tar -xf /root/nacos-server-2.0.2.tar.gz -C /usr/local/
yum -y install java-1.8.0-openjdk-devel
cd /usr/local/nacos/

# 改数据库配置：Nacos 注册数据落 RDS MySQL 的 nacos 库
vim conf/application.properties
# 33 spring.datasource.platform=mysql
# 36 db.num=1
# 39 db.url.0=jdbc:mysql://<RDS-MySQL-内网地址>:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true&useUnicode=true&useSSL=false&serverTimezone=UTC
# 40 db.user.0=nacos
# 41 db.password.0=<YOUR_PASSWORD>

# 单机模式启动
vim bin/startup.sh
# 55 export MODE="standalone"

./bin/startup.sh
tail -2 logs/start.out
# 2025-03-14 15:33:13,360 INFO Nacos started successfully in stand alone mode. use external storage

ss -antlp | grep 8848
# LISTEN 0 100 [::]:8848 [::]:* users:(("java",pid=2515,fd=148))

# 开机自启
echo "/usr/local/nacos/bin/startup.sh" >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# ------------------------------------------------------------
# 浏览器访问 http://<nacos 公网IP>:8848/nacos/（安全组放行 8848）
# 登录后在「命名空间」里新建命名空间：
#   命名空间名 project，命名空间 ID 填 linux
# 后面所有服务的 profile: vm 都注册到这个命名空间下。
# ------------------------------------------------------------
