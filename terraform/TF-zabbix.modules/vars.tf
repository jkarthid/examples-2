# aws provider variables
variable "aws_region" {
  default = "us-west-2"
}

variable "aws_credentials" {
  default = "~/.aws/credentials"
}

variable "aws_profile" {
  default = "asdf"
}

# vpc variables
variable "vpc_name" {
  default = "zabbixVpc"
}

variable "vpc_cidr" {
  default = "192.168.128.0/20"
}

variable "vpc_azs" {
  type = "list"

  default = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c",
  ]
}

variable "public_subnets" {
  type = "list"

  default = [
    "192.168.128.0/24",
    "192.168.129.0/24",
    "192.168.130.0/24",
  ]
}

variable "database_subnets" {
  type = "list"

  default = [
    "192.168.131.0/24",
    "192.168.132.0/24",
  ]
}

variable "vpc_nat_gateway" {
  default = false
}

variable "vpc_vpn_gateway" {
  default = false
}

# security groups
variable "zabbix_app_listen_port" {
  default = 10051
}

variable "zabbix_app_snmp_port" {
  default = 161
}

# default ec2 related variables
variable "default_instance_type" {
  default = "t2.nano"
}

variable "default_key_name" {
  default = "asdf-devops-key"
}

# launch configurations
variable "zabbix_web_lc_name" {
  default = "zabbix-web-lc"
}

variable "zabbix_app_lc_name" {
  default = "zabbix-app-lc"
}

# autoscaling groups
variable "zabbix_web_asg_name" {
  default = "zabbix-web-asg"
}

variable "zabbix_app_asg_name" {
  default = "zabbix-app-asg"
}

# ec2 instances
variable "bastion_ec2_name" {
  default = "bastion"
}

# load balancers
variable "zabbix_web_elb_name" {
  default = "zabbix-web-elb"
}

variable "zabbix_web_elb_hc_interval" {
  default = 30
}

variable "zabbix_web_elb_hc_healthy_threshold" {
  default = 2
}

variable "zabbix_web_elb_hc_unhealthy_threshold" {
  default = 3
}

variable "zabbix_web_elb_hc_timeout" {
  default = 8
}


variable "zabbix_app_elb_name" {
  default = "zabbix-app-elb"
}

variable "zabbix_app_elb_hc_interval" {
  default = 30
}

variable "zabbix_app_elb_hc_healthy_threshold" {
  default = 2
}

variable "zabbix_app_elb_hc_unhealthy_threshold" {
  default = 3
}

variable "zabbix_app_elb_hc_timeout" {
  default = 8
}

# zabbix db
variable "zabbix_db_name" {
  default = "zabbix"
}

variable "zabbix_db_username" {
  default = "zabbix"
}

variable "zabbix_db_password" {
  default = "DB9B3667213E"
}

variable "zabbix_db_port" {
  default = 3306
}

variable "zabbix_db_backup_retention_period" {
  default = 0
}

variable "zabbix_db_maintence_window" {
  default = "Thu:00:00-Thu:03:00"
}

variable "zabbix_db_backup_window" {
  default = "13:00-16:00"
}

variable "zabbix_db_mysql_family" {
  default = "mysql5.7"
}

variable "zabbix_db_instance_type" {
  default = "db.t2.micro"
}
