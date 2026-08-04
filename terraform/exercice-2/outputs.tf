# =============================================================================
# EXERCICE 2 : Outputs OpenSearch
# =============================================================================

output "opensearch_domain_name" {
  description = "Nom du domaine OpenSearch"
  value       = aws_opensearch_domain.p5.domain_name
}

output "opensearch_endpoint" {
  description = "URL HTTPS du domaine OpenSearch"
  value       = "https://${aws_opensearch_domain.p5.endpoint}"
}

output "opensearch_arn" {
  description = "ARN du domaine OpenSearch"
  value       = aws_opensearch_domain.p5.arn
}

output "opensearch_dashboards_endpoint" {
  description = "URL d'OpenSearch Dashboards"
  value       = "https://${aws_opensearch_domain.p5.dashboard_endpoint}"
}
