# =============================================================================
# EXERCICE 3 : Outputs Terraform
# =============================================================================

output "haproxy_public_ip" {
  description = "IP publique de l'instance HAProxy"
  value       = aws_instance.haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "IP privée de l'instance HAProxy"
  value       = aws_instance.haproxy.private_ip
}

output "haproxy_public_dns" {
  description = "DNS public de l'instance HAProxy"
  value       = aws_instance.haproxy.public_dns
}

output "haproxy_eip" {
  description = "Elastic IP de l'instance HAProxy"
  value       = aws_eip.haproxy_eip.public_ip
}

output "haproxy_security_group_id" {
  description = "ID du Security Group pour HAProxy"
  value       = aws_security_group.haproxy_sg.id
}

output "haproxy_url" {
  description = "URL pour accéder à HAProxy"
  value       = "http://${aws_eip.haproxy_eip.public_ip}"
}

output "haproxy_stats_url" {
  description = "URL pour les statistiques HAProxy"
  value       = "http://${aws_eip.haproxy_eip.public_ip}:8404"
}
