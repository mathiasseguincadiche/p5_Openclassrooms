# =============================================================================
# EXERCICE 2 : Variables Terraform
# Fichier : variables.tf
# =============================================================================

# -----------------------------------------------------------------------------
# Variables AWS
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

# -----------------------------------------------------------------------------
# Variables pour OpenSearch
# -----------------------------------------------------------------------------
variable "opensearch_instance_type" {
  description = "Type d'instance pour OpenSearch"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

# -----------------------------------------------------------------------------
# Variables de Sécurité
# -----------------------------------------------------------------------------
variable "your_ip_cidr" {
  description = "Votre IP publique en notation CIDR"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH"
  type        = string
  default     = "~/.ssh/p5-key.pub"
}
