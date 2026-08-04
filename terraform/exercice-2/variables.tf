# =============================================================================
# EXERCICE 2 : Variables Terraform
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# Région AWS : us-east-1 (OBLIGATOIRE)
# =============================================================================

# -----------------------------------------------------------------------------
# Variables AWS
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "Région AWS (us-east-1 OBLIGATOIRE pour ce projet)"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Le projet P5 doit être déployé dans la région us-east-1."
  }
}

# -----------------------------------------------------------------------------
# Variables de Sécurité
# -----------------------------------------------------------------------------
variable "your_ip_cidr" {
  description = "Votre IP publique en notation CIDR (ex: 192.168.1.1/32)"
  type        = string

  validation {
    condition     = can(cidrhost(var.your_ip_cidr, 0)) && endswith(var.your_ip_cidr, "/32")
    error_message = "your_ip_cidr doit être une adresse IPv4 unique au format x.x.x.x/32."
  }
}
