output "vpc_id" {
  description = "ID of the StartupTech VPC"
  value       = aws_vpc.main.id
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion EC2"
  value       = aws_eip.bastion.public_ip
}

output "backend_private_ip" {
  description = "Private IP address of the Backend EC2"
  value       = aws_instance.backend.private_ip
}

output "mongodb_private_ip" {
  description = "Private IP address of the MongoDB EC2"
  value       = aws_instance.mongodb.private_ip
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}