output bastion_private_ip {
  value = "${module.bastion_ec2.private_ip}"
}

output bastion_public_ip {
  value = "${module.bastion_ec2.public_ip}"
}

output zabbix_web_elb_dns_name {
  value = "${module.zabbix_web_elb.this_elb_dns_name}"
}

output zabbix_app_elb_dns_name {
  value = "${module.zabbix_app_elb.this_elb_dns_name}"
}

output zabbix_db_private_ip {
  value = "${module.zabbix_db.this_db_instance_address}"
}
