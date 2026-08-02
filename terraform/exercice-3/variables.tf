# =============================================================================
# EXERCICE 3 : Variables Terraform
# =============================================================================

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "haproxy_instance_type" {
  description = "Type d'instance pour HAProxy"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID (Amazon Linux 2)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
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
