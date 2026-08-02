# =============================================================================
# EXERCICE 2 : Outputs Terraform
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs OpenSearch
# -----------------------------------------------------------------------------
output "opensearch_domain_name" {
  description = "Nom du domaine OpenSearch"
  value       = aws_elasticsearch_domain.p5_opensearch.domain_name
}

output "opensearch_endpoint" {
  description = "Endpoint du cluster OpenSearch"
  value       = aws_elasticsearch_domain.p5_opensearch.endpoint
}

output "opensearch_arn" {
  description = "ARN du domaine OpenSearch"
  value       = aws_elasticsearch_domain.p5_opensearch.arn
}

output "opensearch_kibana_endpoint" {
  description = "Endpoint Kibana (OpenSearch Dashboards)"
  value       = aws_elasticsearch_domain.p5_opensearch.kibana_endpoint
}
