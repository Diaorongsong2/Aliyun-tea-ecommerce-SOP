#!/bin/bash
# ============================================================
# 06 - 构建环境：Maven 与 Node.js
# 主机：ecs-host（172.18.176.252）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

# ---------- Maven ----------
tar -xf apache-maven-3.6.3-bin.tar.gz
mv apache-maven-3.6.3 /usr/local/maven
yum -y install java-11-openjdk-devel

vim /etc/bashrc
# export MAVEN_HOME="/usr/local/maven"
# export PATH=${MAVEN_HOME}/bin/:$PATH

source /etc/bashrc
mvn -v
# Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
# Maven home: /usr/local/maven
# Java version: 11.0.20, vendor: Red Hat, Inc., runtime: /usr/lib/jvm/java-11-openjdk-11.0.19.0.7-4.el8.x86_64
# OS name: "linux", version: "4.18.0-372.26.1.el8_6.x86_64", arch: "amd64", family: "unix"

# 指向离线本地仓库，避免从公网拉依赖
vim /usr/local/maven/conf/settings.xml
# 55 <localRepository>/usr/local/maven/repository/</localRepository>

tar -xf /root/repository.tar.gz -C /usr/local/maven/

# ---------- Node.js ----------
tar -xf node-v16.13.0-linux-x64.tar.gz
mv node-v16.13.0-linux-x64 /usr/local/node

vim /etc/bashrc
# export MAVEN_HOME="/usr/local/maven"
# export NODE_HOME="/usr/local/node"
# export PATH=${MAVEN_HOME}/bin/:${NODE_HOME}/bin/:$PATH

source /etc/bashrc
npm -v
# 8.1.0
