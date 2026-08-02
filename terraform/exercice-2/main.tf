# =============================================================================
# EXERCICE 2 : Terraform - Déploiement OpenSearch
# Fichier : main.tf
# Description : Infrastructure pour OpenSearch, Logstash et Filebeat
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Configuration du Provider AWS
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 2. Récupération des ressources existantes (de l'Exercice 1)
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# 3. Création d'un Security Group pour OpenSearch
# -----------------------------------------------------------------------------
resource "aws_security_group" "opensearch_sg" {
  name        = "p5-opensearch-sg"
  description = "Security Group pour OpenSearch et Logstash"
  vpc_id      = data.aws_vpc.existing_vpc.id
  
  # OpenSearch API (port 9200) depuis NGINX et votre IP
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
    security_groups = [data.aws_security_group.existing_nginx_sg.id]
  }
  
  # OpenSearch Dashboards (port 9600) depuis votre IP
  ingress {
    from_port   = 9600
    to_port     = 9600
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  # Logstash (port 5044) depuis NGINX
  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    security_groups = [data.aws_security_group.existing_nginx_sg.id]
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
    Name        = "p5-opensearch-sg"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# 4. Création de l'instance EC2 pour OpenSearch
# -----------------------------------------------------------------------------
resource "aws_instance" "opensearch" {
  ami           = var.ami_id
  instance_type = var.opensearch_instance_type
  subnet_id     = data.aws_subnet.existing_public_subnets.ids[0]
  
  vpc_security_group_ids = [aws_security_group.opensearch_sg.id]
  key_name = "p5-key-exercice-1"
  
  tags = {
    Name        = "p5-opensearch"
    Environment = "dev"
    Project     = "p5-openclassrooms"
    Role        = "search-engine"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install java-openjdk11 -y
              amazon-linux-extras install python3.8 -y
              yum install python3-pip -y
              pip3 install boto3
              echo "opensearch - nofile 65536" | sudo tee -a /etc/security/limits.conf
              echo "* - nofile 65536" | sudo tee -a /etc/security/limits.conf
              echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
              sudo sysctl -w vm.max_map_count=262144
              sudo useradd opensearch
              EOF
}

# -----------------------------------------------------------------------------
# 5. Création d'une Elastic IP pour OpenSearch
# -----------------------------------------------------------------------------
resource "aws_eip" "opensearch_eip" {
  instance = aws_instance.opensearch.id
  vpc      = true
  
  tags = {
    Name        = "p5-opensearch-eip"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}
