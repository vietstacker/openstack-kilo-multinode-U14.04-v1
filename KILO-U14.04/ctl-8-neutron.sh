#!/bin/bash -ex
#
# RABBIT_PASS=a
# ADMIN_PASS=a

source config.cfg

SERVICE_TENANT_ID=`keystone tenant-get service | awk '$2~/^id/{print $4}'`


echo "########## Install NEUTRON in $CON_MGNT_IP or NETWORK node ################"
sleep 5
apt-get -y install neutron-server neutron-plugin-ml2 python-neutronclient

######## Backup configuration NEUTRON.CONF in $CON_MGNT_IP##################"
echo "########## Config NEUTRON in $CON_MGNT_IP/NETWORK node ##########"
sleep 7

#
controlneutron=/etc/neutron/neutron.conf
test -f $controlneutron.orig || cp $controlneutron $controlneutron.orig
rm $controlneutron
touch $controlneutron
cat << EOF >> $controlneutron
[DEFAULT]
[DEFAULT]
verbose = True

rpc_backend = rabbit
auth_strategy = keystone

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True

notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://$CON_MGNT_IP:8774/v2


[matchmaker_redis]
[matchmaker_ring]
[quotas]
[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = neutron
password = $NEUTRON_PASS



[database]
connection = mysql://neutron:$NEUTRON_DBPASS@$CON_MGNT_IP/neutron


[nova]
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
region_name = RegionOne
project_name = service
username = nova
password = $NOVA_PASS

[oslo_concurrency]
lock_path = \$state_path/lock
[oslo_policy]
[oslo_messaging_amqp]
[oslo_messaging_qpid]

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

EOF


######## Backup configuration of ML2 in $CON_MGNT_IP##################"
echo "########## Configuring ML2 in $CON_MGNT_IP/NETWORK node ##########"
sleep 7

controlML2=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $controlML2.orig || cp $controlML2 $controlML2.orig
rm $controlML2
touch $controlML2

cat << EOF >> $controlML2
[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
EOF


su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  
echo "########## Restarting NOVA service ##########"
sleep 7 
service nova-api restart
service nova-scheduler restart
service nova-conductor restart

echo "########## Restarting NEUTRON service ##########"
sleep 7 
service neutron-server restart
