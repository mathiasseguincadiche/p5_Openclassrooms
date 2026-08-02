# 🔥 Exercice 1 : Terraform + Ansible + NGINX

**Déploiement d'une infrastructure web avec Infrastructure-as-Code**

---

## 🎯 **Objectifs de l'Exercice**

À la fin de cet exercice, vous serez capable de :

✅ **Comprendre** les concepts d'**Infrastructure-as-Code (IaC)**
✅ **Utiliser** Terraform pour **provisionner** des ressources AWS
✅ **Configurer** des serveurs avec **Ansible**
✅ **Déployer** un serveur web **NGINX**
✅ **Automatiser** le processus de déploiement
✅ **Vérifier** et **dépanner** votre infrastructure

---

## 📚 **Concepts Clés à Maîtriser**

### **🏗️ Infrastructure-as-Code (IaC)**

**Définition** :
> L'Infrastructure-as-Code est une pratique DevOps qui consiste à **gérer l'infrastructure** (serveurs, réseaux, stockage, etc.) **via du code** plutôt que via des processus manuels.

**Avantages** :
- ✅ **Reproductibilité** : Même infrastructure à chaque déploiement
- ✅ **Versionnage** : Historique des changements avec Git
- ✅ **Automatisation** : Déploiement rapide et sans erreur
- ✅ **Collaboration** : Travail d'équipe sur l'infrastructure
- ✅ **Documentation** : Le code lui-même documente l'infrastructure

**Outils populaires** :
- **Terraform** (HashiCorp) - **Multi-cloud** (AWS, Azure, GCP, etc.)
- **AWS CloudFormation** - Spécifique à AWS
- **Pulumi** - Utilise des langages généraux (Python, TypeScript)
- **Ansible** - Configuration + provisionnement léger

---

### **⛏️ Terraform**

**C'est quoi ?**
Terraform est un outil d'**Infrastructure-as-Code** développé par HashiCorp. Il permet de :
- **Décrire** votre infrastructure dans des fichiers `.tf`
- **Planifier** les changements avant de les appliquer
- **Appliquer** les changements pour créer/modifier/supprimer des ressources
- **Gérer l'état** (state) de votre infrastructure

**Concepts clés** :

| Concept | Description | Exemple |
|---------|-------------|---------|
| **Provider** | Plugin pour interagir avec un cloud (AWS, Azure, etc.) | `aws` |
| **Resource** | Une ressource cloud à créer | `aws_instance`, `aws_vpc` |
| **Module** | Ensemble de ressources réutilisables | `module "vpc" { ... }` |
| **Variable** | Paramètre configurable | `variable "instance_type"` |
| **Output** | Valeur retournée après déploiement | `output "public_ip"` |
| **State** | Fichier qui stocke l'état actuel | `terraform.tfstate` |

**Workflow Terraform** :
```
1. Écrire le code Terraform (fichiers .tf)
2. terraform init → Télécharge les providers
3. terraform plan → Aperçu des changements
4. terraform apply → Applique les changements
5. terraform destroy → Supprime tout
```

---

### **🎭 Ansible**

**C'est quoi ?**
Ansible est un outil d'**automatisation** développé par Red Hat. Il permet de :
- **Configurer** des serveurs (installation de packages, gestion de fichiers, etc.)
- **Déployer** des applications
- **Orchestrer** des tâches complexes sur plusieurs serveurs

**Avantages** :
- ✅ **Agentless** : Pas besoin d'installer un agent sur les serveurs cibles
- ✅ **Simple** : Syntaxe YAML facile à lire
- ✅ **Puissant** : Modules pour presque tout
- ✅ **Idempotent** : Exécuter plusieurs fois ne change rien si déjà à jour

**Concepts clés** :

| Concept | Description | Exemple |
|---------|-------------|---------|
| **Inventory** | Liste des serveurs à configurer | `inventory.ini` |
| **Playbook** | Fichier YAML avec les tâches à exécuter | `playbook.yml` |
| **Role** | Organisation des tâches par rôle | `roles/nginx/` |
| **Task** | Une action à exécuter | Installer NGINX |
| **Handler** | Tâche déclenchée par un changement | Redémarrer NGINX |
| **Module** | Fonctionnalité réutilisable | `apt`, `yum`, `copy` |

**Architecture Ansible** :
```
┌─────────────┐     ┌─────────────┐
│  Machine     │────▶│  Serveur 1  │
│  de contrôle │     │             │
│  (Votre PC)  │────▶│  Serveur 2  │
└─────────────┘     └─────────────┘
      │
      └── SSH (Port 22)
```

---

### **🌐 NGINX**

**C'est quoi ?**
NGINX (prononcé "engine-x") est un **serveur web** et **reverse proxy** open source. Il est connu pour :
- ✅ **Performances élevées** (architecture asynchrone)
- ✅ **Faible consommation mémoire**
- ✅ **Scalabilité** (gère des milliers de connexions simultanées)
- ✅ **Flexibilité** (reverse proxy, load balancer, cache, etc.)

**Cas d'usage** :
- Serveur web pour des sites statiques
- Reverse proxy pour des applications (Node.js, Python, etc.)
- Load balancer
- Cache HTTP

**Architecture NGINX** :
```
┌─────────────────────────────────────────────┐
│                 NGINX                         │
│  ┌─────────────────────────────────────────┐  │
│  │            Master Process                 │  │
│  │  (Gère la configuration, les workers)    │  │
│  └─────────────────────────────────────────┘  │
│                      │                          │
│  ┌───────────────┐ ┌───────────────┐          │
│  │  Worker 1     │ │  Worker 2     │          │
│  │  (Traite les │ │  (Traite les │          │
│  │   requêtes)  │ │   requêtes)  │          │
│  └───────────────┘ └───────────────┘          │
└─────────────────────────────────────────────┘
```

---

## 🚀 **Étapes Détaillées**

### **📁 Préparation des Fichiers**

#### **1. Structure des dossiers pour l'Exercice 1**

