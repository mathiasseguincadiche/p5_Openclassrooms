# =============================================================================
# EXERCICE 3 : Terraform - Déploiement de HAProxy + nginxdemos/hello
# Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
# Région AWS : us-east-1 (OBLIGATOIRE)
# Conforme aux consignes : utilisation de nginxdemos/hello au lieu de NGINX standard
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
  region = var.aws_region  # Région OBLIGATOIRE pour ce projet
}

# -----------------------------------------------------------------------------
# Récupération du VPC et des sous-réseaux (de l'Exercice 1)
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

# -----------------------------------------------------------------------------
# Création du Security Group pour les serveurs nginxdemos/hello
# -----------------------------------------------------------------------------
resource "aws_security_group" "p5_hello_sg" {
  name        = "p5-hello-sg"
  description = "Security Group pour les instances nginxdemos/hello"
  vpc_id      = data.aws_vpc.p5_vpc.id
  
  # Autoriser HTTP depuis HAProxy et votre IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
    Name    = "p5-hello-sg"
    Project = "p5-openclassrooms"
    Role    = "web-server"
  }
}

# -----------------------------------------------------------------------------
# Création des 2 instances EC2 pour nginxdemos/hello
# -----------------------------------------------------------------------------
resource "aws_instance" "p5_hello" {
  count         = 2
  ami           = var.ami_id  # Ubuntu 26.04
  instance_type = var.instance_type  # t2.micro (gratuit avec Free Tier)
  subnet_id     = data.aws_subnet.p5_public_subnets.ids[count.index % length(data.aws_subnet.p5_public_subnets.ids)]
  
  vpc_security_group_ids = [aws_security_group.p5_hello_sg.id]
  key_name = "p5-key"
  
  tags = {
    Name    = "p5-hello-${count.index + 1}"
    Project = "p5-openclassrooms"
    Role    = "web-server"
    App     = "nginxdemos/hello"
  }
  
  # User Data : Script exécuté au premier démarrage
  user_data = <<-EOF
              #!/bin/bash
              # Mise à jour des packages
              apt update -y
              
              # Installation de Docker (requis pour nginxdemos/hello)
              apt install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt update -y
              apt install -y docker-ce docker-ce-cli containerd.io
              
              # Ajouter l'utilisateur ubuntu au groupe docker
              usermod -aG docker ubuntu
              
              # Démarrer Docker
              systemctl start docker
              systemctl enable docker
              
              # Attendre que Docker soit prêt
              sleep 10
              
              # Lancer le conteneur nginxdemos/hello
              docker run -d -p 80:80 --name nginx-hello --restart unless-stopped nginxdemos/hello:latest
              
              # Vérifier que le conteneur est en cours d'exécution
              sleep 5
              docker ps
              EOF
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
              
              # Attendre que les instances nginxdemos/hello soient prêtes
              sleep 30
              
              # Générer la configuration HAProxy
              cat > /etc/haproxy/haproxy.cfg << 'HAProxyEOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend http-in
    bind *:80
    default_backend hello_servers

backend hello_servers
    balance roundrobin
    server hello-1 ${aws_instance.p5_hello[0].private_ip}:80 check
    server hello-2 ${aws_instance.p5_hello[1].private_ip}:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:P5OpenClassrooms2026
HAProxyEOF
              
              # Redémarrer HAProxy
              systemctl restart haproxy
              EOF
  
  # Dépendance : HAProxy doit être déployé après les instances hello
  depends_on = [aws_instance.p5_hello]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "hello_1_public_ip" {
  description = "IP publique de l'instance nginxdemos/hello 1"
  value       = aws_instance.p5_hello[0].public_ip
}

output "hello_2_public_ip" {
  description = "IP publique de l'instance nginxdemos/hello 2"
  value       = aws_instance.p5_hello[1].public_ip
}

output "hello_1_private_ip" {
  description = "IP privée de l'instance nginxdemos/hello 1"
  value       = aws_instance.p5_hello[0].private_ip
}

output "hello_2_private_ip" {
  description = "IP privée de l'instance nginxdemos/hello 2"
  value       = aws_instance.p5_hello[1].private_ip
}

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

# URL pour accéder directement aux instances hello
output "hello_1_url" {
  description = "URL pour accéder à nginxdemos/hello 1"
  value       = "http://${aws_instance.p5_hello[0].public_ip}"
}

output "hello_2_url" {
  description = "URL pour accéder à nginxdemos/hello 2"
  value       = "http://${aws_instance.p5_hello[1].public_ip}"
}
