# =============================================================================
# EXERCICE 3 : Outputs Terraform
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs HAProxy
# -----------------------------------------------------------------------------
output "haproxy_public_ip" {
  description = "IP publique de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "IP privée de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.private_ip
}

output "haproxy_public_dns" {
  description = "DNS public de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.public_dns
}

output "haproxy_security_group_id" {
  description = "ID du Security Group pour HAProxy"
  value       = aws_security_group.p5_haproxy_sg.id
}

# -----------------------------------------------------------------------------
# Outputs pour la configuration HAProxy
# -----------------------------------------------------------------------------
output "nginx_1_private_ip" {
  description = "IP privée de NGINX-1"
  value       = data.aws_instances.p5_nginx_instances.private_ips[0]
}

output "nginx_2_private_ip" {
  description = "IP privée de NGINX-2"
  value       = data.aws_instances.p5_nginx_instances.private_ips[1]
}

# -----------------------------------------------------------------------------
# URLs
# -----------------------------------------------------------------------------
output "haproxy_url" {
  description = "URL pour accéder à HAProxy"
  value       = "http://${aws_instance.p5_haproxy.public_ip}"
}

output "haproxy_stats_url" {
  description = "URL pour les statistiques HAProxy"
  value       = "http://${aws_instance.p5_haproxy.public_ip}:8404/stats"
}
