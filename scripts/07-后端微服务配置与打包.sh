#!/bin/bash
# ============================================================
# 07 - 后端微服务：改配置、打包、试运行
# 主机：ecs-host（172.18.176.252）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
#
# 四个服务在三个代码仓库里，改的都是 resources 下的 application-vm：
#   tarena-tp-tea/tea-server  -> 30091  商品展示
#   tarena-tp-tea/tea-admin   -> 30092  商品管理
#   tarena-tp-attach/attach-server -> 30093  附件中心
#   tarena-passport/passport-provider -> 30094  验证中心
# 脱敏后的配置文件见 configs/。
# ============================================================

tar -xf tea-master.tar.gz

# 各依赖的地址（写进上面四个配置文件）
#   mysql:    <RDS-MySQL-内网地址>
#   redis:    <云Redis-内网地址>
#   nacos:    172.18.176.13
#   rocketmq: 172.18.176.14
#   slb:      <SLB-公网IP>

# ---------- 1) 商品展示服务 ----------
cd /root/tea/code/backend/tarena-tp-tea/
vim tea-server/tea-server-main/src/main/resources/application-vm.yaml
mvn clean package -Dmaven.test.skip=true
# [INFO] BUILD SUCCESS
# [INFO] Total time:  04:56 min
java -Dfile.encoding=utf-8 -jar tea-server/tea-server-main/target/tea-server-admin-1.0.0-SNAPSHOT.jar \
  -Xmx128M -Xms128M -Xmn64m -XX:MaxMetaspaceSize=128M -XX:MetaspaceSize=128M \
  --server.port=30091 --spring.profiles.active=vm
# Started MainApplication in 12.916 seconds (JVM running for 13.676)

# 准备图片目录（后面 NFS 要把这个目录共享出去）
mkdir -p /home/images/vm/tea_attach/
tar -xf /root/tea/teaimg.tar.gz -C /home/images/vm/tea_attach/

# jar 统一放到 /project/jar，容器里挂的就是这个目录
mkdir -p /project/jar
cp tea-server/tea-server-main/target/tea-server-admin-1.0.0-SNAPSHOT.jar /project/jar/

# ---------- 2) 商品管理服务 ----------
vim tea-admin/tea-admin-main/src/main/resources/application-vm.yaml
mvn clean package -D'maven.test.skip'=true
java -Dfile.encoding=utf-8 -jar tea-admin/tea-admin-main/target/tea-admin-main-1.0.0-SNAPSHOT.jar \
  -Xmx128M -Xms128M -Xmn64m -XX:MaxMetaspaceSize=128M -XX:MetaspaceSize=128M \
  --server.port=30092 --spring.profiles.active=vm
cp tea-admin/tea-admin-main/target/tea-admin-main-1.0.0-SNAPSHOT.jar /project/jar/

# ---------- 3) 附件中心服务 ----------
cd /root/tea/code/backend/tarena-tp-attach/
vim attach-server/attach-server-main/src/main/resources/application-vm.yaml
vim attach-server/attach-server-main/src/main/resources/bootstrap.yaml
mvn clean package -D'maven.test.skip'=true
java -Dfile.encoding=utf-8 -jar attach-server/attach-server-main/target/attach-server-main-1.0.0-SNAPSHOT.jar \
  -Xmx128M -Xms128M -Xmn64m -XX:MaxMetaspaceSize=128M -XX:MetaspaceSize=128M \
  --server.port=30093 --spring.profiles.active=vm
# Started MainApplication in 12.162 seconds (JVM running for 12.923)
cp attach-server/attach-server-main/target/attach-server-main-1.0.0-SNAPSHOT.jar /project/jar/

# ---------- 4) 验证中心服务 ----------
cd /root/tea/code/backend/tarena-passport/
vim passport-provider/src/main/resources/application-vm.yml
mvn clean package -D'maven.test.skip'=true
java -Dfile.encoding=utf-8 -jar passport-provider/target/passport-provider-1.0-SNAPSHOT.jar \
  -Xmx128M -Xms128M -Xmn64m -XX:MaxMetaspaceSize=128M -XX:MetaspaceSize=128M \
  --server.port=30094 --spring.profiles.active=vm
# Started ProviderApp in 7.988 seconds (JVM running for 8.786)
cp passport-provider/target/passport-provider-1.0-SNAPSHOT.jar /project/jar/

# 最终 /project/jar 下四个包：
#   tea-server-admin-1.0.0-SNAPSHOT.jar
#   tea-admin-main-1.0.0-SNAPSHOT.jar
#   attach-server-main-1.0.0-SNAPSHOT.jar
#   passport-provider-1.0-SNAPSHOT.jar
