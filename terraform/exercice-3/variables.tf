variable "aws_region" {
  description = "Région AWS choisie pour l'exercice"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI Ubuntu personnalisée ; null sélectionne automatiquement Ubuntu 24.04 LTS"
  type        = string
  default     = null
  nullable    = true
}

variable "instance_type" {
  description = "Type des instances EC2 ; vérifiez son coût et son éligibilité dans votre compte"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nom de la paire de clés EC2 créée pendant l'exercice 1"
  type        = string
  default     = "p5-key"
}

variable "your_ip_cidr" {
  description = "Adresse IPv4 publique du poste d'administration au format x.x.x.x/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.your_ip_cidr, 0)) && endswith(var.your_ip_cidr, "/32")
    error_message = "your_ip_cidr doit être une adresse IPv4 unique au format x.x.x.x/32."
  }
}
