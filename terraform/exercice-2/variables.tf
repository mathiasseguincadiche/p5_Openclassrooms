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
}

# -----------------------------------------------------------------------------
# Variables de Sécurité
# -----------------------------------------------------------------------------
variable "your_ip_cidr" {
  description = "Votre IP publique en notation CIDR (ex: 192.168.1.1/32)"
  type        = string
}
