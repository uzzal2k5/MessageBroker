#!/usr/bin/env bash
# The latest release of RabbitMQ is 3.6.14.
# http://dl.fedoraproject.org/pub/epel/7/x86_64/e/erlang-R16B-03.18.el7.x86_64.rpm
# http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/erlang-R16B-03.18.el7.x86_64.rpm
yum install epel-release
yum install erlang
yum install socat
wget https://dl.bintray.com/rabbitmq/rabbitmq-server-rpm/rabbitmq-server-3.6.14-1.el7.noarch.rpm
rpm --import https://www.rabbitmq.com/rabbitmq-release-signing-key.asc
yum -y install rabbitmq-server-3.6.14-1.noarch.rpm
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
systemctl status -l rabbitmq-server


# RabbitMQ  ManagementGUI
rabbitmq-plugins enable rabbitmq_management

# URL : http://sam-test:15672/api/  and http://sam-test:15672/cli/

# USER MANAGEMENT / Create ADMIN USER
rabbitmqctl add_user rabbit rabbit
rabbitmqctl set_permissions rabbit ".*" ".*" ".*"

rabbitmqctl add_user admin admin
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"


# ------------------Enabling the Plugin
# Rabbit STOMP
rabbitmq-plugins enable rabbitmq_stomp
rabbitmq-plugins enable rabbitmq_mqtt

rabbitmq-plugins enable rabbitmq_auth_backend_ldap

#Cluster:
#============
# NODEs : sam-test, mongodb0
# On sam-test
# ---- FIREWALL RULES ADD-----------#

firewall-cmd --add-port=15672/tcp
firewall-cmd --add-port=4369/tcp --permanent
firewall-cmd --reload

# CLUSTER JOIN

rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@sam-test
rabbitmqctl cluster_status

chmod 600 ${cookie=$(find /var/lib/rabbitmq/ -name .erlang.cookie)}
nodes=( uzzal )
for node in "${nodes[@]}";
do
scp $cookie "$node":$cookie
ssh -t "$node" "chmod 600 $cookie"
ssh -t "$node" "chown rabbitmq:rabbitmq $cookie"
ssh -t "$node" "rabbitmqctl stop_app"
ssh -t "$node" "rabbitmqctl join_cluster rabbit@sam-test"
done
rabbitmqct stop_app
rabbitmqctl join_cluster "$node"

/var/lib/rabbitmq/.erlang.cookie


ssh -t "$node" "rabbitmqctl join_cluster rabbit@sam-test"
nodes=( mongodb0 sam-test )
for i in ${nodes["@"]};
 do
 echo $i
 done



################ POLICY ####################
# rabbitmqctl set_policy <name> <pattern> <Definition> --priority <priority> --apply-to <queues / exchange>
rabbitmqctl set_policy ha-fed "^hf\." '{"federation-upstream-set":"all","ha-mode":"all"}' \
--priority 1 --apply-to queues