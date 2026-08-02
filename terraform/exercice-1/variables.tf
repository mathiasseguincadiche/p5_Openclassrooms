# =============================================================================
# EXERCICE 1 : Variables Terraform
# =============================================================================

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block pour le subnet public A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block pour le subnet public B"
  type        = string
  default     = "10.0.2.0/24"
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "your_ip_cidr" {
  description = "Votre IP publique en notation CIDR"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH"
  type        = string
  default     = "~/.ssh/p5-key.pub"
}
