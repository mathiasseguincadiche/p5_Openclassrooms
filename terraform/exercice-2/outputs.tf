# =============================================================================
# EXERCICE 2 : Outputs Terraform
# Fichier : outputs.tf
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs OpenSearch
# -----------------------------------------------------------------------------
output "opensearch_public_ip" {
  description = "IP publique de l'instance OpenSearch"
  value       = aws_instance.opensearch.public_ip
}

output "opensearch_private_ip" {
  description = "IP privée de l'instance OpenSearch"
  value       = aws_instance.opensearch.private_ip
}

output "opensearch_public_dns" {
  description = "DNS public de l'instance OpenSearch"
  value       = aws_instance.opensearch.public_dns
}

output "opensearch_eip" {
  description = "Elastic IP de l'instance OpenSearch"
  value       = aws_eip.opensearch_eip.public_ip
}

# -----------------------------------------------------------------------------
# Outputs Security Group
# -----------------------------------------------------------------------------
output "opensearch_security_group_id" {
  description = "ID du Security Group pour OpenSearch"
  value       = aws_security_group.opensearch_sg.id
}

# -----------------------------------------------------------------------------
# Outputs pour Ansible
# -----------------------------------------------------------------------------
output "opensearch_url" {
  description = "URL pour accéder à OpenSearch Dashboards"
  value       = "http://${aws_eip.opensearch_eip.public_ip}:9600"
}

output "opensearch_api_url" {
  description = "URL pour l'API OpenSearch"
  value       = "http://${aws_eip.opensearch_eip.public_ip}:9200"
}
