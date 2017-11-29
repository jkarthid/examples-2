terraform {
  backend "s3" {
    bucket = "fstate-terraform-file"
    key = "demo1/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region                  = "${var.aws_region}"
  shared_credentials_file = "${var.aws_credentials}"
  profile                 = "${var.aws_profile}"
}

###
## create network
###
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}"
  cidr = "${var.vpc_cidr}"

  azs = "${var.vpc_azs}"

  public_subnets   = "${var.public_subnets}"
  database_subnets = "${var.database_subnets}"

  create_database_subnet_group = false

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags {
    Terraform   = "true"
    Environment = "stage"
  }
}

###
## create security groups
###
module "zabbix_web_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "zabbix_web_sg"
  description = "security group for zabbix web fronend"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = "${module.vpc.public_subnets_cidr_blocks}"
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_web"
  }
}

module "zabbix_app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "zabbix_app_sg"
  description = "security group for zabbix server"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_with_cidr_blocks = [
    {
      from_port   = "${var.zabbix_app_listen_port}"
      to_port     = "${var.zabbix_app_listen_port}"
      protocol    = "tcp"
      description = "zabbix server"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
    {
      from_port   = "${var.zabbix_app_snmp_port}"
      to_port     = "${var.zabbix_app_snmp_port}"
      protocol    = "udp"
      description = "zabbix server snmp"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_app"
  }
}

module "zabbix_lb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "zabbix_lb_sg"
  description = "zabbix load balancer security group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_lb"
  }
}

module "zabbix_lb_app_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "zabbix_lb_app_sg"
  description = "zabbix load balancer security group"
  vpc_id      = "${module.vpc.vpc_id}"

  egress_with_cidr_blocks = [
    {
      from_port   = "${var.zabbix_app_listen_port}"
      to_port     = "${var.zabbix_app_listen_port}"
      protocol    = "tcp"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
    {
      from_port   = "${var.zabbix_app_snmp_port}"
      to_port     = "${var.zabbix_app_snmp_port}"
      protocol    = "tcp"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = "${var.zabbix_app_listen_port}"
      to_port     = "${var.zabbix_app_listen_port}"
      protocol    = "tcp"
      description = "zabbix server"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
    {
      from_port   = "${var.zabbix_app_snmp_port}"
      to_port     = "${var.zabbix_app_snmp_port}"
      protocol    = "udp"
      description = "zabbix server snmp"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_lb"
  }
}

module "zabbix_db_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "zabbix_db_sg"
  description = "security group for zabbix database"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = "${module.vpc.public_subnets_cidr_blocks}"
  ingress_rules       = ["mysql-tcp"]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_db"
  }
}

module "bastion_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "bastion_sg"
  description = "bastion security group"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "bastion"
    Subsystem   = "sshd"
  }
}

module "allow_ingress_from_bastion" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = "allow_ingress_from_bastion"
  description = "allow incomming connections from bastion host"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["${format("%s/32",module.bastion_ec2.private_ip[0])}"]
  ingress_rules       = ["ssh-tcp"]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "bastion"
    Subsystem   = "sshd"
  }
}

module "allow_egress_all" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow_egress_all"
  description = "allow all egress traffic"
  vpc_id      = "${module.vpc.vpc_id}"

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "NA"
    Subsystem   = "NA"
  }
}

module "allow_egress_public_subnets" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow_egress_public_subnets"
  description = "allow all egress traffic from public subnets"
  vpc_id      = "${module.vpc.vpc_id}"

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "${join(",", module.vpc.public_subnets_cidr_blocks)}"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_db"
  }
}

###
## create instances
###

module "zabbix_app_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "zabbix_app_asg"

  # Launch configuration
  lc_name                     = "${var.zabbix_app_lc_name}"
  image_id                    = "${data.aws_ami.centos.id}"
  instance_type               = "${var.default_instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.default_key_name}"

  security_groups = [
    "${module.zabbix_app_sg.this_security_group_id}",
    "${module.allow_egress_all.this_security_group_id}",
    "${module.allow_ingress_from_bastion.this_security_group_id}",
  ]

  user_data = "${data.template_file.zabbix_app_init.rendered}"

  load_balancers = ["${module.zabbix_app_elb.this_elb_id}"]

  # Auto scaling group
  asg_name                  = "${var.zabbix_app_asg_name}"
  vpc_zone_identifier       = "${module.vpc.public_subnets}"
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "stage"
      propagate_at_launch = true
    },
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Service"
      value               = "zabbix"
      propagate_at_launch = true
    },
    {
      key                 = "Subsystem"
      value               = "zabbix_app"
      propagate_at_launch = true
    },
  ]
}