```bash
p5_Openclassrooms/
├── terraform/
│   └── exercice-1/
│       ├── main.tf          # 📄 Configuration principale Terraform
│       ├── variables.tf     # 📄 Variables configurables
│       ├── outputs.tf       # 📄 Sorties (IPs, etc.)
│       └── terraform.tfvars # 📄 Valeurs des variables (NE PAS COMMITER)
│
└── ansible/
    ├── inventories/
    │   └── exercice-1.ini    # 📄 Inventaire des serveurs
    ├── playbooks/
    │   └── deploy-nginx.yml  # 📄 Playbook Ansible
    └── roles/
        └── nginx/            # 📁 Rôle NGINX
            ├── tasks/
            │   └── main.yml  # 📄 Tâches principales
            ├── handlers/
            │   └── main.yml  # 📄 Handlers (redémarrage, etc.)
            ├── templates/
            │   └── nginx.conf.j2  # 📄 Template de configuration
            └── vars/
                └── main.yml  # 📄 Variables du rôle
```

#### **2. Créer les fichiers Terraform**

---

##### **📄 `terraform/exercice-1/main.tf`**

```hcl
# =============================================================================
# EXERCICE 1 : Terraform + Ansible + NGINX
# Fichier : main.tf
# Description : Configuration principale pour créer 2 instances EC2 avec NGINX
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Configuration du Provider AWS
# -----------------------------------------------------------------------------
# Le provider AWS permet à Terraform d'interagir avec AWS
# La région est définie dans variables.tf ou terraform.tfvars
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuration du provider AWS avec la région
provider "aws" {
  region = var.aws_region
  
  # Utilisation des variables d'environnement pour les credentials
  # NE JAMAIS mettre les credentials directement dans le code !
  # Ils sont lus depuis :
  # - Variables d'environnement (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # - Fichier ~/.aws/credentials
  # - IAM Role (si exécuté sur une instance EC2)
}

# -----------------------------------------------------------------------------
# 2. Création du VPC
# -----------------------------------------------------------------------------
# Un VPC (Virtual Private Cloud) isole vos ressources dans AWS
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

# -----------------------------------------------------------------------------
# 3. Création des Subnets
# -----------------------------------------------------------------------------
# Les subnets divisent le VPC en sous-réseaux
# Ici, on crée 2 subnets publics (un dans chaque AZ pour la redondance)

# Subnet Public A (AZ: eu-west-3a)
resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.p5_vpc.id
  cidr_block        = var.public_subnet_a_cidr
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Attribue une IP publique automatiquement
  
  tags = {
    Name        = "p5-public-subnet-a"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# Subnet Public B (AZ: eu-west-3b)
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

# -----------------------------------------------------------------------------
# 4. Création de l'Internet Gateway
# -----------------------------------------------------------------------------
# L'Internet Gateway permet aux instances dans les subnets publics
# d'accéder à Internet et d'être accessibles depuis Internet
resource "aws_internet_gateway" "p5_igw" {
  vpc_id = aws_vpc.p5_vpc.id
  
  tags = {
    Name        = "p5-igw-exercice-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# 5. Création de la Route Table
# -----------------------------------------------------------------------------
# La route table définit comment le trafic est routé
# Ici, on ajoute une route vers l'Internet Gateway pour le trafic sortants
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.p5_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"  # Tout le trafic
    gateway_id = aws_internet_gateway.p5_igw.id
  }
  
  tags = {
    Name        = "p5-public-route-table"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# 6. Association des Subnets à la Route Table
# -----------------------------------------------------------------------------
# On associe chaque subnet public à la route table
resource "aws_route_table_association" "public_subnet_a_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_b_association" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_route_table.id
}

# -----------------------------------------------------------------------------
# 7. Création du Security Group pour NGINX
# -----------------------------------------------------------------------------
# Un Security Group agit comme un firewall pour les instances EC2
# Ici, on autorise :
# - SSH (port 22) depuis VOTRE IP uniquement
# - HTTP (port 80) depuis n'importe où
# - Tout le trafic sortant
resource "aws_security_group" "nginx_sg" {
  name        = "p5-nginx-sg"
  description = "Security Group pour les serveurs NGINX"
  vpc_id      = aws_vpc.p5_vpc.id
  
  # Règle entrante : SSH depuis votre IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]  # Remplacez par votre IP/32
  }
  
  # Règle entrante : HTTP depuis n'importe où
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Règle sortante : Tout le trafic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Tous les protocoles
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "p5-nginx-sg"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# 8. Création de la paire de clés SSH
# -----------------------------------------------------------------------------
# Une paire de clés SSH permet de se connecter aux instances EC2
# ATTENTION : La clé privée sera stockée localement et NE DOIT PAS être commité !
resource "aws_key_pair" "p5_key_pair" {
  key_name   = "p5-key-exercice-1"
  public_key = file(var.ssh_public_key_path)  # Chemin vers votre clé publique
  
  tags = {
    Name        = "p5-key-exercice-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# -----------------------------------------------------------------------------
# 9. Création des Instances EC2 pour NGINX
# -----------------------------------------------------------------------------
# On crée 2 instances EC2 identiques pour NGINX
# Une dans chaque subnet public pour la redondance

# Instance NGINX-1 (Subnet A)
resource "aws_instance" "nginx_1" {
  ami           = var.ami_id  # Amazon Linux 2
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_a.id
  
  # Configuration du Security Group
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  
  # Configuration de la clé SSH
  key_name = aws_key_pair.p5_key_pair.key_name
  
  # Tags pour identifier l'instance
  tags = {
    Name        = "p5-nginx-1"
    Environment = "dev"
    Project     = "p5-openclassrooms"
    Role        = "web-server"
  }
  
  # User Data : Script exécuté au premier démarrage
  # Ici, on installe les prérequis pour Ansible
  user_data = <<-EOF
              #!/bin/bash
              # Mise à jour des packages
              yum update -y
              
              # Installation de Python 3 (requis pour Ansible)
              amazon-linux-extras install python3.8 -y
              
              # Installation de pip
              yum install python3-pip -y
              
              # Installation de boto3 (pour Ansible AWS modules)
              pip3 install boto3
              EOF
}

# Instance NGINX-2 (Subnet B)
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

# -----------------------------------------------------------------------------
# 10. Création d'une Elastic IP pour NGINX-1 (Optionnel)
# -----------------------------------------------------------------------------
# Une Elastic IP est une IP publique statique
# Utile si vous voulez une IP fixe pour accéder à votre serveur
# resource "aws_eip" "nginx_1_eip" {
#   instance = aws_instance.nginx_1.id
#   vpc      = true
#   
#   tags = {
#     Name = "p5-nginx-1-eip"
#   }
# }
```

