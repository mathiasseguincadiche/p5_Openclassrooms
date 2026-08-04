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
