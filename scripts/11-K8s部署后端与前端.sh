#!/bin/bash
# ============================================================
# 11 - 在 ACK 上部署后端服务与前端 nginx
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
#      yaml 全文见 k8s-manifests/，这里只记部署顺序。
# ============================================================

mkdir tea-yaml && cd tea-yaml

# ---------- 1) 时区 ConfigMap ----------
kubectl apply -f tz.yaml
kubectl get configmaps
# NAME               DATA   AGE
# kube-root-ca.crt   1      31m
# timezone           1      9s

# ---------- 2) 共享 jar 的 PV / PVC ----------
kubectl apply -f pv-pvc-jar.yaml
kubectl apply -f pv-pvc-image.yaml

# ---------- 3) 四个后端服务 ----------
kubectl apply -f passport-jar.yaml
kubectl apply -f teaserver-jar.yaml
kubectl apply -f teaadmin-jar.yaml
kubectl apply -f attach-jar.yaml

# ---------- 4) 后端 Service ----------
kubectl apply -f passport-service.yaml
kubectl apply -f teaserver-service.yaml
kubectl apply -f teaadmin-service.yaml
kubectl get service
# NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)     AGE
# kubernetes          ClusterIP   10.247.0.1       <none>        443/TCP     79m
# passport-service    ClusterIP   10.247.184.212   <none>        30094/TCP   4m9s
# teaadmin-service    ClusterIP   10.247.181.110   <none>        30092/TCP   55s
# teaserver-service   ClusterIP   10.247.248.165   <none>        30091/TCP   2m19s
# 注：附件中心的调用走 Dubbo/Nacos，没有再单独建 Service。

# ---------- 5) 前端页面静态资源的 PV / PVC ----------
kubectl apply -f pv-pvc-adminpage.yaml
kubectl apply -f pv-pvc-frontpage.yaml

# ---------- 6) nginx 配置与部署 ----------
# nginx.conf 内容见 configs/nginx.conf
kubectl create configmap nginx --from-file=nginx.conf
kubectl apply -f nginx.yaml
kubectl apply -f nginx-service.yaml

# 检查
kubectl get pods
kubectl get svc nginx-service
# nginx-service 是 NodePort，三个端口 30080 / 30091 / 30092 挂在每个节点上
