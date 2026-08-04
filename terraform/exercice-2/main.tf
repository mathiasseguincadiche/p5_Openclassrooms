# =============================================================================
# EXERCICE 2 : Domaine Amazon OpenSearch
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_opensearch_domain" "p5" {
  domain_name    = "p5-opensearch"
  engine_version = "OpenSearch_2.19"

  cluster_config {
    instance_type            = "t3.small.search"
    instance_count           = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/p5-opensearch/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [var.your_ip_cidr]
          }
        }
      }
    ]
  })

  tags = {
    Domain   = "p5-opensearch"
    Project  = "p5-openclassrooms"
    Exercice = "2"
  }
}
