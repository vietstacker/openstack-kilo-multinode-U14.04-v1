#!/bin/bash -ex
#
# Khoi tao bien
# TOKEN_PASS=a
# MYSQL_PASS=a
# ADMIN_PASS=a
source config.cfg
# disable the keystone service from starting automatically after installation
echo "manual" > /etc/init/keystone.override

echo "##### Install keystone #####"
# apt-get -y install keystone python-keystoneclient 
apt-get -y install keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache


#/* Back-up file nova.conf
filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig

#Config file /etc/keystone/keystone.conf
cat << EOF > $filekeystone
[DEFAULT]
log_dir = /var/log/keystone
verbose = True
admin_token = $TOKEN_PASS

[assignment]
[auth]
[cache]
[catalog]
[credential]
[database]
connection = mysql://keystone:$KEYSTONE_DBPASS@$CON_MGNT_IP/keystone


# connection = sqlite:////var/lib/keystone/keystone.db
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[eventlet_server_ssl]
[federation]
[fernet_tokens]
[identity]
[identity_mapping]
[kvs]
[ldap]
[matchmaker_redis]
[matchmaker_ring]
[memcache]
servers = localhost:11211

[oauth1]
[os_inherit]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
[policy]
[resource]
[revoke]
[role]
driver = keystone.contrib.revoke.backends.sql.Revoke

[saml]
[signing]
[ssl]
[token]
provider = keystone.token.providers.uuid.Provider
driver = keystone.token.persistence.backends.memcache.Token

[trust]
[extra_headers]
Distribution = Ubuntu


EOF

#
echo "##### Remove keystone default db #####"
rm  /var/lib/keystone/keystone.db

echo "##### Restarting keystone service #####"
service keystone restart
sleep 3
service keystone restart

echo "##### Syncing keystone DB #####"
sleep 3
su -s /bin/sh -c "keystone-manage db_sync" keystone

#(crontab -l -u keystone 2>&1 | grep -q token_flush) || \
#echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/keystone

# Cau hinh Apache 
echo "##### Config apache #####"
sed -e '\/#ServerRoot \"\/etc\/apache2\"/a ServerName controller' /etc/apache2/apache2.conf

