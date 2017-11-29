data "template_file" "zabbix_app_init" {
  template = "${file("${path.module}/scripts/install_zabbix_app.sh")}"

  vars = {
    zabbix_db_private_addr = "${module.zabbix_db.this_db_instance_address}"
    zabbix_db_password = "${var.zabbix_db_password}"
    zabbix_db_name = "zabbix"
    zabbix_db_user = "zabbix"
  }
}

data "template_file" "zabbix_web_init" {
  template = "${file("${path.module}/scripts/install_zabbix_web.sh")}"

  vars = {
    zabbix_db_private_addr = "${module.zabbix_db.this_db_instance_address}"
    zabbix_db_port = "${var.zabbix_db_port}"
    zabbix_db_password = "${var.zabbix_db_password}"
    zabbix_app_server_addr = "${module.zabbix_app_elb.this_elb_dns_name}"
  }
}