---

##### **📄 `terraform/exercice-1/variables.tf`**

```hcl
# =============================================================================
# EXERCICE 1 : Variables Terraform
# Fichier : variables.tf
# Description : Déclaration de toutes les variables utilisées dans main.tf
# =============================================================================

# -----------------------------------------------------------------------------
# Variables AWS
# -----------------------------------------------------------------------------
variable "aws_region" {
  description = "Région AWS où déployer les ressources"
  type        = string
  default     = "eu-west-3"  # Paris
}

# -----------------------------------------------------------------------------
# Variables VPC et Réseau
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block pour le subnet public A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block pour le subnet public B"
  type        = string
  default     = "10.0.2.0/24"
}

# -----------------------------------------------------------------------------
# Variables pour les Instances EC2
# -----------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI ID pour les instances EC2 (Amazon Linux 2)"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 - eu-west-3
  # Pour trouver l'AMI ID : aws ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2' --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"  # Éligible au Free Tier
}

# -----------------------------------------------------------------------------
# Variables de Sécurité
# -----------------------------------------------------------------------------
variable "your_ip_cidr" {
  description = "Votre IP publique en notation CIDR (ex: 192.168.1.1/32)"
  type        = string
  # Trouvez votre IP avec : curl ifconfig.me
}

variable "ssh_public_key_path" {
  description = "Chemin vers votre clé publique SSH"
  type        = string
  default     = "~/.ssh/p5-key.pub"  # Chemin par défaut
}
```

---

##### **📄 `terraform/exercice-1/outputs.tf`**

```hcl
# =============================================================================
# EXERCICE 1 : Outputs Terraform
# Fichier : outputs.tf
# Description : Valeurs retournées après le déploiement
# =============================================================================

# -----------------------------------------------------------------------------
# Outputs VPC
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID du VPC créé"
  value       = aws_vpc.p5_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block du VPC"
  value       = aws_vpc.p5_vpc.cidr_block
}

# -----------------------------------------------------------------------------
# Outputs Subnets
# -----------------------------------------------------------------------------
output "public_subnet_a_id" {
  description = "ID du subnet public A"
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "ID du subnet public B"
  value       = aws_subnet.public_subnet_b.id
}

# -----------------------------------------------------------------------------
# Outputs Security Group
# -----------------------------------------------------------------------------
output "nginx_security_group_id" {
  description = "ID du Security Group pour NGINX"
  value       = aws_security_group.nginx_sg.id
}

# -----------------------------------------------------------------------------
# Outputs Instances EC2
# -----------------------------------------------------------------------------
output "nginx_1_public_ip" {
  description = "IP publique de l'instance NGINX-1"
  value       = aws_instance.nginx_1.public_ip
}

output "nginx_1_private_ip" {
  description = "IP privée de l'instance NGINX-1"
  value       = aws_instance.nginx_1.private_ip
}

output "nginx_2_public_ip" {
  description = "IP publique de l'instance NGINX-2"
  value       = aws_instance.nginx_2.public_ip
}

output "nginx_2_private_ip" {
  description = "IP privée de l'instance NGINX-2"
  value       = aws_instance.nginx_2.private_ip
}

# -----------------------------------------------------------------------------
# Outputs pour Ansible
# -----------------------------------------------------------------------------
# Ces outputs seront utilisés pour générer l'inventaire Ansible
output "nginx_1_public_dns" {
  description = "DNS public de l'instance NGINX-1"
  value       = aws_instance.nginx_1.public_dns
}

output "nginx_2_public_dns" {
  description = "DNS public de l'instance NGINX-2"
  value       = aws_instance.nginx_2.public_dns
}

# Affichage des URLs d'accès
output "nginx_1_url" {
  description = "URL pour accéder à NGINX-1"
  value       = "http://${aws_instance.nginx_1.public_ip}"
}

output "nginx_2_url" {
  description = "URL pour accéder à NGINX-2"
  value       = "http://${aws_instance.nginx_2.public_ip}"
}
```

---

##### **📄 `terraform/exercice-1/terraform.tfvars`**

```hcl
# =============================================================================
# EXERCICE 1 : Variables Terraform (VALUES)
# Fichier : terraform.tfvars
# Description : Valeurs concrètes des variables
# ⚠️ ATTENTION : NE PAS COMMITER CE FICHIER DANS GIT !
# =============================================================================

# Région AWS (laisser eu-west-3 pour Paris)
aws_region = "eu-west-3"

# CIDR blocks (laisser les valeurs par défaut)
vpc_cidr = "10.0.0.0/16"
public_subnet_a_cidr = "10.0.1.0/24"
public_subnet_b_cidr = "10.0.2.0/24"

# Type d'instance (t2.micro est éligible au Free Tier)
instance_type = "t2.micro"

# AMI ID (Amazon Linux 2 pour eu-west-3)
# Pour vérifier : aws ec2 describe-images --owners amazon --filters 'Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2' --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' --output text
ami_id = "ami-0c55b159cbfafe1f0"

# 🔴 À MODIFIER : Votre IP publique
# Trouvez votre IP avec : curl ifconfig.me
# Format : "VOTRE_IP/32"
your_ip_cidr = "192.168.1.1/32"  # ⚠️ Remplacez par votre IP !

# Chemin vers votre clé publique SSH
# Générez une clé avec : ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key
ssh_public_key_path = "~/.ssh/p5-key.pub"
```

---

#### **3. Créer les fichiers Ansible**

---

##### **📄 `ansible/inventories/exercice-1.ini`**

```ini
# =============================================================================
# EXERCICE 1 : Inventaire Ansible
# Fichier : inventories/exercice-1.ini
# Description : Liste des serveurs à configurer
# =============================================================================

# 📌 Après avoir exécuté Terraform, récupérez les IPs avec :
# terraform output -raw nginx_1_public_ip
# terraform output -raw nginx_2_public_ip

# 📌 Ou utilisez ce script pour générer l'inventaire automatiquement :
# ./scripts/generate-inventory.sh exercice-1

[nginx_servers]
# Remplacez les IPs par celles de vos instances
nginx-1 ansible_host=1.2.3.4 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
nginx-2 ansible_host=5.6.7.8 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[nginx_servers:vars]
# Variables communes à tous les serveurs NGINX
ansible_python_interpreter=/usr/bin/python3
```

