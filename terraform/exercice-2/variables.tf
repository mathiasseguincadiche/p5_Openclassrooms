variable "aws_region" {
  description = "Région AWS choisie pour le domaine OpenSearch"
  type        = string
  default     = "us-east-1"
}

variable "expected_aws_account_id" {
  description = "Identifiant du seul compte AWS autorisé pour ce module"
  type        = string

  validation {
    condition = (
      can(regex("^[0-9]{12}$", var.expected_aws_account_id)) &&
      var.expected_aws_account_id != "000000000000"
    )
    error_message = "expected_aws_account_id doit être le véritable identifiant AWS à 12 chiffres."
  }
}

variable "your_ip_cidr" {
  description = "Adresse IPv4 publique autorisée à accéder au domaine, au format x.x.x.x/32"
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.your_ip_cidr)) &&
      endswith(var.your_ip_cidr, "/32") &&
      var.your_ip_cidr != "203.0.113.10/32" &&
      var.your_ip_cidr != "0.0.0.0/32"
    )
    error_message = "your_ip_cidr doit être votre véritable adresse IPv4 publique au format x.x.x.x/32."
  }
}

variable "opensearch_domain_name" {
  description = "Nom du domaine Amazon OpenSearch"
  type        = string
  default     = "p5-opensearch"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,27}$", var.opensearch_domain_name))
    error_message = "opensearch_domain_name doit contenir 3 à 28 caractères minuscules, chiffres ou tirets."
  }
}

variable "opensearch_engine_version" {
  description = "Version du moteur Amazon OpenSearch"
  type        = string
  default     = "OpenSearch_2.19"

  validation {
    condition     = can(regex("^OpenSearch_[0-9]+[.][0-9]+$", var.opensearch_engine_version))
    error_message = "opensearch_engine_version doit utiliser le format OpenSearch_X.Y."
  }
}

variable "opensearch_instance_type" {
  description = "Type d'instance du domaine Amazon OpenSearch"
  type        = string
  default     = "t3.small.search"

  validation {
    condition     = endswith(var.opensearch_instance_type, ".search")
    error_message = "opensearch_instance_type doit être un type d'instance OpenSearch se terminant par .search."
  }
}

variable "opensearch_volume_size_gb" {
  description = "Taille du volume EBS gp3 du domaine OpenSearch"
  type        = number
  default     = 10

  validation {
    condition     = var.opensearch_volume_size_gb >= 10 && var.opensearch_volume_size_gb <= 100
    error_message = "opensearch_volume_size_gb doit être compris entre 10 et 100 Gio pour ce lab."
  }
}
