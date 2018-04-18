# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

variable “server_port” {
 description = “The port the server will use for SSH requests”
 default = 22
}

# CONFIGURE OUR AWS CONNECTION
provider “aws” {
 region = “us-east-1”
}

resource “aws_instance” “example” {
 # Ubuntu Server 14.04 LTS (HVM), SSD Volume Type in us-east-1
 ami = “ami-2d39803a”
 instance_type = “t2.small”
 vpc_security_group_ids = [“${aws_security_group.instance.id}“]
}

# CREATE THE SECURITY GROUP THAT’S APPLIED TO THE EC2 INSTANCE
resource “aws_security_group” “instance” {
 name = “terraform-example-instance”

 # Inbound SSH from anywhere
 ingress {
   from_port = “${var.server_port}“
   to_port = “${var.server_port}“
   protocol = “tcp”
   cidr_blocks = [“0.0.0.0/0”]
 }
}

output “public_ip” {
 value = “${aws_instance.example.public_ip}“
}

output “instance_id” {
 value = “aws_instance.instance.*.id}”
}
