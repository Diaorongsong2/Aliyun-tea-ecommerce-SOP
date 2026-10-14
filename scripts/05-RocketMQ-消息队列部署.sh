#!/bin/bash
# ============================================================
# 05 - RocketMQ 消息队列部署
# 主机：rocketmq（172.18.176.14）
# 说明：部署过程的操作记录，不是可直接执行的自动化脚本。
# ============================================================

yum -y install unzip
unzip /root/rocketmq-all-4.9.4-bin-release.zip
mv rocketmq-all-4.9.4-bin-release/ /usr/local/rocketmq
yum -y install java-1.8.0-openjdk-devel
cd /usr/local/rocketmq/

# Broker 配置：绑定本机内网地址
vim conf/broker.conf
# namesrvAddr=0.0.0.0:9876
# brokerIP1=172.18.176.14
# brokerIP2=127.0.0.1

# 调小 JVM 堆（默认配置按大内存机器给的，2G 的机器起不来）
vim bin/runserver.sh
# 71 JAVA_OPT="${JAVA_OPT} -server -Xms512m -Xmx512m -Xmn256m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=320m"

vim bin/runbroker.sh
# 85 JAVA_OPT="${JAVA_OPT} -server -Xms512m -Xmx512m"

# 启动 NameServer 和 Broker
nohup /usr/local/rocketmq/bin/mqnamesrv -n 0.0.0.0:9876 &> /usr/local/rocketmq/bin/namesrv.log &
nohup /usr/local/rocketmq/bin/mqbroker -n 172.18.176.14:9876 autoCreateTopicEnable=true \
  -c /usr/local/rocketmq/conf/broker.conf &> /usr/local/rocketmq/bin/mqbroker.log &

# 验证
jps
# 2498 Jps
# 2330 NamesrvStartup
# 2395 BrokerStartup
ss -antplu | grep 9876
# tcp LISTEN 0 128 [::]:9876 [::]:* users:(("java",pid=2330,fd=92))

# 开机自启：把上面两条 nohup 追加到 /etc/rc.d/rc.local 末尾
vim /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

# ------------------------------------------------------------
# 订单相关主题由服务端配置声明（见 configs/tea-server-application-vm.yaml）：
#   order-cancel-topic / order-auto-close-topic / pay-success-paid
#   order-success-paid-topic
# autoCreateTopicEnable=true 是让 Broker 在第一次发送时自动建主题，
# 生产环境应改成提前手工建主题、关闭自动创建。
# ------------------------------------------------------------
