#!/bin/bash
# ============================================================
# 10 - ACK 集群：配置 kubectl 与 containerd 的 Harbor 认证
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

# ---------- 1) 在 ACK 控制台下载 kubeconfig，配到跳板机上 ----------
mkdir .kube
cd .kube/
vim config

kubectl get node
# NAME                        STATUS   ROLES    AGE     VERSION
# cn-hangzhou.172.18.191.71   Ready    <none>   6m40s   v1.32.1-aliyun.1
# cn-hangzhou.172.18.191.72   Ready    <none>   6m41s   v1.32.1-aliyun.1
# cn-hangzhou.172.18.191.73   Ready    <none>   6m40s   v1.32.1-aliyun.1

# ---------- 2) 所有 K8s 节点补 hosts，让 containerd 能解析 harbor ----------
vim /etc/hosts
# 172.18.176.30 harbor

# ---------- 3) containerd 配置 Harbor：镜像加速 + 跳过自签证书校验 ----------
vim /etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".registry.mirrors."harbor:443"]
#     endpoint = ["https://harbor:443"]
# [plugins."io.containerd.grpc.v1.cri".registry.configs."harbor:443".tls]
#     insecure_skip_verify = true

systemctl restart containerd

# ------------------------------------------------------------
# 注意：阿里云 ACK 对节点上自签证书有校验限制，
# containerd 直接拉 harbor:443 会失败。当时的绕法是：
#
#   # 在 ecs-host 上把镜像导出
#   docker save jar:base -o jar.tar.gz
#
#   # 上传到 ACK 的每个节点后手工导入
#   ctr -n k8s.io images import jar.tar.gz
#
# 这样 Pod 就能以 IfNotPresent 策略直接用本地镜像起容器。
# ------------------------------------------------------------
