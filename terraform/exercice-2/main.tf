# =============================================================================
# EXERCICE 2 : Domaine Amazon OpenSearch
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# La valeur de référence OpenSearch_2.19 reste configurable par tfvars.
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
  region              = var.aws_region
  allowed_account_ids = [var.expected_aws_account_id]

  default_tags {
    tags = {
      Project   = "p5-openclassrooms"
      ManagedBy = "Terraform"
      Purpose   = "training-lab"
      Exercise  = "2"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_opensearch_domain" "p5" {
  domain_name    = var.opensearch_domain_name
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type            = var.opensearch_instance_type
    instance_count           = 1
    dedicated_master_enabled = false
    zone_awareness_enabled   = false
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.opensearch_volume_size_gb
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
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = [var.your_ip_cidr]
          }
        }
      }
    ]
  })

  tags = {
    Domain = var.opensearch_domain_name
  }
}
