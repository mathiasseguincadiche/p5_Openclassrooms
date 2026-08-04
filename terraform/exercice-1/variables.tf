# =============================================================================
# EXERCICE 1 : Variables Terraform
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
# Variables pour les Instances EC2
# -----------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI Ubuntu à utiliser, ou null pour sélectionner la dernière Ubuntu 24.04 LTS"
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "Type d'instance EC2 (t2.micro est gratuit avec Free Tier)"
  type        = string
  default     = "t2.micro"
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

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH"
  type        = string
  default     = "~/.ssh/p5-key.pub"
}