---

##### **📄 `ansible/playbooks/deploy-nginx.yml`**

```yaml
---
# =============================================================================
# EXERCICE 1 : Playbook Ansible - Déploiement NGINX
# Fichier : playbooks/deploy-nginx.yml
# Description : Playbook pour installer et configurer NGINX
# =============================================================================

# Cible : Tous les serveurs dans le groupe 'nginx_servers'
- name: Deploy and configure NGINX on all web servers
  hosts: nginx_servers
  become: true  # Exécuter avec sudo
  
  # Variables globales pour le playbook
  vars:
    nginx_version: "1.23"  # Version de NGINX à installer
    web_root: "/var/www/html"
    
  # Rôles à appliquer
  roles:
    - nginx
  
  # Tâches post-déploiement (optionnel)
  post_tasks:
    - name: Display NGINX version
      command: nginx -v
      register: nginx_version_output
      changed_when: false  # Ne pas marquer comme changé
      
    - name: Show NGINX version
      debug:
        msg: "NGINX version: {{ nginx_version_output.stdout }}"
      
    - name: Test NGINX configuration
      command: nginx -t
      register: nginx_test
      changed_when: false
      
    - name: Show NGINX test result
      debug:
        msg: "NGINX configuration test: {{ nginx_test.stdout }}"
```

---

##### **📄 `ansible/roles/nginx/tasks/main.yml`**

```yaml
---
# =============================================================================
# EXERCICE 1 : Rôle NGINX - Tâches principales
# Fichier : roles/nginx/tasks/main.yml
# Description : Tâches pour installer et configurer NGINX
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Installation des dépendances
# -----------------------------------------------------------------------------
- name: Install required packages
  ansible.builtin.yum:
    name:
      - epel-release  # Repository supplémentaire pour NGINX
      - git
      - curl
      - wget
    state: present
    update_cache: yes
  
  tags:
    - dependencies
    - install

# -----------------------------------------------------------------------------
# 2. Ajout du repository NGINX (pour avoir la dernière version)
# -----------------------------------------------------------------------------
- name: Add NGINX repository
  ansible.builtin.yum_repository:
    name: nginx
    description: "NGINX Official Repository"
    baseurl: "https://nginx.org/packages/mainline/amazon/2/$releasever/$basearch/"
    gpgkey: "https://nginx.org/keys/nginx_signing.key"
    gpgcheck: yes
    repo_gpgcheck: yes
    enabled: yes
  
  tags:
    - repository
    - install

# -----------------------------------------------------------------------------
# 3. Installation de NGINX
# -----------------------------------------------------------------------------
- name: Install NGINX
  ansible.builtin.yum:
    name: nginx
    state: present
    update_cache: yes
  
  notify: restart nginx  # Déclenche le handler si NGINX est installé/mis à jour
  
  tags:
    - nginx
    - install

# -----------------------------------------------------------------------------
# 4. Création du répertoire web
# -----------------------------------------------------------------------------
- name: Create web root directory
  ansible.builtin.file:
    path: "{{ web_root }}"
    state: directory
    owner: ec2-user
    group: ec2-user
    mode: '0755'
  
  tags:
    - configuration
    - web

# -----------------------------------------------------------------------------
# 5. Déploiement d'une page web statique
# -----------------------------------------------------------------------------
- name: Deploy static HTML page
  ansible.builtin.copy:
    dest: "{{ web_root }}/index.html"
    content: |
      <!DOCTYPE html>
      <html lang="fr">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>P5 OpenClassrooms - Exercice 1</title>
          <style>
              body {
                  font-family: Arial, sans-serif;
                  text-align: center;
                  background-color: #f0f0f0;
                  margin: 0;
                  padding: 50px;
              }
              h1 {
                  color: #2c3e50;
              }
              p {
                  color: #7f8c8d;
                  font-size: 18px;
              }
              .server-info {
                  background-color: white;
                  border-radius: 10px;
                  padding: 20px;
                  margin: 20px auto;
                  max-width: 600px;
                  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              }
              .server-info h2 {
                  color: #e74c3c;
                  margin-top: 0;
              }
              .server-info p {
                  margin: 10px 0;
              }
          </style>
      </head>
      <body>
          <h1>✅ Bienvenue sur P5 OpenClassrooms !</h1>
          <p>Exercice 1 : Terraform + Ansible + NGINX</p>
          
          <div class="server-info">
              <h2>🖥️ Informations du Serveur</h2>
              <p><strong>Nom:</strong> {{ ansible_hostname }}</p>
              <p><strong>IP Privée:</strong> {{ ansible_default_ipv4.address }}</p>
              <p><strong>IP Publique:</strong> {{ ansible_default_ipv4.public_ip | default('N/A') }}</p>
              <p><strong>Système:</strong> {{ ansible_distribution }} {{ ansible_distribution_version }}</p>
              <p><strong>NGINX Version:</strong> {{ nginx_version }}</p>
          </div>
          
          <p>🎉 Déploiement réussi avec Terraform et Ansible !</p>
      </body>
      </html>
    mode: '0644'
    owner: ec2-user
    group: ec2-user
  
  notify: restart nginx
  
  tags:
    - web
    - content

# -----------------------------------------------------------------------------
# 6. Déploiement de la configuration NGINX
# -----------------------------------------------------------------------------
- name: Deploy NGINX configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
  
  notify: restart nginx
  
  tags:
    - configuration
    - nginx

# -----------------------------------------------------------------------------
# 7. Activation et démarrage de NGINX
# -----------------------------------------------------------------------------
- name: Ensure NGINX is enabled and running
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: yes
  
  tags:
    - service
    - nginx
```

---

##### **📄 `ansible/roles/nginx/handlers/main.yml`**

```yaml
---
# =============================================================================
# EXERCICE 1 : Rôle NGINX - Handlers
# Fichier : roles/nginx/handlers/main.yml
# Description : Handlers pour redémarrer NGINX
# =============================================================================

# Handler pour redémarrer NGINX
# Déclenché quand un changement nécessite un redémarrage
- name: restart nginx
  ansible.builtin.service:
    name: nginx
    state: restarted
  
  # Écouter les notifications
  listen: "restart nginx"

# Handler pour recharger NGINX (si la config change mais pas besoin de redémarrer)
- name: reload nginx
  ansible.builtin.service:
    name: nginx
    state: reloaded
  
  listen: "reload nginx"
```

