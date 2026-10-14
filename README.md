# 阿里云茶叶电商系统部署 SOP

在阿里云上从零搭一套茶叶电商系统（学茶网）的完整部署记录。

从云资源采购一路做到对外发布：自建 Harbor 私有镜像仓库、Nacos 注册中心、RocketMQ 消息队列，数据层用云 RDS MySQL 和云 Redis，业务跑在 ACK 容器集群上，Jar 包和前端静态资源走 NFS 共享挂载，最后用 SLB 发布出去。

**部署环境**：阿里云 ECS（Rocky Linux 8.5 / 8.9 x86_64）、ACK v1.32.1-aliyun.1、Harbor 2.5.3、Nacos 2.0.2、RocketMQ 4.9.4、nginx、containerd

> 这是实验环境的部署记录，验收完成后所有云资源已释放。仓库里的口令、RDS/Redis 内网地址、公网 IP、实例 ID 一律换成了占位符。

---

## 一、这套系统长什么样

一个 Spring Cloud 微服务后端 + 两个 Vue 前端的茶叶商城。硬件是四台自建 ECS 加一组云服务。

| 角色 | 地址 | 配置 | 跑什么 |
|---|---|---|---|
| ecs-host | 172.18.176.252 | 2C8G | Docker、Maven 3.6.3、Node 16.13、NFS 服务端、前端编译产物 |
| harbor | 172.18.176.30 | 2C2G | Harbor 2.5.3（HTTPS 443） |
| nacos | 172.18.176.13 | 2C2G | Nacos 2.0.2 单机模式（8848） |
| rocketmq | 172.18.176.14 | 2C2G | RocketMQ 4.9.4 NameServer + Broker（9876） |

云服务这边：ACK 三节点托管集群跑业务，RDS MySQL 承载业务库 / 验证码库 / Nacos 注册库，云 Redis 做缓存和验证码，SLB 做公网入口。

请求链路：

```
浏览器
  │
  ▼
SLB（公网，30080 / 30091 / 30092 三个 TCP 监听）
  │
  ▼
ACK 节点 NodePort
  │
  ▼
nginx Pod ─┬─ 30080  商品图片    → /home/images/vm（NFS）
           ├─ 30091  商城前台页  → front-page/dist（NFS）
           │          /api/          → teaserver-service:30091
           │          /passport-api/ → passport-service:30094
           └─ 30092  商品管理页  → admin-page/dist（NFS）
                      /api/          → teaadmin-service:30092
                      /to_passport/  → passport-service:30094

四个后端 Pod（同一个 jar:base 镜像，jar 从 NFS 的 /project/jar 加载）
  ├── teaserver-jar   30091  商品展示
  ├── teaadmin-jar    30092  商品管理
  ├── attache-jar     30093  附件中心（图片上传）
  └── passport-jar    30094  验证码
        │
        ├── RDS MySQL（tarena_tp_tea / cs_mall_passport / nacos）
        ├── 云 Redis（db8 业务 / db9 验证码）
        ├── Nacos（注册发现 + Dubbo）
        └── RocketMQ（订单取消、支付成功等主题）
```

## 二、这套方案的三个设计点

**镜像只做运行时基座。** 四个后端服务共用同一个 `harbor:443/tea/jar:base`，镜像里只有一个 JDK，没有业务代码。业务 Jar 放在宿主机 `/project/jar`，通过 NFS 挂进容器。换包时只替换 NFS 上的文件、重启 Pod，不用重建和推送镜像。代价是四个服务共用一个镜像标签，版本追踪只能靠 Jar 文件名。

**前端静态资源同样走 NFS。** 两个 Vue 项目编译出的 `dist` 目录，和商品图片目录一起挂在 nginx Pod 上。前端改版重新编译、覆盖 NFS 上的目录即可，全程不碰镜像。

**一套 nginx 顶三个站点。** 靠 `nginx.conf` 里三个 `server` 块按端口区分，各自 root 到不同目录，再把 `/api/` 反代到对应的后端 Service。页面和接口同端口，前端同源，不用处理跨域。

## 三、仓库结构

