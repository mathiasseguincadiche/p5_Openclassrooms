# =============================================================================
# EXERCICE 3 : Variables Terraform
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
# Variables pour les Instances EC2
# -----------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID pour Ubuntu 26.04 (us-east-1)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Ubuntu 26.04 LTS - us-east-1
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
}
