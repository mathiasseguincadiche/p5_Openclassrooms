# =============================================================================
# EXERCICE 3 : Terraform - Déploiement de HAProxy
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# Région AWS : us-east-1 (OBLIGATOIRE)
# =============================================================================

# -----------------------------------------------------------------------------
# Configuration du Provider AWS
# -----------------------------------------------------------------------------
terraform {
  required_version = ">= 1.15.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Région OBLIGATOIRE pour ce projet
}

# -----------------------------------------------------------------------------
# Récupération des ressources existantes (de l'Exercice 1)
# -----------------------------------------------------------------------------
data "aws_vpc" "p5_vpc" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }
}

data "aws_subnet" "p5_public_subnets" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }
}

data "aws_security_group" "p5_nginx_sg" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }
}

data "aws_instances" "p5_nginx_instances" {
  instance_tags = {
    Project = "p5-openclassrooms"
    Role    = "web-server"
  }
}

# -----------------------------------------------------------------------------
# Création du Security Group pour HAProxy
# -----------------------------------------------------------------------------
resource "aws_security_group" "p5_haproxy_sg" {
  name        = "p5-haproxy-sg"
  description = "Security Group pour HAProxy"
  vpc_id      = data.aws_vpc.p5_vpc.id
  
  # Autoriser HTTP depuis n'importe où
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Autoriser HTTPS depuis n'importe où (optionnel)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Autoriser les statistiques HAProxy depuis votre IP
  ingress {
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # Autoriser SSH depuis votre IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # Autoriser tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name    = "p5-haproxy-sg"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création de l'instance EC2 pour HAProxy
# -----------------------------------------------------------------------------
resource "aws_instance" "p5_haproxy" {
  ami           = var.ami_id  # Ubuntu 26.04
  instance_type = var.instance_type  # t2.micro (gratuit avec Free Tier)
  subnet_id     = data.aws_subnet.p5_public_subnets.ids[0]
  
  vpc_security_group_ids = [aws_security_group.p5_haproxy_sg.id]
  key_name = "p5-key"
  
  tags = {
    Name    = "p5-haproxy"
    Project = "p5-openclassrooms"
    Role    = "load-balancer"
  }
  
  # User Data : Script exécuté au premier démarrage
  user_data = <<-EOF
              #!/bin/bash
              # Mise à jour des packages
              apt update -y
              
              # Installation de Python 3 (requis pour Ansible)
              apt install -y python3 python3-pip
              
              # Installation de pip pour boto3
              pip3 install boto3
              
              # Installation de HAProxy
              apt install -y haproxy
              EOF
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "haproxy_public_ip" {
  description = "IP publique de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.public_ip
}

output "haproxy_private_ip" {
  description = "IP privée de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.private_ip
}

output "haproxy_public_dns" {
  description = "DNS public de l'instance HAProxy"
  value       = aws_instance.p5_haproxy.public_dns
}

output "haproxy_security_group_id" {
  description = "ID du Security Group pour HAProxy"
  value       = aws_security_group.p5_haproxy_sg.id
}

# IPs privées des instances NGINX (pour la configuration HAProxy)
output "nginx_1_private_ip" {
  description = "IP privée de NGINX-1"
  value       = data.aws_instances.p5_nginx_instances.private_ips[0]
}

output "nginx_2_private_ip" {
  description = "IP privée de NGINX-2"
  value       = data.aws_instances.p5_nginx_instances.private_ips[1]
}

# URL pour accéder à HAProxy
output "haproxy_url" {
  description = "URL pour accéder à HAProxy"
  value       = "http://${aws_instance.p5_haproxy.public_ip}"
}

# URL pour les statistiques HAProxy
output "haproxy_stats_url" {
  description = "URL pour les statistiques HAProxy"
  value       = "http://${aws_instance.p5_haproxy.public_ip}:8404/stats"
}