---

##### **📄 `ansible/roles/nginx/templates/nginx.conf.j2`**

```nginx
# =============================================================================
# EXERCICE 1 : Template de configuration NGINX
# Fichier : roles/nginx/templates/nginx.conf.j2
# Description : Configuration personnalisée pour NGINX
# =============================================================================

# Contexte d'exécution
user  nginx;
worker_processes  auto;

# Optimisation des performances
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

# Configuration des workers
events {
    worker_connections  1024;
}

# Configuration HTTP
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Format des logs
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    # Paramètres de performance
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    
    # Gzip compression
    gzip  on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # Server block par défaut
    server {
        listen       80;
        listen       [::]:80;
        server_name  _;
        root         {{ web_root }};
        
        # Page d'index
        index index.html;
        
        # Gestion des erreurs
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        
        # Location pour la racine
        location / {
            try_files $uri $uri/ =404;
        }
        
        # Location pour les fichiers statiques
        location ~* \.(jpg|jpeg|gif|png|ico|css|js|woff2)$ {
            expires 30d;
            add_header Cache-Control "public, no-transform";
        }
    }

    # Inclure les configurations supplémentaires
    include /etc/nginx/conf.d/*.conf;
}
```

---

##### **📄 `ansible/roles/nginx/vars/main.yml`**

```yaml
---
# =============================================================================
# EXERCICE 1 : Rôle NGINX - Variables
# Fichier : roles/nginx/vars/main.yml
# Description : Variables spécifiques au rôle NGINX
# =============================================================================

# Version de NGINX
nginx_version: "1.23"

# Répertoire racine web
web_root: "/var/www/html"

# Ports NGINX
nginx_port: 80

# Nom du service NGINX
nginx_service_name: "nginx"
```

---

### **🚀 Étapes d'Exécution**

#### **📌 Étape 1 : Préparation de l'Environnement**

1. **Installer les outils nécessaires** :
   ```bash
   # Sur macOS (avec Homebrew)
   brew install terraform ansible awscli
   
   # Sur Linux (Ubuntu/Debian)
   sudo apt update
   sudo apt install -y terraform ansible awscli
   
   # Sur Linux (CentOS/RHEL)
   sudo yum install -y terraform ansible awscli
   ```

2. **Configurer AWS CLI** :
   ```bash
   aws configure
   # AWS Access Key ID: [VOTRE_ACCESS_KEY]
   # AWS Secret Access Key: [VOTRE_SECRET_KEY]
   # Default region name: eu-west-3
   # Default output format: json
   ```

3. **Générer une paire de clés SSH** :
   ```bash
   # Générer une nouvelle paire de clés
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key -N ""
   
   # Vérifier que la clé publique existe
   ls -la ~/.ssh/p5-key.pub
   
   # Trouver votre IP publique
   curl ifconfig.me
   ```

4. **Cloner le dépôt et se positionner** :
   ```bash
   git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
   cd p5_Openclassrooms
   ```

---

#### **📌 Étape 2 : Configuration de Terraform**

1. **Modifier le fichier `terraform/exercice-1/terraform.tfvars`** :
   ```bash
   # Remplacez votre IP (exemple : 82.123.45.67/32)
   nano terraform/exercice-1/terraform.tfvars
   ```
   
   Modifiez la ligne :
   ```hcl
   your_ip_cidr = "VOTRE_IP_PUBLIQUE/32"
   ```

2. **Vérifier le chemin de la clé SSH** :
   Assurez-vous que le chemin dans `terraform.tfvars` est correct :
   ```hcl
   ssh_public_key_path = "~/.ssh/p5-key.pub"
   ```

---

#### **📌 Étape 3 : Déploiement avec Terraform**

1. **Initialiser Terraform** (télécharge les providers) :
   ```bash
   cd terraform/exercice-1
   terraform init
   ```
   
   **Sortie attendue** :
   ```
   Initializing the backend...
   Initializing provider plugins...
   - Finding hashicorp/aws versions matching "~> 5.0"...
   - Installing hashicorp/aws v5.x.x...
   - Installed hashicorp/aws v5.x.x (signed by HashiCorp)
   
   Terraform has been successfully initialized!
   ```

2. **Vérifier la configuration avec `plan`** :
   ```bash
   terraform plan
   ```
   
   **Ce que fait `plan`** :
   - Analyse votre code Terraform
   - Compare avec l'état actuel (state)
   - Affiche les **changements qui seront appliqués**
   - **Ne modifie rien** sur AWS
   
   **Sortie attendue** :
   ```
   Terraform used the selected providers or latest git version.
   
   Terraform will perform the following actions:
     + Create aws_vpc.p5_vpc
     + Create aws_subnet.public_subnet_a
     + Create aws_subnet.public_subnet_b
     + ... (toutes les ressources)
   
   Plan: 12 to add, 0 to change, 0 to destroy.
   ```

3. **Appliquer la configuration** :
   ```bash
   terraform apply
   ```
   
   **Ce que fait `apply`** :
   - Crée toutes les ressources définies dans votre code
   - Affiche la progression en temps réel
   - **Modifie réellement votre infrastructure AWS**
   
   **Sortie attendue** :
   ```
   Do you want to perform these actions?
     Terraform will perform the actions described above.
     Only 'yes' will be accepted to approve.
   
     Enter a value: yes
   
   aws_vpc.p5_vpc: Creating...
   aws_vpc.p5_vpc: Creation complete [id=vpc-xxxxx]
   aws_subnet.public_subnet_a: Creating...
   ...
   
   Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
   ```

4. **Récupérer les informations de sortie** :
   ```bash
   # Afficher toutes les outputs
   terraform output
   
   # Récupérer une output spécifique
   terraform output nginx_1_public_ip
   terraform output nginx_2_public_ip
   ```

---

#### **📌 Étape 4 : Configuration de l'Inventaire Ansible**