```
k8s-manifests/                      ACK 上的资源对象，按部署顺序编号
  00-timezone-configmap.yaml        时区 ConfigMap
  01-04-pv-pvc-*.yaml               共享 jar / 图片 / 前端页面的 PV 与 PVC
  10-13-*-deployment.yaml           四个后端服务的 Deployment
  20-22-*-service.yaml              后端服务的 ClusterIP Service
  30-nginx-deployment.yaml          nginx（一个 Pod 提供三个站点）
  31-nginx-service.yaml             nginx 的 NodePort Service
configs/                            脱敏后的配置与构建文件
  tea-server-application-vm.yaml    商品展示服务配置
  tea-admin-application-vm.yaml     商品管理服务配置
  attach-server-application-vm.yaml 附件中心服务配置
  attach-server-bootstrap.yaml      附件中心的 Nacos 多环境引导配置
  passport-application-vm.yml       验证码服务配置
  nginx.conf                        前端三个站点的 nginx 配置
  harbor.yml                        Harbor 配置（只列改动项）
  Dockerfile-jar-base               jar 运行时基础镜像
  docker-daemon.json                Docker 客户端信任 Harbor 的配置
scripts/                            按部署顺序编号的操作记录
  01-四台ECS-基础环境-Docker安装.sh
  02-Harbor-私有仓库部署.sh
  03-制作并推送jar基础镜像.sh
  04-Nacos-注册中心部署.sh
  05-RocketMQ-消息队列部署.sh
  06-构建环境-Maven与Node.sh
  07-后端微服务配置与打包.sh
  08-前端页面编译打包.sh
  09-NFS共享与安全组放行.sh
  10-ACK集群-containerd配置与镜像导入.sh
  11-K8s部署后端与前端.sh
  12-SLB发布与验收清理.sh
images/                             过程截图
阿里云茶叶电商系统部署SOP.md          完整 SOP
```

**没有纳入仓库的东西**：四个服务的业务源码、离线安装包（Harbor 660MB、RockyLinux 镜像、Maven 本地仓库等）、以及业务库的 SQL 脚本。前者是课程资料，后者体积太大，都不适合放进来。

## 四、怎么复现

> **关于 `scripts/*.sh`**：这些是**部署过程的操作记录**（还原了当时的命令和输出），不是可以直接执行的自动化脚本，按顺序照着敲即可。

```bash
# 1. 四台 ECS 装 Docker，互相补 hosts
scripts/01-四台ECS-基础环境-Docker安装.sh

# 2. Harbor：自签证书 → 改 harbor.yml → 起容器 → 建 tea 项目
scripts/02-Harbor-私有仓库部署.sh

# 3. 构建只含 JDK 的镜像，推送到 Harbor 的 tea 项目
scripts/03-制作并推送jar基础镜像.sh

# 4. 注册中心与消息队列
scripts/04-Nacos-注册中心部署.sh
scripts/05-RocketMQ-消息队列部署.sh

# 5. 构建环境（编译用 JDK 11，运行用 JDK 1.8）
scripts/06-构建环境-Maven与Node.sh

# 6. 改四个服务的 application-vm 配置，打包，产物统一放 /project/jar
#    配置模板见 configs/，需要替换的只有口令和几个地址
scripts/07-后端微服务配置与打包.sh

# 7. 编译两个前端，dist 放到 /project/page
scripts/08-前端页面编译打包.sh

# 8. 把 jar / 页面 / 图片三个目录用 NFS 共享出去
scripts/09-NFS共享与安全组放行.sh

# 9. ACK 节点补 hosts、配 containerd 信任 Harbor
scripts/10-ACK集群-containerd配置与镜像导入.sh

# 10. 按顺序 apply 资源对象
scripts/11-K8s部署后端与前端.sh

# 11. SLB 挂三个监听，验收，最后清理资源
scripts/12-SLB发布与验收清理.sh
```

**凭据说明**：仓库里**不保存任何明文口令**。所有配置文件里出现过的密码统一写成 `<YOUR_PASSWORD>`，RDS / Redis 的内网地址写成 `<RDS-MySQL-内网地址>` / `<云Redis-内网地址>`，公网 IP 写成 `<SLB-公网IP>`。照着替换成自己的就行。

## 五、完整文档

每一步的命令与输出、ACK 上自签证书拉不动镜像的绕法、以及几个部署时踩到的坑，都在
[`阿里云茶叶电商系统部署SOP.md`](./阿里云茶叶电商系统部署SOP.md)。
