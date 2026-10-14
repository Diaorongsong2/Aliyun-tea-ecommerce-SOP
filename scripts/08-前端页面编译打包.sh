#!/bin/bash
# ============================================================
# 08 - 前端页面编译打包
# 主机：ecs-host（172.18.176.252）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
#
# 两个 Vue 项目，产物都放到 /project/page 下，由 NFS 共享给 K8s 里的 nginx。
# ============================================================

# ---------- 1) 商品管理页面 ----------
cd /root/tea/code/page/admin-page/
npm install
npm run build:test
ls -l
# drwxr-xr-x 3 root root 4096 Mar 14 20:23 dist   <- 打包产物

mkdir -p /project/page
mkdir /project/page/admin-page
cp -r dist/ /project/page/admin-page

# ---------- 2) 商品展示页面 ----------
cd ../front-page/
npm install
npm run build:linuxTech
ls -l
# drwxr-xr-x 3 root root 4096 Mar 14 20:32 dist   <- 打包产物

mkdir /project/page/front-page
cp -r dist/ /project/page/front-page

# 目录约定：
#   /project/page/admin-page/dist  -> 管理后台静态资源（nginx 30092）
#   /project/page/front-page/dist  -> 商城前台静态资源（nginx 30091）
