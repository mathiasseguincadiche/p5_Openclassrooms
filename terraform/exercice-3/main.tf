# =============================================================================
# EXERCICE 3 : Terraform - Déploiement HAProxy
# Fichier : main.tf
# Description : Infrastructure pour HAProxy Load Balancer
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Récupération des ressources existantes (de l'Exercice 1)
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }
}

data "aws_subnet" "existing_public_subnets" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }
}

data "aws_security_group" "existing_nginx_sg" {
  filter {
    name   = "tag:Name"
    values = ["p5-nginx-sg"]
  }
}

# Security Group pour HAProxy
resource "aws_security_group" "haproxy_sg" {
  name        = "p5-haproxy-sg"
  description = "Security Group pour HAProxy"
  vpc_id      = data.aws_vpc.existing_vpc.id
  
  # HTTP depuis n'importe où
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS depuis n'importe où (optionnel)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Statistiques HAProxy (port 8404) depuis votre IP
  ingress {
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # SSH depuis votre IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # Tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "p5-haproxy-sg"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Instance EC2 pour HAProxy
resource "aws_instance" "haproxy" {
  ami           = var.ami_id
  instance_type = var.haproxy_instance_type
  subnet_id     = data.aws_subnet.existing_public_subnets.ids[0]
  
  vpc_security_group_ids = [aws_security_group.haproxy_sg.id]
  key_name = "p5-key-exercice-1"
  
  tags = {
    Name        = "p5-haproxy"
    Environment = "dev"
    Project     = "p5-openclassrooms"
    Role        = "load-balancer"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install python3.8 -y
              yum install python3-pip -y
              pip3 install boto3
              EOF
}

# Elastic IP pour HAProxy
resource "aws_eip" "haproxy_eip" {
  instance = aws_instance.haproxy.id
  vpc      = true
  
  tags = {
    Name        = "p5-haproxy-eip"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}
