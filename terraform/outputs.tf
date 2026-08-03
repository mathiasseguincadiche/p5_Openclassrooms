# Sorties Terraform
output "instance_public_ip" {
  description = "Adresse IP publique de l'instance"
  value       = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  description = "DNS public de l'instance"
  value       = aws_instance.web_server.public_dns
}
