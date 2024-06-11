output "alb_dns_name" {
  value       = aws_lb.webserver-cluster.dns_name
  description = "value of the ALB DNS Name"
}

output "asg_name" {
  value       = aws_autoscaling_group.webserver-cluster.name
  description = "Name of the auto scaling group"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB Security Group ID"
}