1. **Générer l'inventaire automatiquement** (optionnel) :
   
   Créez un script `scripts/generate-inventory.sh` :
   ```bash
   #!/bin/bash
   # Script pour générer l'inventaire Ansible depuis Terraform
   
   EXERCICE=$1
   INVENTORY_FILE="ansible/inventories/exercice-${EXERCICE}.ini"
   
   # Récupérer les IPs depuis Terraform
   NGINX_1_IP=$(cd terraform/exercice-${EXERCICE} && terraform output -raw nginx_1_public_ip)
   NGINX_2_IP=$(cd terraform/exercice-${EXERCICE} && terraform output -raw nginx_2_public_ip)
   
   # Générer l'inventaire
   cat > "$INVENTORY_FILE" <<EOF
[nginx_servers]
nginx-1 ansible_host=${NGINX_1_IP} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
nginx-2 ansible_host=${NGINX_2_IP} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key

[nginx_servers:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
   
   echo "Inventaire généré : $INVENTORY_FILE"
   ```
   
   Puis exécutez :
   ```bash
   chmod +x scripts/generate-inventory.sh
   ./scripts/generate-inventory.sh 1
   ```

2. **Ou modifier manuellement l'inventaire** :
   ```bash
   nano ansible/inventories/exercice-1.ini
   ```
   
   Remplacez les IPs par celles retournées par Terraform :
   ```ini
   [nginx_servers]
   nginx-1 ansible_host=1.2.3.4 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
   nginx-2 ansible_host=5.6.7.8 ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/p5-key
   ```

---

#### **📌 Étape 5 : Test de Connexion SSH**

Avant de lancer Ansible, vérifiez que vous pouvez vous connecter en SSH :

```bash
# Tester la connexion à NGINX-1
ssh -i ~/.ssh/p5-key ec2-user@$(terraform -C terraform/exercice-1 output -raw nginx_1_public_ip)

# Tester la connexion à NGINX-2
ssh -i ~/.ssh/p5-key ec2-user@$(terraform -C terraform/exercice-1 output -raw nginx_2_public_ip)

# Quitter la session SSH
exit
```

**Si la connexion échoue** :
1. Vérifiez que le Security Group autorise votre IP sur le port 22
2. Vérifiez que la clé SSH est correcte
3. Vérifiez que l'instance est bien démarrée (console AWS)

---

#### **📌 Étape 6 : Déploiement avec Ansible**

1. **Tester la connectivité Ansible** :
   ```bash
   cd ansible
   
   # Tester la connexion à tous les serveurs
   ansible -i inventories/exercice-1.ini nginx_servers -m ping
   ```
   
   **Sortie attendue** :
   ```
   nginx-1 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   nginx-2 | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```

2. **Exécuter le playbook** :
   ```bash
   # Exécuter le playbook en mode verbose (-v pour plus de détails)
   ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml -v
   ```
   
   **Ce que fait Ansible** :
   - Se connecte à chaque serveur via SSH
   - Installe les dépendances (epel-release, git, etc.)
   - Ajoute le repository NGINX
   - Installe NGINX
   - Déploie la configuration et la page web
   - Démarre le service NGINX
   
   **Sortie attendue** :
   ```
   PLAY [Deploy and configure NGINX on all web servers] *************************************
   
   TASK [Gathering Facts] *************************************************************
   ok: [nginx-1]
   ok: [nginx-2]
   
   TASK [Install required packages] ***************************************************
   changed: [nginx-1]
   changed: [nginx-2]
   
   TASK [Add NGINX repository] ********************************************************
   changed: [nginx-1]
   changed: [nginx-2]
   
   TASK [Install NGINX] ***************************************************************
   changed: [nginx-1]
   changed: [nginx-2]
   
   ... (autres tâches)
   
   PLAY RECAP *********************************************************************
   nginx-1                    : ok=12  changed=10  unreachable=0  failed=0
   nginx-2                    : ok=12  changed=10  unreachable=0  failed=0
   ```

---

#### **📌 Étape 7 : Vérification du Déploiement**

1. **Vérifier que NGINX est installé** :
   ```bash
   # Sur chaque serveur
   ansible -i inventories/exercice-1.ini nginx_servers -a "nginx -v"
   ```

2. **Vérifier que NGINX est en cours d'exécution** :
   ```bash
   ansible -i inventories/exercice-1.ini nginx_servers -a "systemctl status nginx"
   ```

3. **Accéder à la page web** :
   Ouvrez un navigateur et allez sur :
   - `http://<IP-NGINX-1>`
   - `http://<IP-NGINX-2>`
   
   Vous devriez voir la page web personnalisée avec les informations du serveur.

4. **Vérifier les logs NGINX** :
   ```bash
   # Voir les logs d'accès
   ansible -i inventories/exercice-1.ini nginx_servers -a "tail -f /var/log/nginx/access.log"
   
   # Voir les logs d'erreur
   ansible -i inventories/exercice-1.ini nginx_servers -a "tail -f /var/log/nginx/error.log"
   ```

---

## ✅ **Vérifications**

### **📋 Checklist de Vérification**

- [ ] **Terraform** :
  - [ ] `terraform init` s'exécute sans erreur
  - [ ] `terraform plan` affiche les bonnes ressources
  - [ ] `terraform apply` crée toutes les ressources
  - [ ] `terraform output` retourne les IPs publiques

- [ ] **AWS Console** :
  - [ ] Le VPC est créé avec le bon CIDR
  - [ ] Les 2 subnets publics existent
  - [ ] L'Internet Gateway est attaché au VPC
  - [ ] Les 2 instances EC2 sont en cours d'exécution
  - [ ] Le Security Group autorise SSH (port 22) et HTTP (port 80)

- [ ] **Connexion SSH** :
  - [ ] Connexion SSH à NGINX-1 fonctionne
  - [ ] Connexion SSH à NGINX-2 fonctionne

- [ ] **Ansible** :
  - [ ] `ansible -m ping` retourne "pong" pour les 2 serveurs
  - [ ] Le playbook s'exécute sans erreur
  - [ ] NGINX est installé sur les 2 serveurs

- [ ] **NGINX** :
  - [ ] Le service NGINX est démarré
  - [ ] La page web est accessible via HTTP
  - [ ] La page affiche les bonnes informations (IP, hostname, etc.)
  - [ ] Les logs NGINX sont générés

---

### **🔍 Commandes de Vérification**

