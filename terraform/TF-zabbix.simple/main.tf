provider "aws" {
    region = "${var.aws_region}"
    shared_credentials_file = "/Users/dhelios/.aws/credentials"
    profile = "myprofile"
}

# BEGIN: Instances
resource "aws_instance" "bhost" {
    ami = "${data.aws_ami.centos.id}"
    instance_type = "${var.bhost_inst_type}"
    subnet_id = "${aws_subnet.subnet_for_bhost.id}"
    key_name = "${var.default_keyname}"
    vpc_security_group_ids = [
        "${aws_security_group.sg_allow_internet.id}", 
        "${aws_security_group.sg_bastion.id}"
    ]

    monitoring = false

    count = "${var.bhost_inst_count}"

    tags {
        Name = "Bastion Host"
    }
}


resource "aws_instance" "app" {
    ami = "${data.aws_ami.centos.id}"
    instance_type = "${var.app_inst_type}"
    subnet_id = "${aws_subnet.subnet_for_app.id}"
    key_name = "${var.default_keyname}"
    vpc_security_group_ids = [
        "${aws_security_group.sg_allow_internet.id}", 
        "${aws_security_group.sg_bastion.id}",
        "${aws_security_group.sg_web2app.id}" 
    ]

    monitoring = false

    count = "${var.app_inst_count}"

    user_data = <<-EOF
                #!/bin/bash
                yum install -y http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
                yum install -y zabbix-server-mysql.x86_64 policycoreutils.x86_64 policycoreutils-devel
                setenforce 0
                cat > /etc/zabbix/zabbix_server.conf<<'_END'
                LogFile=/var/log/zabbix/zabbix_server.log
                LogFileSize=0
                PidFile=/var/run/zabbix/zabbix_server.pid
                SocketDir=/var/run/zabbix
                DBName=zabbix
                DBUser=zabbix
                DBHost=${aws_instance.db.private_ip}
                DBPassword=${var.db_password}
                SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
                Timeout=4
                AlertScriptsPath=/usr/lib/zabbix/alertscripts
                ExternalScripts=/usr/lib/zabbix/externalscripts
                LogSlowQueries=3000
                _END
                cat > /tmp/zabbix-policy.te <<'_END'
                module zabbix-policy 1.0;
                require {
                    type mysqld_port_t;
                    type zabbix_var_run_t;
                    type zabbix_t;
                    class sock_file create;
                    class tcp_socket name_connect;
                    class process setrlimit;
                    class unix_stream_socket connectto;
                }
                #============= zabbix_t ==============
                allow zabbix_t mysqld_port_t:tcp_socket name_connect;
                allow zabbix_t self:process setrlimit;
                
                allow zabbix_t self:unix_stream_socket connectto;
                allow zabbix_t zabbix_var_run_t:sock_file create;
                _END
                checkmodule -M -m -o /tmp/zabbix-policy.mod /tmp/zabbix-policy.te
                semodule_package -o /tmp/zabbix-policy.pp -m /tmp/zabbix-policy.mod
                semodule -i /tmp/zabbix-policy.pp
                systemctl start zabbix-server.service
                systemctl enable zabbix-server.service
                EOF

    tags {
        Name = "application"
    }

}

resource "aws_instance" "db" {
    ami = "${data.aws_ami.centos.id}"
    instance_type = "${var.db_inst_type}"
    subnet_id = "${aws_subnet.subnet_for_db.id}"
    key_name = "${var.default_keyname}"
    vpc_security_group_ids = [
        "${aws_security_group.sg_allow_internet.id}", 
        "${aws_security_group.sg_app2db.id}",
        "${aws_security_group.sg_admin.id}"
    ]

    user_data = <<-EOF
                #!/bin/bash
                yum install -y mariadb-server.x86_64
                echo mysql soft nofile ${var.mysql_nofile} >> /etc/security/limits.d/10-mysql.conf
                echo mysql hard nofile ${var.mysql_nofile} >> /etc/security/limits.d/10-mysql.conf
                sed -i -e '2ibind_address=0.0.0.0' /etc/my.cnf
                service mariadb start
                yum install -y http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-1.el7.centos.noarch.rpm
                yum install -y zabbix-server-mysql
                echo "create database zabbix" | mysql
                gunzip -c   /usr/share/doc/zabbix-server-mysql-3.4.4/create.sql.gz |mysql zabbix
                echo "create user 'zabbix'@'%' identified by '${var.db_password}';" | mysql zabbix
                echo "grant all privileges on zabbix.* to 'zabbix'@'%';" | mysql zabbix
                echo update zabbix.users set passwd=md5\(\'${var.db_password}\'\) where alias = \'Admin\' and name = \'Zabbix\' | mysql
                EOF

    monitoring = false

    count = "${var.db_inst_count}"

    tags {
        Name = "Database Host"
    }
}


data "template_file" "app_payload" {
    template = "${file("user_data_app.tpl")}"
    vars = {
        db_private_addr = "${aws_instance.db.private_ip}"
        db_password = "${var.db_password}"
        db_port = "${var.db_port}"
        zbx_private_addr = "${aws_instance.app.private_ip}"
    }
}

resource "aws_launch_configuration" "web_lc" {
    image_id = "${data.aws_ami.centos.id}"
    instance_type = "${var.web_inst_type}"
    security_groups  = [
            "${aws_security_group.sg_admin.id}",
            "${aws_security_group.sg_allow_internet.id}",
            "${aws_security_group.sg_lb2app.id}"
    ]

    key_name = "${var.default_keyname}"

    user_data = "${data.template_file.app_payload.rendered}"
    enable_monitoring = false

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "web_asg" {
    launch_configuration = "${aws_launch_configuration.web_lc.id}"
    min_size = "${var.web_inst_min_count}"
    max_size = "${var.web_inst_max_count}"

    vpc_zone_identifier = ["${aws_subnet.subnet_for_app.id}"]
    tag {
        key = "Name"
        value = "web-asg"
        propagate_at_launch = true
    }

    load_balancers = ["${aws_elb.frontend_lb.name}"]
    health_check_type = "ELB"

}


resource "aws_elb" "frontend_lb" {
    name = "frontendlb"
    security_groups = [ 
        "${aws_security_group.elb.id}"]
    subnets = ["${aws_subnet.subnet_for_lb.id}"]

    health_check {
        healthy_threshold = 2
        unhealthy_threshold = 2
        timeout = 3
        interval = 30
        target = "HTTP:${var.web_http_port}/zabbix/"
    }

    listener {
        lb_port = "${var.elb_listen_http_port}"
        lb_protocol = "http"
        instance_port = "${var.web_http_port}"
        instance_protocol = "http"
    }


}

# END: Instances