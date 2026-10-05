output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.app[*].id
}

output "private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.app[*].private_ip
}

output "public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.app[*].public_ip
}

output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2.id
}