| Vérification | Commande |
|--------------|----------|
| **Liste des ressources Terraform** | `terraform state list` |
| **Afficher les outputs** | `terraform output` |
| **Voir les instances EC2** | `aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress,State.Name]' --output table` |
| **Voir les Security Groups** | `aws ec2 describe-security-groups --query 'SecurityGroups[*].[GroupName,GroupId]' --output table` |
| **Tester la connexion HTTP** | `curl http://<IP-NGINX-1>` |
| **Vérifier NGINX** | `ansible -i inventories/exercice-1.ini nginx_servers -a "systemctl status nginx"` |
| **Voir les logs** | `ansible -i inventories/exercice-1.ini nginx_servers -a "tail /var/log/nginx/access.log"` |

---

## 🛠️ **Dépannage**

### **❌ Problèmes Courants et Solutions**

#### **1. Erreur : "No valid credential sources found" (Terraform)**

**Symptômes** :
```
Error: No valid credential sources found
```

**Solutions** :
1. **Configurer AWS CLI** :
   ```bash
   aws configure
   ```
2. **Exporter les variables d'environnement** :
   ```bash
   export AWS_ACCESS_KEY_ID="VOTRE_ACCESS_KEY"
   export AWS_SECRET_ACCESS_KEY="VOTRE_SECRET_KEY"
   export AWS_DEFAULT_REGION="eu-west-3"
   ```
3. **Vérifier les permissions IAM** :
   - Votre utilisateur IAM doit avoir les permissions `AmazonEC2FullAccess` ou équivalent

---

#### **2. Erreur : "Permission denied (publickey)" (SSH)**

**Symptômes** :
```
Permission denied (publickey).
```

**Solutions** :
1. **Vérifier la clé SSH** :
   ```bash
   # Vérifier que la clé privée existe
   ls -la ~/.ssh/p5-key
   
   # Vérifier les permissions (doit être 600)
   chmod 600 ~/.ssh/p5-key
   ```
2. **Vérifier le Security Group** :
   - Le Security Group doit autoriser votre IP sur le port 22
   - Vérifiez avec :
     ```bash
     aws ec2 describe-security-groups --group-ids $(terraform -C terraform/exercice-1 output -raw nginx_security_group_id)
     ```
3. **Vérifier l'utilisateur** :
   - Pour Amazon Linux 2, l'utilisateur est `ec2-user`
   - Pour Ubuntu, c'est `ubuntu`

---

#### **3. Erreur : "Connection timed out" (SSH)**

**Symptômes** :
```
ssh: connect to host ... port 22: Connection timed out
```

**Solutions** :
1. **Vérifier que l'instance est démarrée** :
   ```bash
   aws ec2 describe-instances --instance-ids $(terraform -C terraform/exercice-1 output -raw nginx_1_instance_id) --query 'Reservations[0].Instances[0].State.Name'
   ```
2. **Vérifier l'IP publique** :
   ```bash
   terraform -C terraform/exercice-1 output nginx_1_public_ip
   ```
3. **Vérifier le Security Group** :
   - Le port 22 doit être ouvert pour votre IP
4. **Vérifier le subnet** :
   - Le subnet doit être public avec `map_public_ip_on_launch = true`

---

#### **4. Erreur : "No package nginx available" (Ansible)**

**Symptômes** :
```
TASK [Install NGINX] ***************************************************************
fatal: [nginx-1]: FAILED! => {"changed": false, "msg": "No package nginx available."}
```

**Solutions** :
1. **Vérifier le repository** :
   ```bash
   # Sur le serveur
   ssh -i ~/.ssh/p5-key ec2-user@<IP>
   yum repolist
   ```
2. **Installer manuellement le repository** :
   ```bash
   # Sur le serveur
   sudo amazon-linux-extras install nginx1 -y
   ```
3. **Utiliser le bon nom de package** :
   - Pour Amazon Linux 2 : `nginx` (après avoir ajouté le repo)
   - Alternative : `amazon-linux-extras install nginx1`

---

#### **5. Erreur : "Failed to connect to the host via ssh" (Ansible)**

**Symptômes** :
```
fatal: [nginx-1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh", ...}
```

**Solutions** :
1. **Tester la connexion SSH manuellement** :
   ```bash
   ssh -i ~/.ssh/p5-key ec2-user@<IP>
   ```
2. **Vérifier l'inventaire Ansible** :
   ```bash
   cat ansible/inventories/exercice-1.ini
   ```
3. **Vérifier le chemin de la clé SSH** :
   - Le chemin doit être absolu : `/home/user/.ssh/p5-key`
   - Pas de `~` dans le chemin

---

#### **6. Erreur : "Job for nginx.service failed" (Systemd)**

**Symptômes** :
```
Job for nginx.service failed because the control process exited with error code.
```

**Solutions** :
1. **Vérifier la configuration NGINX** :
   ```bash
   # Sur le serveur
   sudo nginx -t
   ```
2. **Vérifier les ports** :
   ```bash
   sudo netstat -tulnp | grep nginx
   sudo ss -tulnp | grep nginx
   ```
3. **Vérifier les logs** :
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

---

#### **7. Problème : NGINX ne répond pas sur le port 80**

**Symptômes** :
- `curl http://<IP>` retourne une erreur de connexion

**Solutions** :
1. **Vérifier que NGINX écoute** :
   ```bash
   # Sur le serveur
   sudo netstat -tulnp | grep 80
   ```
2. **Vérifier le firewall local** :
   ```bash
   sudo firewall-cmd --list-all  # Pour CentOS/RHEL
   sudo ufw status                # Pour Ubuntu
   ```
3. **Vérifier le Security Group AWS** :
   - Le port 80 doit être ouvert pour `0.0.0.0/0`

---

### **🔧 Outils de Dépannage**

| Outil | Commande | Description |
|-------|----------|-------------|
| **AWS CLI** | `aws ec2 describe-instances` | Lister les instances |
| **AWS CLI** | `aws ec2 describe-security-groups` | Voir les Security Groups |
| **SSH** | `ssh -v -i ~/.ssh/p5-key ec2-user@<IP>` | Connexion SSH en mode verbose |
| **Ansible** | `ansible -i inventories/exercice-1.ini nginx_servers -m setup` | Récupérer toutes les infos des serveurs |
| **Curl** | `curl -v http://<IP>` | Tester la connexion HTTP en mode verbose |
| **Nmap** | `nmap -Pn <IP>` | Scanner les ports ouverts |
| **Journalctl** | `journalctl -u nginx -f` | Voir les logs systemd de NGINX |

