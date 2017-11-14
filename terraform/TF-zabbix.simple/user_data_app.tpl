#!/bin/bash
yum install -y http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
yum install -y zabbix-web-mysql.noarch
setsebool -P httpd_can_network_connect_db=on
setsebool -P httpd_can_connect_zabbix=on
mkdir -p /etc/zabbix/web/
chown apache:apache /etc/zabbix/web

cat > /etc/zabbix/web/zabbix.conf.php << '_END'
<?php
// Zabbix GUI configuration file.
global $$DB;
$$DB['TYPE']				= 'MYSQL';
$$DB['SERVER']			= '${db_private_addr}';
$$DB['PORT']				= '${db_port}';
$$DB['DATABASE']			= 'zabbix';
$$DB['USER']				= 'zabbix';
$$DB['PASSWORD']			= '${db_password}';
// Schema name. Used for IBM DB2 and PostgreSQL.
$$DB['SCHEMA']			= '';
$$ZBX_SERVER				= '${zbx_private_addr}';
$$ZBX_SERVER_PORT		= '10051';
$$ZBX_SERVER_NAME		= '';
$$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
_END
chmod +x /etc/zabbix/web/zabbix.conf.php
chown apache:apache /etc/zabbix/web/zabbix.conf.php
yum install -y epel-release
yum install -y crudini.noarch
crudini --set /etc/php.ini Date date.timezone Europe/Moscow
systemctl start httpd