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
}

# -----------------------------------------------------------------------------
# Variables pour les Instances EC2
# -----------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID pour Ubuntu 26.04 (us-east-1)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Ubuntu 26.04 LTS - us-east-1
  # Pour trouver l'AMI ID : aws ec2 describe-images --owners 099720109477 --filters 'Name=ubuntu/images/hvm-ssd/ubuntu-noble-26.04-amd64-server-*' --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
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

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH"
  type        = string
  default     = "~/.ssh/p5-key.pub"
}
