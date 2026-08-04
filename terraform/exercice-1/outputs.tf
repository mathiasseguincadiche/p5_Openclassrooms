output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.p5.id
}

output "public_subnet_ids" {
  description = "Sous-réseaux publics créés"
  value       = aws_subnet.public[*].id
}

output "web_security_group_id" {
  description = "Groupe de sécurité de la cible Ansible"
  value       = aws_security_group.web.id
}

output "web_public_ip" {
  description = "Adresse IPv4 publique de la cible Ansible"
  value       = aws_instance.web.public_ip
}

output "web_private_ip" {
  description = "Adresse IPv4 privée de la cible Ansible"
  value       = aws_instance.web.private_ip
}

output "web_public_dns" {
  description = "Nom DNS public de la cible Ansible"
  value       = aws_instance.web.public_dns
}

output "web_url" {
  description = "URL HTTP de l'application après exécution du playbook"
  value       = "http://${aws_instance.web.public_ip}"
}