---

## 📝 **Journal de Session (Exemple)**

> ⚠️ **À compléter dans** : [📄 journal-session.md](../livrables/journal-session.md)

### **📅 Date : [AAAA-MM-JJ]**

#### **🕒 Début de Session : [HH:MM]**

**Objectif** : Déployer 2 serveurs NGINX avec Terraform et Ansible

---

**Étape 1 : Préparation**
- [x] Installation de Terraform, Ansible, AWS CLI
- [x] Configuration AWS CLI (`aws configure`)
- [x] Génération de la paire de clés SSH (`ssh-keygen`)
- [x] Clonage du dépôt Git

**Problèmes rencontrés** : Aucun

---

**Étape 2 : Terraform**
- [x] Modification de `terraform.tfvars` (IP personnelle)
- [x] `terraform init` → Succès
- [x] `terraform plan` → 12 ressources à créer
- [x] `terraform apply` → Toutes les ressources créées

**Outputs Terraform** :
```
nginx_1_public_ip = "52.47.123.45"
nginx_2_public_ip = "3.235.67.89"
```

**Problèmes rencontrés** : Aucun

---

**Étape 3 : Ansible**
- [x] Génération de l'inventaire avec le script
- [x] Test de connexion (`ansible -m ping`) → Succès
- [x] Exécution du playbook → 12 tâches, 10 changées

**Problèmes rencontrés** :
- ❌ Erreur "No package nginx available"
  - **Solution** : Ajout manuel du repository NGINX sur les serveurs
  - **Commande** : `sudo amazon-linux-extras install nginx1 -y`

---

**Étape 4 : Vérification**
- [x] Accès HTTP à NGINX-1 → Page affichée correctement
- [x] Accès HTTP à NGINX-2 → Page affichée correctement
- [x] Vérification des logs → Logs générés

---

**🕒 Fin de Session : [HH:MM]**

**Durée totale** : [X] heures [Y] minutes

**Bilan** :
✅ Toutes les étapes complétées avec succès
✅ 2 serveurs NGINX déployés et accessibles
✅ Infrastructure-as-Code fonctionnelle

---

## 📌 **Résumé des Commandes Utiles**

### **Terraform**

| Commande | Description |
|----------|-------------|
| `terraform init` | Initialise le backend et télécharge les providers |
| `terraform plan` | Aperçu des changements à appliquer |
| `terraform apply` | Applique les changements |
| `terraform destroy` | Supprime toutes les ressources |
| `terraform output` | Affiche les outputs définis |
| `terraform state list` | Liste toutes les ressources gérées |
| `terraform state show <ressource>` | Affiche les détails d'une ressource |

### **Ansible**

| Commande | Description |
|----------|-------------|
| `ansible -i inventory.ini all -m ping` | Test de connectivité |
| `ansible -i inventory.ini all -a "commande"` | Exécute une commande sur tous les serveurs |
| `ansible-playbook -i inventory.ini playbook.yml` | Exécute un playbook |
| `ansible -i inventory.ini all -m setup` | Récupère toutes les infos des serveurs |
| `ansible-inventory -i inventory.ini --list` | Affiche l'inventaire |

### **AWS CLI**

| Commande | Description |
|----------|-------------|
| `aws ec2 describe-instances` | Liste toutes les instances |
| `aws ec2 describe-vpcs` | Liste tous les VPC |
| `aws ec2 describe-subnets` | Liste tous les subnets |
| `aws ec2 describe-security-groups` | Liste tous les Security Groups |
| `aws ec2 describe-key-pairs` | Liste toutes les paires de clés |

### **SSH**

| Commande | Description |
|----------|-------------|
| `ssh -i ~/.ssh/p5-key ec2-user@<IP>` | Connexion SSH à un serveur |
| `ssh -v -i ~/.ssh/p5-key ec2-user@<IP>` | Connexion SSH en mode verbose |
| `scp -i ~/.ssh/p5-key fichier ec2-user@<IP>:/chemin` | Copier un fichier via SCP |

### **NGINX**

| Commande | Description |
|----------|-------------|
| `sudo systemctl start nginx` | Démarre NGINX |
| `sudo systemctl stop nginx` | Arrête NGINX |
| `sudo systemctl restart nginx` | Redémarre NGINX |
| `sudo systemctl status nginx` | Affiche le statut de NGINX |
| `sudo nginx -t` | Teste la configuration NGINX |
| `sudo nginx -v` | Affiche la version de NGINX |
| `sudo tail -f /var/log/nginx/access.log` | Affiche les logs d'accès |
| `sudo tail -f /var/log/nginx/error.log` | Affiche les logs d'erreur |

---

## 🎓 **Ce que vous avez appris**

✅ **Terraform** :
- Créer un VPC, des subnets, des Security Groups
- Lancer des instances EC2
- Gérer l'état de l'infrastructure
- Utiliser des variables et des outputs

✅ **Ansible** :
- Créer un inventaire
- Écrire un playbook
- Utiliser des rôles
- Déployer une configuration sur plusieurs serveurs

✅ **NGINX** :
- Installer et configurer NGINX
- Déployer une page web statique
- Gérer le service NGINX
- Comprendre les logs

✅ **AWS** :
- Comprendre les concepts VPC, Subnet, Security Group
- Utiliser EC2
- Gérer les clés SSH

✅ **DevOps** :
- Automatiser le déploiement d'infrastructure
- Utiliser Infrastructure-as-Code
- Travailler avec Git
- Dépanner des problèmes d'infrastructure

---

## 🚀 **Prochaine Étape**

**Passer à l'[Exercice 2 - OpenSearch (ELK)](../exercice-2-opensearch.md)** pour :
- Déployer un cluster OpenSearch
- Configurer Logstash pour la collecte de logs
- Visualiser les logs avec Kibana
- Intégrer Filebeat sur vos serveurs NGINX

---

**Félicitations !** 🎉

Vous avez réussi à déployer votre première infrastructure avec **Terraform + Ansible + NGINX** !

> *"Le succès, c'est d'aller d'échec en échec sans perdre son enthousiasme."* — **Winston Churchill**
