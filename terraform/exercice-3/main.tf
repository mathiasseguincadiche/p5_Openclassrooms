# =============================================================================
# EXERCICE 3 : Terraform - Déploiement de HAProxy + nginxdemos/hello
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# =============================================================================

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
      Exercise  = "3"
    }
  }
}

# ----------------------------------------------------------------------------
# Infrastructure créée pendant l'exercice 1
# ----------------------------------------------------------------------------
data "aws_vpc" "p5_vpc" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }

  filter {
    name   = "tag:Exercise"
    values = ["1"]
  }

  filter {
    name   = "tag:Name"
    values = ["p5-vpc"]
  }
}

data "aws_subnets" "p5_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.p5_vpc.id]
  }

  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
  }

  filter {
    name   = "tag:Exercise"
    values = ["1"]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------------------------------------------------------
# Groupes de sécurité
# ----------------------------------------------------------------------------
resource "aws_security_group" "p5_haproxy_sg" {
  name        = "p5-haproxy-sg"
  description = "Acces HTTP public et SSH d’administration"
  vpc_id      = data.aws_vpc.p5_vpc.id

  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH depuis le poste d'administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "p5-haproxy-sg"
    Role = "load-balancer"
  }
}

resource "aws_security_group" "p5_hello_sg" {
  name        = "p5-hello-sg"
  description = "Acces aux serveurs hello depuis HAProxy et par SSH"
  vpc_id      = data.aws_vpc.p5_vpc.id

  ingress {
    description     = "HTTP depuis HAProxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.p5_haproxy_sg.id]
  }

  ingress {
    description = "SSH depuis le poste d'administration"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "p5-hello-sg"
    Role = "web-server"
  }
}

# ----------------------------------------------------------------------------
# Deux serveurs nginxdemos/hello
# ----------------------------------------------------------------------------
resource "aws_instance" "p5_hello" {
  count                       = 2
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.p5_public_subnets.ids)[count.index % length(data.aws_subnets.p5_public_subnets.ids)]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.p5_hello_sg.id]
  key_name                    = var.key_name
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    docker run -d \
      --name nginx-hello \
      --hostname p5-hello-${count.index + 1} \
      --restart unless-stopped \
      -p 80:80 \
      nginxdemos/hello:0.4-plain-text
  EOF

  tags = {
    Name = "p5-hello-${count.index + 1}"
    Role = "web-server"
    App  = "nginxdemos/hello:0.4-plain-text"
  }
}

locals {
  haproxy_config = replace(
    replace(
      file("${path.module}/haproxy.cfg.tpl"),
      "@@BACKEND_1@@",
      aws_instance.p5_hello[0].private_ip,
    ),
    "@@BACKEND_2@@",
    aws_instance.p5_hello[1].private_ip,
  )
}

# ----------------------------------------------------------------------------
# Répartiteur HAProxy
# ----------------------------------------------------------------------------
resource "aws_instance" "p5_haproxy" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.p5_public_subnets.ids)[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.p5_haproxy_sg.id]
  key_name                    = var.key_name
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y haproxy

    cat > /etc/haproxy/haproxy.cfg <<'HAPROXY'
    ${indent(4, local.haproxy_config)}
    HAPROXY

    haproxy -c -f /etc/haproxy/haproxy.cfg
    systemctl enable --now haproxy
  EOF

  tags = {
    Name = "p5-haproxy"
    Role = "load-balancer"
  }

  depends_on = [aws_instance.p5_hello]
}
