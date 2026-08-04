# =============================================
# TEMPLATE : Configuration Terraform pour AWS
# =============================================
# Ce fichier permet de provisionner une infrastructure cloud complète sur AWS.
# Il inclut :
# - Configuration du provider AWS.
# - Création d'un VPC (Virtual Private Cloud).
# - Création de subnets (public et privé).
# - Création d'une Internet Gateway et d'une NAT Gateway.
# - Création de groupes de sécurité.
# - Création d'une instance EC2.
#
# Pour utiliser ce template :
# 1. Copiez ce fichier dans votre projet sous le nom "main.tf".
# 2. Configurez vos clés AWS (via AWS CLI ou variables d'environnement).
# 3. Personnalisez les ressources selon vos besoins.
# 4. Exécutez : terraform init && terraform plan && terraform apply

# =============================================
# CONFIGURATION DU PROVIDER AWS
# =============================================

# Bloc terraform : configure la version de Terraform et les providers requis
terraform {
  # Version minimale de Terraform requise
  required_version = ">= 1.15.0, < 2.0.0"

  # Providers requis
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuration du provider AWS
provider "aws" {
  # Région AWS (Paris = eu-west-3, Frankfurt = eu-central-1, etc.)
  region = var.aws_region

  # Utilise les credentials par défaut (configurés via AWS CLI ou variables d'environnement)
  # Pour spécifier des credentials ici (non recommandé pour la sécurité) :
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}

# =============================================
# RÉSEAU : VPC, SUBNETS, INTERNET GATEWAY, NAT GATEWAY
# =============================================

# Créer un VPC (Virtual Private Cloud)
resource "aws_vpc" "main" {
  # Plage d'adresses IP pour le VPC (CIDR)
  cidr_block = var.vpc_cidr

  # Activer les DNS hostnames et le support DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tag pour identifier le VPC
  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Créer un subnet public
resource "aws_subnet" "public" {
  # VPC dans lequel créer le subnet
  vpc_id = aws_vpc.main.id

  # Plage d'adresses IP pour le subnet (CIDR)
  cidr_block = var.public_subnet_cidr

  # Zone de disponibilité
  availability_zone = "${var.aws_region}a"

  # Attribuer une IP publique automatiquement aux instances dans ce subnet
  map_public_ip_on_launch = true

  # Tag pour identifier le subnet
  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

# Créer un subnet privé
resource "aws_subnet" "private" {
  # VPC dans lequel créer le subnet
  vpc_id = aws_vpc.main.id

  # Plage d'adresses IP pour le subnet (CIDR)
  cidr_block = var.private_subnet_cidr

  # Zone de disponibilité
  availability_zone = "${var.aws_region}a"

  # Tag pour identifier le subnet
  tags = {
    Name    = "${var.project_name}-private-subnet"
    Project = var.project_name
  }
}

# Créer une Internet Gateway (pour le subnet public)
resource "aws_internet_gateway" "igw" {
  # VPC auquel attacher l'Internet Gateway
  vpc_id = aws_vpc.main.id

  # Tag pour identifier l'Internet Gateway
  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Créer une Elastic IP pour la NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  # Tag pour identifier l'Elastic IP
  tags = {
    Name    = "${var.project_name}-nat-eip"
    Project = var.project_name
  }
}

# Créer une NAT Gateway (pour le subnet privé)
resource "aws_nat_gateway" "nat" {
  # Allouer une Elastic IP à la NAT Gateway
  allocation_id = aws_eip.nat.id

  # Subnet dans lequel créer la NAT Gateway (doit être public)
  subnet_id = aws_subnet.public.id

  # Tag pour identifier la NAT Gateway
  tags = {
    Name    = "${var.project_name}-nat"
    Project = var.project_name
  }

  # Attendre que l'Internet Gateway soit créée
  depends_on = [aws_internet_gateway.igw]
}

# Créer une route table pour le subnet public
resource "aws_route_table" "public" {
  # VPC auquel attacher la route table
  vpc_id = aws_vpc.main.id

  # Route par défaut vers l'Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # Tag pour identifier la route table
  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

# Créer une route table pour le subnet privé
resource "aws_route_table" "private" {
  # VPC auquel attacher la route table
  vpc_id = aws_vpc.main.id

  # Route par défaut vers la NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  # Tag pour identifier la route table
  tags = {
    Name    = "${var.project_name}-private-rt"
    Project = var.project_name
  }
}

# Associer la route table publique au subnet public
resource "aws_route_table_association" "public" {
  # Subnet à associer
  subnet_id = aws_subnet.public.id

  # Route table à associer
  route_table_id = aws_route_table.public.id
}

# Associer la route table privée au subnet privé
resource "aws_route_table_association" "private" {
  # Subnet à associer
  subnet_id = aws_subnet.private.id

  # Route table à associer
  route_table_id = aws_route_table.private.id
}

# =============================================
# SÉCURITÉ : GROUPES DE SÉCURITÉ
# =============================================

# Créer un groupe de sécurité pour les instances dans le subnet public
resource "aws_security_group" "public" {
  name        = "${var.project_name}-public-sg"
  description = "Groupe de sécurité pour les instances dans le subnet public"
  vpc_id      = aws_vpc.main.id

  # Règles de trafic entrant (ingress)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Règles de trafic sortant (egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Tous les protocoles
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tag pour identifier le groupe de sécurité
  tags = {
    Name    = "${var.project_name}-public-sg"
    Project = var.project_name
  }
}

# Créer un groupe de sécurité pour les instances dans le subnet privé
resource "aws_security_group" "private" {
  name        = "${var.project_name}-private-sg"
  description = "Groupe de sécurité pour les instances dans le subnet privé"
  vpc_id      = aws_vpc.main.id

  # Règles de trafic entrant (ingress)
  ingress {
    description = "SSH (depuis le subnet public)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public.cidr_block]
  }

  ingress {
    description = "HTTP (depuis le subnet public)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.public.cidr_block]
  }

  # Règles de trafic sortant (egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tag pour identifier le groupe de sécurité
  tags = {
    Name    = "${var.project_name}-private-sg"
    Project = var.project_name
  }
}

# =============================================
# CALCUL : INSTANCES EC2
# =============================================

# Créer une instance EC2 dans le subnet public
resource "aws_instance" "public" {
  # AMI (Amazon Machine Image) : Ubuntu 22.04 LTS
  ami = var.ami_id

  # Type d'instance (t2.micro est éligible au Free Tier)
  instance_type = var.instance_type

  # Clé SSH pour se connecter à l'instance
  key_name = var.key_name

  # Subnet dans lequel lancer l'instance
  subnet_id = aws_subnet.public.id

  # Groupe de sécurité
  vpc_security_group_ids = [aws_security_group.public.id]

  # Attribuer une IP publique (déjà activé dans le subnet)
  associate_public_ip_address = true

  # Tag pour identifier l'instance
  tags = {
    Name        = "${var.project_name}-public-instance"
    Project     = var.project_name
    Environment = "public"
  }
}

# Créer une instance EC2 dans le subnet privé
resource "aws_instance" "private" {
  # AMI (Amazon Machine Image) : Ubuntu 22.04 LTS
  ami = var.ami_id

  # Type d'instance
  instance_type = var.instance_type

  # Clé SSH pour se connecter à l'instance
  key_name = var.key_name

  # Subnet dans lequel lancer l'instance
  subnet_id = aws_subnet.private.id

  # Groupe de sécurité
  vpc_security_group_ids = [aws_security_group.private.id]

  # Tag pour identifier l'instance
  tags = {
    Name        = "${var.project_name}-private-instance"
    Project     = var.project_name
    Environment = "private"
  }
}

# =============================================
# OUTPUTS : AFFICHER DES INFORMATIONS SUR LES RESSOURCES CRÉÉES
# =============================================

# ID du VPC
output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

# ID du subnet public
output "public_subnet_id" {
  description = "ID du subnet public"
  value       = aws_subnet.public.id
}

# ID du subnet privé
output "private_subnet_id" {
  description = "ID du subnet privé"
  value       = aws_subnet.private.id
}

# IP publique de l'instance dans le subnet public
output "public_instance_public_ip" {
  description = "IP publique de l'instance dans le subnet public"
  value       = aws_instance.public.public_ip
}

# ID de l'instance dans le subnet public
output "public_instance_id" {
  description = "ID de l'instance dans le subnet public"
  value       = aws_instance.public.id
}

# ID de l'instance dans le subnet privé
output "private_instance_id" {
  description = "ID de l'instance dans le subnet privé"
  value       = aws_instance.private.id
}

# =============================================
# EXPLICATIONS :
# =============================================
# 1. terraform { ... } : Bloc pour configurer Terraform lui-même.
#    - required_version : Version minimale de Terraform requise.
#    - required_providers : Liste des providers requis et leurs versions.
#
# 2. provider "aws" { ... } : Configuration du provider AWS.
#    - region : Région AWS à utiliser.
#    - Les credentials sont lus depuis AWS CLI ou des variables d'environnement.
#
# 3. aws_vpc : Crée un VPC (Virtual Private Cloud).
#    - cidr_block : Plage d'adresses IP pour le VPC.
#    - enable_dns_hostnames : Active les noms DNS pour les instances.
#    - enable_dns_support : Active le support DNS.
#
# 4. aws_subnet : Crée un subnet dans le VPC.
#    - vpc_id : VPC dans lequel créer le subnet.
#    - cidr_block : Plage d'adresses IP pour le subnet.
#    - availability_zone : Zone de disponibilité.
#    - map_public_ip_on_launch : Attribue une IP publique aux instances.
#
# 5. aws_internet_gateway : Crée une Internet Gateway pour le VPC.
#    - vpc_id : VPC auquel attacher l'Internet Gateway.
#
# 6. aws_eip : Crée une Elastic IP (adresse IP publique statique).
#
# 7. aws_nat_gateway : Crée une NAT Gateway pour le subnet privé.
#    - allocation_id : Elastic IP à attacher à la NAT Gateway.
#    - subnet_id : Subnet dans lequel créer la NAT Gateway (doit être public).
#
# 8. aws_route_table : Crée une table de routage.
#    - vpc_id : VPC auquel attacher la table de routage.
#    - route : Règles de routage (cidr_block, gateway_id, nat_gateway_id).
#
# 9. aws_route_table_association : Associe une table de routage à un subnet.
#    - subnet_id : Subnet à associer.
#    - route_table_id : Table de routage à associer.
#
# 10. aws_security_group : Crée un groupe de sécurité.
#     - name : Nom du groupe de sécurité.
#     - description : Description du groupe de sécurité.
#     - vpc_id : VPC auquel attacher le groupe de sécurité.
#     - ingress : Règles de trafic entrant.
#     - egress : Règles de trafic sortant.
#
# 11. aws_instance : Crée une instance EC2.
#     - ami : AMI à utiliser pour l'instance.
#     - instance_type : Type d'instance.
#     - key_name : Nom de la clé SSH.
#     - subnet_id : Subnet dans lequel lancer l'instance.
#     - vpc_security_group_ids : Groupes de sécurité à attacher.
#     - associate_public_ip_address : Attribue une IP publique.
#
# 12. output : Définit un output pour afficher des informations.
#     - description : Description de l'output.
#     - value : Valeur à afficher.
# =============================================

# =============================================
# UTILISATION :
# =============================================
# 1. Copiez ce fichier dans votre projet sous le nom "main.tf".
# 2. Copiez le fichier variables.tf dans votre projet.
# 3. Configurez vos clés AWS (via AWS CLI ou variables d'environnement).
# 4. Initialisez Terraform :
#    terraform init
# 5. Voir le plan d'exécution :
#    terraform plan
# 6. Appliquez les changements :
#    terraform apply
# 7. Détruyez l'infrastructure (après utilisation) :
#    terraform destroy
# =============================================

# =============================================
# BONNES PRATIQUES :
# =============================================
# 1. Utilisez des modules pour organiser votre code (ex: modules/vpc/main.tf).
# 2. Versionnez votre état avec un backend distant (ex: S3).
# 3. Utilisez des variables pour éviter de hardcoder des valeurs.
# 4. Verrouillez les versions des providers.
# 5. Utilisez des outputs pour afficher des informations utiles.
# 6. Planifiez toujours les changements avec terraform plan.
# 7. Détruyez l'infrastructure inutilisée pour éviter des frais.
# 8. Utilisez des workspaces pour gérer plusieurs environnements.
# 9. Documentez votre infrastructure avec des commentaires.
# =============================================
