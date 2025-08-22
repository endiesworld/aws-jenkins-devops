output "app_instance_id" {
  value       = aws_instance.app_server.id
  description = "ID of the app EC2 instance"
}

output "ec2_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "Public IP of the app EC2 instance"
}

output "app_public_dns" {
  value       = aws_instance.app_server.public_dns
  description = "Public DNS of the app EC2 instance"
}

output "app_security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "Security group ID for the app EC2 instance"
}
