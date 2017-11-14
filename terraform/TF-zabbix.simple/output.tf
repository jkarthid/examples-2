output "database" {
    value = "${aws_instance.db.public_ip}"
}

output "bastion" {
    value = "${aws_instance.bhost.public_ip}"
}

output "elb_frontend" {
  value = "${aws_elb.frontend_lb.dns_name}"
}

# output "rendered_payload" {
#   value  = "${data.template_file.app_payload.rendered}"
# }

output "private_db_addr" {
    value = "${aws_instance.db.private_ip}"
}

output "private_bastion_addr" {
    value = "${aws_instance.bhost.private_ip}"
}

output "private_app_addr" {
  value = "${aws_instance.app.private_ip}"
}