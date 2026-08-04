# =============================================================================
# EXERCICE 3 : Variables Terraform
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

variable "aws_region" {
  description = "Région AWS imposée pour le projet"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Le projet P5 doit être déployé dans la région us-east-1."
  }
}

variable "ami_id" {
  description = "AMI Ubuntu personnalisée ; null sélectionne automatiquement Ubuntu 24.04 LTS"
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "Type des instances EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 déjà créée dans AWS"
  type        = string
  default     = "p5-key"
}

variable "your_ip_cidr" {
  description = "Adresse IPv4 publique du poste d'administration au format CIDR"
  type        = string

  validation {
    condition     = can(cidrhost(var.your_ip_cidr, 0)) && endswith(var.your_ip_cidr, "/32")
    error_message = "your_ip_cidr doit être une adresse IPv4 unique au format x.x.x.x/32."
  }
}

variable "haproxy_stats_password" {
  description = "Mot de passe du compte admin de la page de statistiques HAProxy"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.haproxy_stats_password) >= 16
    error_message = "haproxy_stats_password doit contenir au moins 16 caractères."
  }
}
