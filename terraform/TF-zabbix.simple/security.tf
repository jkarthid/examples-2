# BEGIN: Sec Groups
resource "aws_security_group" "sg_allow_internet" {
    name = "sg_allow_internet"
    description = "allow all outcomming traffic"
    vpc_id = "${aws_vpc.default.id}"

    # allow internet access, but block all incoming traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.cidr_block_internet}"]
    }
}

resource "aws_security_group" "sg_bastion" {
    name = "sg_bastion"
    description = "allow traffic on bastion host"
    vpc_id = "${aws_vpc.default.id}"

    # allow sshd connection
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_internet}"]
    }
}


resource "aws_security_group" "sg_admin" {
    name = "sg_allow_bhost_traffic"
    description = "allow all traffic from bastion host"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.cidr_block_for_bhost}"]
    }
}

resource "aws_security_group" "sg_lb2app" {
    name = "sg_allow_lb_to_app"
    description = "allow traffic from load balancer and to load balancer"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = "${var.web_http_port}"
        to_port = "${var.web_http_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_for_lb}"]
    }

    ingress {
        from_port = "${var.web_https_port}"
        to_port = "${var.web_https_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_for_lb}"]
    }
}

resource "aws_security_group" "elb" {
    name = "sg_elb"
    description = "elb security group"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = "${var.elb_listen_http_port}"
        to_port = "${var.elb_listen_http_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_internet}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${var.cidr_block_internet}"]
    }
}

resource "aws_security_group" "sg_app2db" {
    name = "sg_allow_app_to_db"
    description = "allow traffic from app hosts to databases"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = "${var.db_port}"
        to_port = "${var.db_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_for_app}"]
    }
}

resource "aws_security_group" "sg_web2app" {
    name = "sg_allow_web_to_app"
    description = "allow traffic from app hosts to databases"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = "${var.app_port}"
        to_port = "${var.app_port}"
        protocol = "tcp"
        cidr_blocks = ["${var.cidr_block_for_app}"]
    }
}

# END: Sec Groups