module "zabbix_web_asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name = "zabbix_web_asg"

  # Launch configuration
  lc_name                     = "${var.zabbix_web_lc_name}"
  image_id                    = "${data.aws_ami.centos.id}"
  instance_type               = "${var.default_instance_type}"
  associate_public_ip_address = true
  key_name                    = "${var.default_key_name}"

  security_groups = [
    "${module.zabbix_web_sg.this_security_group_id}",
    "${module.allow_egress_all.this_security_group_id}",
    "${module.zabbix_lb_app_sg.this_security_group_id}",
    "${module.allow_ingress_from_bastion.this_security_group_id}",
  ]

  user_data = "${data.template_file.zabbix_web_init.rendered}"

  load_balancers = ["${module.zabbix_web_elb.this_elb_id}"]

  # auto scaling group
  asg_name                  = "${var.zabbix_web_asg_name}"
  vpc_zone_identifier       = "${module.vpc.public_subnets}"
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "stage"
      propagate_at_launch = true
    },
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Service"
      value               = "zabbix"
      propagate_at_launch = true
    },
    {
      key                 = "Subsystem"
      value               = "zabbix_web"
      propagate_at_launch = true
    },
  ]
}

module "bastion_ec2" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name  = "${var.bastion_ec2_name}"
  count = 1

  ami                         = "${data.aws_ami.centos.id}"
  instance_type               = "${var.default_instance_type}"
  key_name                    = "${var.default_key_name}"
  monitoring                  = false
  associate_public_ip_address = true

  subnet_id = "${module.vpc.public_subnets[0]}"

  vpc_security_group_ids = [
    "${module.bastion_sg.this_security_group_id}",
    "${module.allow_egress_all.this_security_group_id}",
    "${module.allow_ingress_from_bastion.this_security_group_id}",
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "bastion"
    Subsystem   = "sshd"
  }
}

###
## load balancers
##

module "zabbix_web_elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "${var.zabbix_web_elb_name}"

  subnets = "${module.vpc.public_subnets}"

  security_groups = [
    "${module.zabbix_lb_sg.this_security_group_id}",
    "${module.allow_egress_all.this_security_group_id}",
  ]

  internal = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
  ]

  health_check = [
    {
      target              = "HTTP:80/zabbix/"
      interval            = "${var.zabbix_web_elb_hc_interval}"
      healthy_threshold   = "${var.zabbix_web_elb_hc_healthy_threshold}"
      unhealthy_threshold = "${var.zabbix_web_elb_hc_unhealthy_threshold}"
      timeout             = "${var.zabbix_web_elb_hc_timeout}"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_web"
  }
}

module "zabbix_app_elb" {
  source = "terraform-aws-modules/elb/aws"

  name = "${var.zabbix_app_elb_name}"

  subnets = "${module.vpc.public_subnets}"

  security_groups = [
    "${module.zabbix_lb_app_sg.this_security_group_id}",
  ]

  internal = true

  listener = [
    {
      instance_port     = "${var.zabbix_app_listen_port}"
      instance_protocol = "TCP"
      lb_port           = "${var.zabbix_app_listen_port}"
      lb_protocol       = "TCP"
    },
  ]

  health_check = [
    {
      target              = "${format("TCP:%s", var.zabbix_app_listen_port)}"
      interval            = "${var.zabbix_app_elb_hc_interval}"
      healthy_threshold   = "${var.zabbix_app_elb_hc_healthy_threshold}"
      unhealthy_threshold = "${var.zabbix_app_elb_hc_unhealthy_threshold}"
      timeout             = "${var.zabbix_app_elb_hc_timeout}"
    },
  ]

  tags {
    Terraform   = "true"
    Environment = "stage"
    Service     = "zabbix"
    Subsystem   = "zabbix_app"
  }
}

module "zabbix_db" {
  source     = "terraform-aws-modules/rds/aws"
  identifier = "zabbix-db"

  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "${var.zabbix_db_instance_type}"
  allocated_storage = 5
  storage_encrypted = false

  name     = "${var.zabbix_db_name}"
  username = "${var.zabbix_db_username}"
  password = "${var.zabbix_db_password}"
  port     = "${var.zabbix_db_port}"

  vpc_security_group_ids = [
    "${module.zabbix_db_sg.this_security_group_id}",
    "${module.allow_egress_public_subnets.this_security_group_id}",
    "${module.allow_ingress_from_bastion.this_security_group_id}",
  ]

  backup_retention_period = "${var.zabbix_db_backup_retention_period}"
  maintenance_window      = "${var.zabbix_db_maintence_window}"
  backup_window           = "${var.zabbix_db_backup_window}"

  subnet_ids = "${module.vpc.database_subnets}"

  family = "mysql5.7"
}
