# Exercice 1 — Infrastructure AWS utilisée comme cible Ansible.
terraform {
  required_version = ">= 1.15.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.expected_aws_account_id]

  default_tags {
    tags = {
      Project   = "p5-openclassrooms"
      ManagedBy = "Terraform"
      Purpose   = "training-lab"
      Exercise  = "1"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "p5" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "p5-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.p5.id
  cidr_block              = cidrsubnet(aws_vpc.p5.cidr_block, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "p5-public-${count.index + 1}"
    Type = "public"
  }
}

resource "aws_internet_gateway" "p5" {
  vpc_id = aws_vpc.p5.id

  tags = {
    Name = "p5-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.p5.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.p5.id
  }

  tags = {
    Name = "p5-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "web" {
  name        = "p5-web-sg"
  description = "Acces HTTP public et SSH depuis le poste d'administration"
  vpc_id      = aws_vpc.p5.id

  ingress {
    description = "SSH depuis le poste d'administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  ingress {
    description = "HTTP public"
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
    Name = "p5-web-sg"
  }
}

resource "aws_key_pair" "p5" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = {
    Name = var.key_name
  }
}

resource "aws_instance" "web" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = aws_key_pair.p5.key_name
  user_data_replace_on_change = true

  user_data = <<-EOF_USER_DATA
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y python3
  EOF_USER_DATA

  tags = {
    Name = "p5-web"
    Role = "ansible-target"
  }
}
