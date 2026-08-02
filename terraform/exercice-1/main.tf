# =============================================================================
# EXERCICE 1 : Terraform - Déploiement NGINX
# Fichier : main.tf
# Description : Infrastructure pour 2 serveurs NGINX
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

# VPC
resource "aws_vpc" "p5_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name        = "p5-vpc-exercice-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.p5_vpc.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "p5-public-subnet-a"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.p5_vpc.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "p5-public-subnet-b"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "p5_igw" {
  vpc_id = aws_vpc.p5_vpc.id
  
  tags = {
    Name        = "p5-igw-exercice-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.p5_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.p5_igw.id
  }
  
  tags = {
    Name        = "p5-public-route-table"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group
resource "aws_security_group" "nginx_sg" {
  name        = "p5-nginx-sg"
  description = "Security Group pour les serveurs NGINX"
  vpc_id      = aws_vpc.p5_vpc.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "p5-nginx-sg"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Key Pair
resource "aws_key_pair" "p5_key_pair" {
  key_name   = "p5-key-exercice-1"
  public_key = file(var.ssh_public_key_path)
  
  tags = {
    Name        = "p5-key-exercice-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# EC2 Instances for NGINX
resource "aws_instance" "nginx_1" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_a.id
  
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  key_name = aws_key_pair.p5_key_pair.key_name
  
  tags = {
    Name        = "p5-nginx-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
    Role        = "web-server"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install python3.8 -y
              yum install python3-pip -y
              pip3 install boto3
              EOF
}

resource "aws_instance" "nginx_2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_b.id
  
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  key_name = aws_key_pair.p5_key_pair.key_name
  
  tags = {
    Name        = "p5-nginx-2"
    Environment = "dev"
    Project     = "p5-openclassrooms"
    Role        = "web-server"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install python3.8 -y
              yum install python3-pip -y
              pip3 install boto3
              EOF
}
