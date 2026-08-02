# =============================================================================
# EXERCICE 1 : Terraform - Déploiement de 2 VMs NGINX
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
# Création du VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "p5_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name    = "p5-vpc"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création des Subnets Publics
# -----------------------------------------------------------------------------
resource "aws_subnet" "p5_public_subnet_a" {
  vpc_id            = aws_vpc.p5_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name    = "p5-public-subnet-a"
    Project = "p5-openclassrooms"
  }
}

resource "aws_subnet" "p5_public_subnet_b" {
  vpc_id            = aws_vpc.p5_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name    = "p5-public-subnet-b"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création de l'Internet Gateway
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "p5_igw" {
  vpc_id = aws_vpc.p5_vpc.id
  
  tags = {
    Name    = "p5-igw"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création de la Route Table
# -----------------------------------------------------------------------------
resource "aws_route_table" "p5_public_rt" {
  vpc_id = aws_vpc.p5_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.p5_igw.id
  }
  
  tags = {
    Name    = "p5-public-rt"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Association des Subnets à la Route Table
# -----------------------------------------------------------------------------
resource "aws_route_table_association" "p5_public_subnet_a_association" {
  subnet_id      = aws_subnet.p5_public_subnet_a.id
  route_table_id = aws_route_table.p5_public_rt.id
}

resource "aws_route_table_association" "p5_public_subnet_b_association" {
  subnet_id      = aws_subnet.p5_public_subnet_b.id
  route_table_id = aws_route_table.p5_public_rt.id
}

# -----------------------------------------------------------------------------
# Création du Security Group pour NGINX
# -----------------------------------------------------------------------------
resource "aws_security_group" "p5_nginx_sg" {
  name        = "p5-nginx-sg"
  description = "Security Group pour les serveurs NGINX"
  vpc_id      = aws_vpc.p5_vpc.id
  
  # Autoriser SSH depuis votre IP (à configurer dans terraform.tfvars)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # Autoriser HTTP depuis n'importe où
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Autoriser tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name    = "p5-nginx-sg"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création de la paire de clés SSH
# -----------------------------------------------------------------------------
resource "aws_key_pair" "p5_key_pair" {
  key_name   = "p5-key"
  public_key = file(var.ssh_public_key_path)
  
  tags = {
    Name    = "p5-key"
    Project = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# Création des Instances EC2 pour NGINX
# -----------------------------------------------------------------------------
resource "aws_instance" "p5_nginx_1" {
  ami           = var.ami_id  # Ubuntu 26.04
  instance_type = var.instance_type  # t2.micro (gratuit avec Free Tier)
  subnet_id     = aws_subnet.p5_public_subnet_a.id
  
  vpc_security_group_ids = [aws_security_group.p5_nginx_sg.id]
  key_name = aws_key_pair.p5_key_pair.key_name
  
  tags = {
    Name    = "p5-nginx-1"
    Project = "p5-openclassrooms"
    Role    = "web-server"
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
              EOF
}

resource "aws_instance" "p5_nginx_2" {
  ami           = var.ami_id  # Ubuntu 26.04
  instance_type = var.instance_type  # t2.micro (gratuit avec Free Tier)
  subnet_id     = aws_subnet.p5_public_subnet_b.id
  
  vpc_security_group_ids = [aws_security_group.p5_nginx_sg.id]
  key_name = aws_key_pair.p5_key_pair.key_name
  
  tags = {
    Name    = "p5-nginx-2"
    Project = "p5-openclassrooms"
    Role    = "web-server"
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
              EOF
}
