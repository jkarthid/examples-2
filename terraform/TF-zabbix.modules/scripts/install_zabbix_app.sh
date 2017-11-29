#!/bin/bash

# Install server
yum install -y http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
yum install -y zabbix-server-mysql mariadb

# Configure server
cat > /etc/zabbix/zabbix_server.conf << '_EOF'
DBHost=${zabbix_db_private_addr}
DBName=${zabbix_db_name}
DBUser=${zabbix_db_user}
DBPassword=${zabbix_db_password}
LogFile=/var/log/zabbix/zabbix_server.log
LogFileSize=0
PidFile=/var/run/zabbix/zabbix_server.pid
SocketDir=/var/run/zabbix
Timeout=4
AlertScriptsPath=/usr/lib/zabbix/alertscripts
ExternalScripts=/usr/lib/zabbix/externalscripts
LogSlowQueries=3000
_EOF


for i in {1..10}; do
    echo "select 1"| mysql -u zabbix -p${zabbix_db_password} -h ${zabbix_db_private_addr}
    if [ $? == 1 ]; then
        sleep 10s
        continue
    else
        zcat /usr/share/doc/zabbix-server-mysql-3.4.4/create.sql.gz | mysql -u zabbix -p${zabbix_db_password} -h ${zabbix_db_private_addr} zabbix
        break
    fi
done

setsebool -P zabbix_can_network=on

cat > /tmp/zabbix_server_setrlimit.te << 'EOF'
module zabbix_server_setrlimit 1.0;

require {
	type zabbix_t;
	class process setrlimit;
}

#============= zabbix_agent_t ==============
allow zabbix_t self:process setrlimit;
# semodule -i zabbix_server_setrlimit.pp
# systemctl start zabbix-server
EOF

checkmodule -M -m -o /tmp/zabbix_server_setrlimit.mod /tmp/zabbix_server_setrlimit.te
semodule_package -o /tmp/zabbix_server_setrlimit.pp -m /tmp/zabbix_server_setrlimit.mod
semodule -i /tmp/zabbix_server_setrlimit.pp


cat > /tmp/zabbix_server_socket.te << 'EOF'

module zabbix_server_socket 1.0;

require {
	type zabbix_var_run_t;
	type zabbix_t;
	class sock_file create;
	class sock_file unlink;
	class unix_stream_socket connectto;
}

#============= zabbix_t ==============
allow zabbix_t zabbix_var_run_t:sock_file create;
allow zabbix_t self:unix_stream_socket connectto;
allow zabbix_t zabbix_var_run_t:sock_file unlink;
EOF

checkmodule -M -m -o /tmp/zabbix_server_socket.mod /tmp/zabbix_server_socket.te
semodule_package -o /tmp/zabbix_server_socket.pp -m /tmp/zabbix_server_socket.mod
semodule -i /tmp/zabbix_server_socket.pp


systemctl start zabbix-server
systemctl enable zabbix-server