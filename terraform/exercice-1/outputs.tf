# =============================================================================
# EXERCICE 1 : Outputs Terraform
# =============================================================================

output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.p5_vpc.id
}

output "public_subnet_a_id" {
  description = "ID du subnet public A"
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "ID du subnet public B"
  value       = aws_subnet.public_subnet_b.id
}

output "nginx_security_group_id" {
  description = "ID du Security Group pour NGINX"
  value       = aws_security_group.nginx_sg.id
}

output "nginx_1_public_ip" {
  description = "IP publique de l'instance NGINX-1"
  value       = aws_instance.nginx_1.public_ip
}

output "nginx_1_private_ip" {
  description = "IP privée de l'instance NGINX-1"
  value       = aws_instance.nginx_1.private_ip
}

output "nginx_2_public_ip" {
  description = "IP publique de l'instance NGINX-2"
  value       = aws_instance.nginx_2.public_ip
}

output "nginx_2_private_ip" {
  description = "IP privée de l'instance NGINX-2"
  value       = aws_instance.nginx_2.private_ip
}

output "nginx_1_public_dns" {
  description = "DNS public de l'instance NGINX-1"
  value       = aws_instance.nginx_1.public_dns
}

output "nginx_2_public_dns" {
  description = "DNS public de l'instance NGINX-2"
  value       = aws_instance.nginx_2.public_dns
}

output "nginx_1_url" {
  description = "URL pour accéder à NGINX-1"
  value       = "http://${aws_instance.nginx_1.public_ip}"
}

output "nginx_2_url" {
  description = "URL pour accéder à NGINX-2"
  value       = "http://${aws_instance.nginx_2.public_ip}"
}
