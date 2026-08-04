# =============================================================================
# EXERCICE 3 : Terraform - Déploiement de HAProxy + nginxdemos/hello
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# Région AWS : us-east-1 (OBLIGATOIRE)
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
  region = var.aws_region
}

# ----------------------------------------------------------------------------
# Infrastructure créée pendant l'exercice 1
# ----------------------------------------------------------------------------
data "aws_vpc" "p5_vpc" {
  filter {
    name   = "tag:Project"
    values = ["p5-openclassrooms"]
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
  description = "Acces HTTP, statistiques et administration HAProxy"
  vpc_id      = data.aws_vpc.p5_vpc.id

  ingress {
    description = "HTTP public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Statistiques HAProxy depuis le poste d'administration"
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
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
    Name    = "p5-haproxy-sg"
    Project = "p5-openclassrooms"
    Role    = "load-balancer"
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
    Name    = "p5-hello-sg"
    Project = "p5-openclassrooms"
    Role    = "web-server"
  }
}

# ----------------------------------------------------------------------------
# Deux serveurs nginxdemos/hello
# ----------------------------------------------------------------------------
resource "aws_instance" "p5_hello" {
  count                       = 2
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.p5_public_subnets.ids[count.index % length(data.aws_subnets.p5_public_subnets.ids)]
  vpc_security_group_ids      = [aws_security_group.p5_hello_sg.id]
  key_name                    = var.key_name
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    docker run -d --name nginx-hello --restart unless-stopped -p 80:80 nginxdemos/hello:plain-text
  EOF

  tags = {
    Name    = "p5-hello-${count.index + 1}"
    Project = "p5-openclassrooms"
    Role    = "web-server"
    App     = "nginxdemos/hello"
  }
}

# ----------------------------------------------------------------------------
# Répartiteur HAProxy
# ----------------------------------------------------------------------------
resource "aws_instance" "p5_haproxy" {
  ami                         = coalesce(var.ami_id, data.aws_ami.ubuntu.id)
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.p5_public_subnets.ids[0]
  vpc_security_group_ids      = [aws_security_group.p5_haproxy_sg.id]
  key_name                    = var.key_name
  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/usr/bin/env bash
    set -euo pipefail
    apt-get update -y
    apt-get install -y haproxy

    cat > /etc/haproxy/haproxy.cfg <<'HAPROXY'
    global
        log /dev/log local0
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        user haproxy
        group haproxy
        daemon

    defaults
        log global
        mode http
        option httplog
        option dontlognull
        timeout connect 5s
        timeout client 50s
        timeout server 50s

    frontend http-in
        bind *:80
        default_backend hello-servers

    backend hello-servers
        balance roundrobin
        option httpchk GET /
        server hello-1 ${aws_instance.p5_hello[0].private_ip}:80 check
        server hello-2 ${aws_instance.p5_hello[1].private_ip}:80 check

    listen stats
        bind *:8404
        stats enable
        stats uri /stats
        stats refresh 10s
        stats auth admin:${var.haproxy_stats_password}
    HAPROXY

    haproxy -c -f /etc/haproxy/haproxy.cfg
    systemctl enable --now haproxy
  EOF

  tags = {
    Name    = "p5-haproxy"
    Project = "p5-openclassrooms"
    Role    = "load-balancer"
  }

  depends_on = [aws_instance.p5_hello]
}
