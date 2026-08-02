# =============================================================================
# EXERCICE 2 : Terraform - Déploiement d'un Cluster OpenSearch
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# Région AWS : us-east-1 (OBLIGATOIRE)
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration du Provider AWS
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.15.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Région OBLIGATOIRE pour ce projet
}

# -----------------------------------------------------------------------------
# Création du Domain OpenSearch (Cluster managé)
# -----------------------------------------------------------------------------
resource "aws_elasticsearch_domain" "p5_opensearch" {
  domain_name           = "p5-opensearch"
  elasticsearch_version = "7.10"  # Version compatible avec OpenSearch
  
  # Configuration du cluster
  cluster_config {
    instance_type          = "t3.medium.search"  # Minimum requis pour OpenSearch
    instance_count         = 1                   # 1 nœud pour le projet
    dedicated_master_enabled = false           # Pas de nœud master dédié
  }
  
  # Configuration du stockage
  ebs_options {
    ebs_enabled = true
    volume_size = 10  # 10 Go (gp3 par défaut)
    volume_type = "gp3"
  }
  
  # Configuration de l'accès
  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "es:*"
      ],
      "Resource": "arn:aws:es:us-east-1:${data.aws_caller_identity.current.account_id}:domain/p5-opensearch/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ["${var.your_ip_cidr}"]
        }
      }
    }
  ]
}
POLICY
  
  # Configuration des logs (optionnel)
  log_publishing_options {
    enabled                  = false
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.p5_opensearch_logs[0].arn
    log_type                 = "ES_APPLICATION_LOGS"
  }
  
  # Tags
  tags = {
    Domain   = "p5-opensearch"
    Project  = "p5-openclassrooms"
    Exercice = "2"
  }
  
  # Attendre que le domaine soit actif
  depends_on = [aws_iam_service_linked_role.es]
}

# -----------------------------------------------------------------------------
# Rôle IAM pour Elasticsearch Service (requis)
# -----------------------------------------------------------------------------
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group pour OpenSearch (optionnel)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "p5_opensearch_logs" {
  count = 1
  name              = "/aws/elasticsearch/p5-opensearch"
  retention_in_days = 7
}

# -----------------------------------------------------------------------------
# Récupération de l'account_id pour l'access policy
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Outputs
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
