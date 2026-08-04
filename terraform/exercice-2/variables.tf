variable "aws_region" {
  description = "Région AWS choisie pour le domaine OpenSearch"
  type        = string
  default     = "us-east-1"
}

variable "your_ip_cidr" {
  description = "Adresse IPv4 publique autorisée à accéder au domaine, au format x.x.x.x/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.your_ip_cidr, 0)) && endswith(var.your_ip_cidr, "/32")
    error_message = "your_ip_cidr doit être une adresse IPv4 unique au format x.x.x.x/32."
  }
}
