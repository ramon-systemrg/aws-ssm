#!/usr/bin/env bash

HOSTNAME=web1
IP=10.1.10.201
MANAGER_IP=10.1.10.199
ZABBIXSERVER=10.1.10.60
SALTMASTER_IP=10.1.10.61
SALTMASTER_NAME=saltmaster

echo ''
echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo "  Setting up: $HOSTNAME"
echo ' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
echo ''


echo "$IP $HOSTNAME" >> /etc/hosts
echo "$SALTMASTER_IP $SALTMASTER_NAME" >> /etc/hosts

# Install Amazon SSM Agent
curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm -o /tmp/amazon-ssm-agent.rpm
yum install -y /tmp/amazon-ssm-agent.rpm


# Install epel-release and basic tools.
echo '- Installing epel-release and updating repositories...'
yum clean all
yum install epel-release -y
#yum update -y
yum -y groupinstall "Development Tools"
yum -y install net-tools fping git jq zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel expat-devel

# Disable selinux
sed -i s/=enforcing/=disabled/g /etc/sysconfig/selinux
sed -i s/=permissive/=disabled/g /etc/sysconfig/selinux
yum -y remove firewalld

# Setup chronyd
yum -y install chrony

CCONF=$(cat <<EOF

server 10.1.10.2 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
log measurements statistics tracking

EOF
)
echo "${CCONF}" > /etc/chrony.conf
systemctl restart chronyd
systemctl enable chronyd


# Setup zabbix agent config
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum -y install zabbix-agent

ZCONF=$(cat <<EOF

PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$ZABBIXSERVER
ServerActive=127.0.0.1,$ZABBIXSERVER
Hostname=$HOSTNAME
Include=/etc/zabbix/zabbix_agentd.d/*.conf

EOF
)
echo "${ZCONF}" > /etc/zabbix/zabbix_agentd.conf
systemctl restart zabbix-agent
systemctl enable zabbix-agent


# ---------------
# Install salt
# ---------------

echo '- Installing salt-minion...'
rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo
yum -y install salt-minion
systemctl start salt-minion
systemctl enable salt-minion


# ---------------
#  Apache
# ---------------

echo '- Installing httpd...'
yum install -y httpd
echo '...done'
echo '- Setting up Apache virtual host...'

# Setup hosts file

VHOST=$(cat <<EOF
<VirtualHost *:80>
        ServerName localhost
        DocumentRoot "/var/www"
        <Directory "/var/www">
                Options +ExecCGI -Indexes +Includes -FollowSymLinks +SymLinksIfOwnerMatch +MultiViews
        AllowOverride All
        Order allow,deny
        Allow from all
        </Directory>
        ErrorLog /var/log/httpd/error.log
    CustomLog /var/log/httpd/access.log combined
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/httpd/conf.d/default.conf

yum -y install mod_ssl openssl

cd /etc/httpd/conf

# Generate Self Signed Key
openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=UT/L=SLC/O=Dis/CN=www.example.com" \
    -keyout ca.key \
    -out ca.cert

# Restart apache
systemctl restart httpd
systemctl enable httpd
echo '...done'

# Install html healthcheck page.
mkdir -p /var/www/html/health

HEALTHCHECK=$(cat <<EOF

<HTML>
  <HEAD>
    <TITLE>Health Check</TITLE>
  </HEAD>
  <BODY>
    <H1>Health Check OK</H1>
  </BODY>
</HTML>

EOF
)
echo "${HEALTHCHECK}" > /var/www/html/health/index.html


service httpd restart
echo '...done'


# -------------
# Install wazuh agent
# -------------

rpm --import http://packages.wazuh.com/key/GPG-KEY-WAZUH

WAZUHAGENT=$(cat <<EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=Wazuh repository
baseurl=https://packages.wazuh.com/3.x/yum/
protect=1

EOF
)
echo "${WAZUHAGENT}" > /etc/yum.repos.d/wazuh.repo
yum install -y wazuh-agent
sed -i s/MANAGER_IP/10.1.10.199/ /var/ossec/etc/ossec.conf

# Remove the old agent key from wazuh-manager then re-add it for this new host invokation.

agent_ERR=$(curl -s -u foo:bar -k -X GET "https://$MANAGER_IP:55000/agents/name/$HOSTNAME" |jq --raw-output '.error')
echo "err: $agent_ERR"

# If error returns 0 then there is an existing entry for this host. Remove it and add a new entry.
if [ "$agent_ERR" == 0 ]
then
  agent_old_ID=$(curl -s -u foo:bar -k -X GET "https://$MANAGER_IP:55000/agents/name/$HOSTNAME" |jq --raw-output '.data.id')
  curl -s -u foo:bar -k -X DELETE "https://$MANAGER_IP:55000/agents/$agent_old_ID?pretty&purge"
fi

new_agent_id=$(curl -s -u foo:bar -k -X POST -d "{\"name\":\"$HOSTNAME\",\"ip\":\"$IP\"}" -H 'Content-Type:application/json' "https://$MANAGER_IP:55000/agents?pretty" |jq --raw-output '.data.key')

echo "$new_agent_id"

printf 'y' | /var/ossec/bin/manage_agents -i $new_agent_id

systemctl enable wazuh-agent
systemctl start wazuh-agent


echo 'provision script done...'
