# =============================================================================
# EXERCICE 3 : Outputs Terraform
# =============================================================================

output "hello_1_public_ip" {
  description = "IP publique du premier serveur hello"
  value       = aws_instance.p5_hello[0].public_ip
}

output "hello_2_public_ip" {
  description = "IP publique du second serveur hello"
  value       = aws_instance.p5_hello[1].public_ip
}

output "hello_1_private_ip" {
  description = "IP privée du premier serveur hello"
  value       = aws_instance.p5_hello[0].private_ip
}

output "hello_2_private_ip" {
  description = "IP privée du second serveur hello"
  value       = aws_instance.p5_hello[1].private_ip
}

output "haproxy_public_ip" {
  description = "IP publique de HAProxy"
  value       = aws_instance.p5_haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "IP privée de HAProxy"
  value       = aws_instance.p5_haproxy.private_ip
}

output "haproxy_public_dns" {
  description = "Nom DNS public de HAProxy"
  value       = aws_instance.p5_haproxy.public_dns
}

output "haproxy_security_group_id" {
  description = "Identifiant du groupe de sécurité HAProxy"
  value       = aws_security_group.p5_haproxy_sg.id
}

output "haproxy_url" {
  description = "URL publique du répartiteur"
  value       = "http://${aws_instance.p5_haproxy.public_ip}"
}

output "haproxy_stats_url" {
  description = "URL de la page de statistiques, accessible uniquement depuis your_ip_cidr"
  value       = "http://${aws_instance.p5_haproxy.public_ip}:8404/stats"
}
