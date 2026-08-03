# ☁️ Exercice 4 : Infrastructure as Code avec Terraform

**Bienvenue dans l'Exercice 4 !**
Ici, vous allez apprendre à **provisionner une infrastructure cloud** avec **Terraform**. Cet exercice est conçu pour les **débutants en Infrastructure as Code (IaC)** et couvre les bases de Terraform : providers, ressources, variables, outputs, et plus.

---

## 📌 Table des Matières

1. [🎯 Objectifs](#-objectifs)
2. [🛠️ Prérequis](#-prérequis)
3. [📥 Préparation de l'Environnement](#-préparation-de-lenvironnement)
4. [📝 Étape 1 : Installer Terraform](#-étape-1-installer-terraform)
5. [📝 Étape 2 : Configurer un Provider AWS](#-étape-2-configurer-un-provider-aws)
6. [📝 Étape 3 : Créer une Ressource Simple (Instance EC2)](#-étape-3-créer-une-ressource-simple-instance-ec2)
7. [📝 Étape 4 : Utiliser des Variables](#-étape-4-utiliser-des-variables)
8. [📝 Étape 5 : Créer un Réseau Complet (VPC, Subnet, Security Group)](#-étape-5-créer-un-réseau-complet-vpc-subnet-security-group)
9. [📝 Étape 6 : Utiliser des Outputs](#-étape-6-utiliser-des-outputs)
10. [📝 Étape 7 : Détruire l'Infrastructure](#-étape-7-détruire-linfrastructure)
11. [✅ Vérification](#-vérification)
12. [🔍 Résolution des Problèmes](#-résolution-des-problèmes)
13. [📚 Pour Aller Plus Loin](#-pour-aller-plus-loin)

---

## 🎯 Objectifs

À la fin de cet exercice, vous serez capable de :
✅ **Comprendre** les concepts de base de Terraform (IaC, providers, ressources).
✅ **Installer** Terraform sur votre machine.
✅ **Configurer** un provider (AWS, Azure, GCP, etc.).
✅ **Créer** des ressources cloud (instances, réseaux, etc.).
✅ **Utiliser** des variables et des outputs.
✅ **Gérer** l'état Terraform (`terraform.tfstate`).
✅ **Détruire** une infrastructure de manière propre.

---

## 🛠️ Prérequis

Avant de commencer, assurez-vous d'avoir :

| Outil | Version | Vérification | Lien d'Installation |
|-------|---------|--------------|---------------------|
| **Terraform** | 1.5.x | `terraform --version` | [terraform.io](https://www.terraform.io/) |
| **AWS CLI** | 2.x | `aws --version` | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| **Compte AWS** | - | - | [aws.amazon.com](https://aws.amazon.com/) |
| **Clés AWS** | - | - | IAM Console |

> **⚠️ Important** :
> - Vous avez besoin d'un **compte AWS** avec des **permissions IAM** pour créer des ressources.
> - Les ressources créées dans cet exercice **coûtent de l'argent** (mais très peu, ~0.01$ par heure pour une instance t2.micro).
> - **Pensez à détruire l'infrastructure** après l'exercice pour éviter des frais inutiles.

---

## 📥 Préparation de l'Environnement

### 1. Cloner le Dépôt du Projet P5
Si ce n'est pas déjà fait, clonez le dépôt :
```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 2. Créer un Dossier pour l'Exercice
```bash
mkdir -p ~/p5-exercise-4 && cd ~/p5-exercise-4
```

### 3. Configurer les Clés AWS
1. Allez sur la [Console IAM AWS](https://console.aws.amazon.com/iam/).
2. Cliquez sur **Users** > **Votre utilisateur** > **Security credentials**.
3. Cliquez sur **Create access key**.
4. Sélectionnez **Command Line Interface (CLI)** et cliquez sur **Next**.
5. Donnez une description (ex: `p5-exercise-4`) et cliquez sur **Create access key**.
6. **Copiez** la **Access Key ID** et la **Secret Access Key** (vous ne pourrez plus les voir après).

### 4. Configurer AWS CLI
```bash
# Configurer AWS CLI avec vos clés
aws configure
```

> **Répondez aux questions comme suit** (remplacez par vos valeurs) :
> ```
> AWS Access Key ID [None]: VOTRE_ACCESS_KEY_ID
> AWS Secret Access Key [None]: VOTRE_SECRET_ACCESS_KEY
> Default region name [None]: eu-west-3  # Région : Paris
> Default output format [None]: json
> ```

### 5. Vérifier la Configuration
```bash
# Vérifier que AWS CLI est bien configuré
aws sts get-caller-identity
```

> **✅ Résultat attendu** : Vous devriez voir :
> ```json
> {
>     "UserId": "AIDASAMPLEUSERID",
>     "Account": "123456789012",
>     "Arn": "arn:aws:iam::123456789012:user/votre-utilisateur"
> }
> ```

---

## 📝 Étape 1 : Installer Terraform

### 1. Télécharger Terraform
Terraform est distribué sous forme de **binaire unique**. Téléchargez la dernière version depuis le site officiel.

#### Sur Linux/macOS :
```bash
# Télécharger Terraform (version 1.5.x)
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip

# Décompresser l'archive
unzip terraform_1.5.7_linux_amd64.zip

# Déplacer le binaire dans /usr/local/bin
sudo mv terraform /usr/local/bin/

# Supprimer l'archive
rm terraform_1.5.7_linux_amd64.zip
```

#### Sur Windows (PowerShell) :
```powershell
# Télécharger Terraform
Invoke-WebRequest -Uri https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_windows_amd64.zip -OutFile terraform.zip

# Décompresser l'archive
Expand-Archive -Path terraform.zip -DestinationPath .

# Déplacer le binaire dans un dossier du PATH
mv terraform C:\Windows\System32\

# Supprimer l'archive
rm terraform.zip
```

### 2. Vérifier l'Installation
```bash
# Vérifier la version de Terraform
terraform --version
```

> **✅ Résultat attendu** : Vous devriez voir :
> ```
> Terraform v1.5.7
> on linux_amd64
> ```

---

## 📝 Étape 2 : Configurer un Provider AWS

Un **provider** est un plugin Terraform qui permet d'interagir avec une plateforme cloud (AWS, Azure, GCP, etc.).

### 1. Créer le Fichier `main.tf`
Créez un fichier `main.tf` :
```bash
nano main.tf
```

Ajoutez le contenu suivant :
```hcl
# =============================================
# Configuration du provider AWS
# =============================================

# Bloc terraform : configure la version de Terraform et les providers requis
terraform {
  # Version minimale de Terraform requise
  required_version = ">= 1.5.0"

  # Providers requis
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Version 4.x du provider AWS
    }
  }
}

# Configuration du provider AWS
provider "aws" {
  # Région AWS (Paris = eu-west-3)
  region = "eu-west-3"

  # Utilise les credentials par défaut (configurés via AWS CLI)
  # Si vous voulez spécifier des credentials ici (non recommandé) :
  # access_key = "VOTRE_ACCESS_KEY"
  # secret_key = "VOTRE_SECRET_KEY"
}

# =============================================
# Explications :
# - terraform { ... } : Bloc pour configurer Terraform lui-même.
#   - required_version : Version minimale de Terraform requise.
#   - required_providers : Liste des providers requis et leurs versions.
# - provider "aws" { ... } : Configuration du provider AWS.
#   - region : Région AWS à utiliser (ex: eu-west-3 pour Paris).
#   - Les credentials sont lus depuis :
#     1. Variables d'environnement (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
#     2. Fichier ~/.aws/credentials (configuré via AWS CLI)
#     3. Paramètres dans le provider (non recommandé pour la sécurité)
# =============================================
```

> **⚠️ Sécurité** :
> - **Ne jamais stocker de clés AWS dans le code** (même dans des fichiers `.tf`).
> - Utilisez toujours **AWS CLI** ou des **variables d'environnement** pour les credentials.

### 2. Initialiser Terraform
```bash
# Initialiser Terraform (télécharge les providers)
terraform init
```

> **💡 Explication** :
> - `terraform init` :
>   - Télécharge les **providers** spécifiés dans le fichier de configuration.
>   - Initialise le **backend** (pour stocker l'état Terraform).
>   - Crée un fichier `.terraform.lock.hcl` pour verrouiller les versions des providers.

> **✅ Résultat attendu** : Vous devriez voir :
> ```
> Initializing the backend...
> 
> Initializing provider plugins...
> - Finding hashicorp/aws versions matching "~> 4.0"...
> - Installing hashicorp/aws v4.65.0...
> - Installed hashicorp/aws v4.65.0 (signed by HashiCorp)
> 
> Terraform has created a lock file .terraform.lock.hcl to record the provider
> selections it made above. Include this file in your version control repository
> so that Terraform can guarantee to make the same selections by default when
> you run "terraform init" in the future.
> 
> Terraform has been successfully initialized!
> 
> You may now begin working with Terraform. Try running "terraform plan" to see
> any changes that are required for your infrastructure. All Terraform commands
> should now work.
> 
> If you ever set or change modules or backend configurations for Terraform,
> rerun this command to reinitialize your working directory. If you forget, other
> commands will detect it and remind you to do so if necessary.
> ```

---

## 📝 Étape 3 : Créer une Ressource Simple (Instance EC2)

Une **ressource** est une unité d'infrastructure (ex: instance EC2, bucket S3, VPC, etc.).

### 1. Ajouter une Ressource EC2 à `main.tf`
Modifiez le fichier `main.tf` :
```bash
nano main.tf
```

Ajoutez le contenu suivant à la fin du fichier :
```hcl
# =============================================
# Ressource : Instance EC2
# =============================================

# Créer une instance EC2
resource "aws_instance" "p5_exercise_4" {
  # AMI (Amazon Machine Image) : Ubuntu 22.04 LTS
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 en eu-west-3

  # Type d'instance (t2.micro est éligible au Free Tier)
  instance_type = "t2.micro"

  # Clé SSH pour se connecter à l'instance
  # Remplacez par le nom de votre clé SSH (créée dans AWS EC2)
  key_name      = "votre-cle-ssh"  # À remplacer !

  # Groupe de sécurité (autorise SSH, HTTP, HTTPS)
  vpc_security_group_ids = [aws_security_group.p5_sg.id]

  # Tag pour identifier l'instance
  tags = {
    Name        = "p5-exercise-4-instance"
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Groupe de sécurité
# =============================================

# Créer un groupe de sécurité pour autoriser SSH, HTTP, HTTPS
resource "aws_security_group" "p5_sg" {
  name        = "p5-exercise-4-sg"
  description = "Groupe de sécurité pour l'exercice 4"

  # Règles de sécurité (ingress = entrée, egress = sortie)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Autorise SSH depuis n'importe où (à restreindre en production !)
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

  # Autoriser tout le trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Tous les protocoles
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tag pour identifier le groupe de sécurité
  tags = {
    Name    = "p5-exercise-4-sg"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Explications :
# - resource : Mot-clé pour définir une ressource.
# - aws_instance : Type de ressource (instance EC2).
# - p5_exercise_4 : Nom de la ressource (utilisé pour référencer la ressource).
# - ami : AMI (Amazon Machine Image) à utiliser pour l'instance.
# - instance_type : Type d'instance (t2.micro, t3.small, etc.).
# - key_name : Nom de la clé SSH pour se connecter à l'instance.
# - vpc_security_group_ids : Liste des groupes de sécurité à attacher.
# - tags : Métadonnées pour identifier la ressource.
# - aws_security_group : Type de ressource (groupe de sécurité).
# - ingress : Règles de trafic entrant.
# - egress : Règles de trafic sortant.
# - cidr_blocks : Plages d'adresses IP autorisées.
# =============================================
```

> **⚠️ Important** :
> - Remplacez `votre-cle-ssh` par le **nom de votre clé SSH** (créée dans AWS EC2).
> - Si vous n'avez pas de clé SSH, créez-en une dans la [Console EC2](https://console.aws.amazon.com/ec2/v2/home#KeyPairs:).

### 2. Vérifier la Configuration
```bash
# Vérifier la syntaxe des fichiers Terraform
terraform validate
```

> **✅ Résultat attendu** : Vous devriez voir :
> ```
> Success! The configuration is valid.
> ```

### 3. Voir le Plan d'Exécution
```bash
# Afficher le plan d'exécution (ce que Terraform va faire)
terraform plan
```

> **💡 Explication** :
> - `terraform plan` :
>   - Affiche les **changements** que Terraform va appliquer.
>   - Ne **modifie pas** l'infrastructure (c'est une simulation).
>   - Montre les ressources à **créer** (`+`), **modifier** (`~`), ou **supprimer** (`-`).

> **✅ Résultat attendu** : Vous devriez voir un résumé des ressources à créer :
> ```
> Plan: 2 to add, 0 to change, 0 to destroy.
> 
> Changes to Outputs:
>   + p5_exercise_4_instance_id = (known after apply)
> ```

### 4. Appliquer les Changements
```bash
# Appliquer les changements (créer les ressources)
terraform apply
```

> **⚠️ Attention** : Terraform va **créer des ressources réelles** sur AWS, ce qui peut engendrer des **frais**. Assurez-vous de **détruire l'infrastructure** après l'exercice.

> **💡 Explication** :
> - `terraform apply` :
>   - Crée les ressources définies dans les fichiers `.tf`.
>   - Affiche un **résumé** des changements avant de les appliquer.
>   - Demande une **confirmation** (`yes` pour valider).

> **✅ Résultat attendu** : Après confirmation, vous devriez voir :
> ```
> aws_security_group.p5_sg: Creating...
> aws_security_group.p5_sg: Creation complete after 2s [id=sg-1234567890abcdef0]
> aws_instance.p5_exercise_4: Creating...
> aws_instance.p5_exercise_4: Still creating... [10s elapsed]
> aws_instance.p5_exercise_4: Creation complete after 20s [id=i-1234567890abcdef0]
> 
> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
> ```

### 5. Vérifier les Ressources sur AWS
1. Allez sur la [Console EC2](https://console.aws.amazon.com/ec2/v2/home).
2. Cliquez sur **Instances** dans le menu de gauche.
3. Vous devriez voir une instance nommée `p5-exercise-4-instance` en cours d'exécution.
4. Cliquez sur l'**ID de l'instance** pour voir les détails.

---

## 📝 Étape 4 : Utiliser des Variables

Les **variables** permettent de **paramétrer** votre infrastructure et de la rendre plus **flexible**.

### 1. Créer un Fichier `variables.tf`
Créez un fichier `variables.tf` :
```bash
nano variables.tf
```

Ajoutez le contenu suivant :
```hcl
# =============================================
# Variables pour l'infrastructure
# =============================================

# Variable pour la région AWS
variable "aws_region" {
  description = "Région AWS à utiliser"
  type        = string
  default     = "eu-west-3"  # Paris
}

# Variable pour le type d'instance EC2
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

# Variable pour l'AMI (Amazon Machine Image)
variable "ami_id" {
  description = "AMI à utiliser pour l'instance EC2"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Ubuntu 22.04 en eu-west-3
}

# Variable pour le nom de la clé SSH
variable "key_name" {
  description = "Nom de la clé SSH pour se connecter à l'instance"
  type        = string
}

# Variable pour le nom de l'instance
variable "instance_name" {
  description = "Nom de l'instance EC2"
  type        = string
  default     = "p5-exercise-4-instance"
}

# =============================================
# Explications :
# - variable : Mot-clé pour définir une variable.
# - description : Description de la variable (affichée dans l'aide).
# - type : Type de la variable (string, number, bool, list, map, etc.).
# - default : Valeur par défaut (optionnelle).
# =============================================
```

### 2. Modifier `main.tf` pour Utiliser les Variables
Modifiez le fichier `main.tf` :
```bash
nano main.tf
```

Remplacez le contenu par :
```hcl
# =============================================
# Configuration du provider AWS
# =============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region  # Utilise la variable aws_region
}

# =============================================
# Ressource : Instance EC2
# =============================================

resource "aws_instance" "p5_exercise_4" {
  ami           = var.ami_id           # Utilise la variable ami_id
  instance_type = var.instance_type    # Utilise la variable instance_type
  key_name      = var.key_name        # Utilise la variable key_name

  vpc_security_group_ids = [aws_security_group.p5_sg.id]

  tags = {
    Name        = var.instance_name  # Utilise la variable instance_name
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Groupe de sécurité
# =============================================

resource "aws_security_group" "p5_sg" {
  name        = "p5-exercise-4-sg"
  description = "Groupe de sécurité pour l'exercice 4"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "p5-exercise-4-sg"
    Project = "p5-openclassrooms"
  }
}
```

### 3. Créer un Fichier `terraform.tfvars`
Les fichiers `.tfvars` permettent de **surcharger les valeurs des variables** sans modifier le code.

Créez un fichier `terraform.tfvars` :
```bash
nano terraform.tfvars
```

Ajoutez le contenu suivant (remplacez par vos valeurs) :
```hcl
# =============================================
# Valeurs des variables pour l'exercice 4
# =============================================

# Région AWS
aws_region = "eu-west-3"

# Type d'instance EC2
instance_type = "t2.micro"

# AMI à utiliser
ami_id = "ami-0c55b159cbfafe1f0"

# Nom de la clé SSH (à remplacer !)
key_name = "votre-cle-ssh"

# Nom de l'instance
instance_name = "p5-exercise-4-instance"
```

> **⚠️ Important** :
> - Le fichier `terraform.tfvars` **n'est pas versionné** dans Git (ajoutez-le au `.gitignore`).
> - Il permet de **personnaliser** les variables sans modifier le code.

### 4. Vérifier les Variables
```bash
# Afficher la liste des variables et leurs valeurs
terraform show
```

> **💡 Explication** :
> - `terraform show` : Affiche l'**état actuel** de l'infrastructure.

### 5. Appliquer les Changements
```bash
# Appliquer les changements (les variables sont déjà utilisées)
terraform apply
```

> **✅ Résultat attendu** : Terraform devrait **ne rien changer** (car les valeurs par défaut sont les mêmes).

---

## 📝 Étape 5 : Créer un Réseau Complet (VPC, Subnet, Security Group)

Dans cette étape, nous allons **améliorer l'infrastructure** en ajoutant un **VPC**, des **subnets**, et une **IP publique** à l'instance.

### 1. Modifier `main.tf` pour Ajouter un VPC
Modifiez le fichier `main.tf` :
```bash
nano main.tf
```

Remplacez le contenu par :
```hcl
# =============================================
# Configuration du provider AWS
# =============================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =============================================
# Ressource : VPC
# =============================================

resource "aws_vpc" "p5_vpc" {
  # Plage d'adresses IP pour le VPC (CIDR)
  cidr_block = "10.0.0.0/16"

  # Activer les DNS hostnames
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "p5-exercise-4-vpc"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Subnet Public
# =============================================

resource "aws_subnet" "p5_public_subnet" {
  # VPC dans lequel créer le subnet
  vpc_id     = aws_vpc.p5_vpc.id

  # Plage d'adresses IP pour le subnet (CIDR)
  cidr_block = "10.0.1.0/24"

  # Zone de disponibilité
  availability_zone = "${var.aws_region}a"

  # Activer l'attribution automatique d'IP publique
  map_public_ip_on_launch = true

  tags = {
    Name    = "p5-exercise-4-public-subnet"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Internet Gateway
# =============================================

resource "aws_internet_gateway" "p5_igw" {
  # VPC auquel attacher l'Internet Gateway
  vpc_id = aws_vpc.p5_vpc.id

  tags = {
    Name    = "p5-exercise-4-igw"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Route Table
# =============================================

resource "aws_route_table" "p5_public_rt" {
  # VPC auquel attacher la route table
  vpc_id = aws_vpc.p5_vpc.id

  # Route par défaut vers l'Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.p5_igw.id
  }

  tags = {
    Name    = "p5-exercise-4-public-rt"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Association de la Route Table au Subnet
# =============================================

resource "aws_route_table_association" "p5_public_assoc" {
  # Subnet à associer
  subnet_id      = aws_subnet.p5_public_subnet.id

  # Route table à associer
  route_table_id = aws_route_table.p5_public_rt.id
}

# =============================================
# Ressource : Groupe de sécurité (mis à jour)
# =============================================

resource "aws_security_group" "p5_sg" {
  name        = "p5-exercise-4-sg"
  description = "Groupe de sécurité pour l'exercice 4"
  vpc_id      = aws_vpc.p5_vpc.id  # Attacher au VPC

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "p5-exercise-4-sg"
    Project = "p5-openclassrooms"
  }
}

# =============================================
# Ressource : Instance EC2 (mis à jour)
# =============================================

resource "aws_instance" "p5_exercise_4" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  # Subnet dans lequel lancer l'instance
  subnet_id = aws_subnet.p5_public_subnet.id

  # Groupe de sécurité
  vpc_security_group_ids = [aws_security_group.p5_sg.id]

  # Attribuer une IP publique (déjà activé dans le subnet)
  associate_public_ip_address = true

  tags = {
    Name        = var.instance_name
    Environment = "dev"
    Project     = "p5-openclassrooms"
  }
}

# =============================================
# Explications :
# - aws_vpc : Crée un VPC (Virtual Private Cloud).
# - aws_subnet : Crée un subnet dans le VPC.
# - aws_internet_gateway : Crée une passerelle Internet pour le VPC.
# - aws_route_table : Crée une table de routage pour le subnet public.
# - aws_route_table_association : Associe la table de routage au subnet.
# - subnet_id : Spécifie le subnet dans lequel lancer l'instance.
# - associate_public_ip_address : Attribue une IP publique à l'instance.
# =============================================
```

### 2. Vérifier la Configuration
```bash
terraform validate
```

### 3. Voir le Plan d'Exécution
```bash
terraform plan
```

> **✅ Résultat attendu** : Vous devriez voir un résumé des **nouvelles ressources** à créer :
> ```
> Plan: 6 to add, 1 to change, 0 to destroy.
> ```

### 4. Appliquer les Changements
```bash
terraform apply
```

> **⚠️ Attention** : Terraform va **remplacer l'instance existante** (car son `subnet_id` a changé). Cela peut entraîner une **interruption de service**.

> **✅ Résultat attendu** : Après confirmation, Terraform devrait créer toutes les nouvelles ressources.

### 5. Vérifier les Ressources sur AWS
1. Allez sur la [Console VPC](https://console.aws.amazon.com/vpc/home).
2. Vérifiez que le **VPC**, le **subnet**, l'**Internet Gateway**, et la **route table** ont été créés.
3. Allez sur la [Console EC2](https://console.aws.amazon.com/ec2/v2/home) et vérifiez que l'instance a une **IP publique**.

---

## 📝 Étape 6 : Utiliser des Outputs

Les **outputs** permettent d'**afficher des informations** sur les ressources créées (ex: IP publique, ID, etc.).

### 1. Ajouter des Outputs à `main.tf`
Modifiez le fichier `main.tf` :
```bash
nano main.tf
```

Ajoutez le contenu suivant à la fin du fichier :
```hcl
# =============================================
# Outputs : Afficher des informations sur les ressources créées
# =============================================

# ID de l'instance EC2
output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.p5_exercise_4.id
}

# IP publique de l'instance EC2
output "instance_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.p5_exercise_4.public_ip
}

# URL pour se connecter à l'instance via SSH
output "instance_ssh_url" {
  description = "URL SSH pour se connecter à l'instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.p5_exercise_4.public_ip}"
}

# ID du VPC
output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.p5_vpc.id
}

# ID du subnet public
output "public_subnet_id" {
  description = "ID du subnet public"
  value       = aws_subnet.p5_public_subnet.id
}

# =============================================
# Explications :
# - output : Mot-clé pour définir un output.
# - description : Description de l'output (affichée dans la sortie).
# - value : Valeur à afficher (peut être une expression Terraform).
# - Les outputs sont affichés après un `terraform apply`.
# =============================================
```

### 2. Appliquer les Changements
```bash
terraform apply
```

> **✅ Résultat attendu** : Après confirmation, Terraform devrait afficher les **outputs** :
> ```
> Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
> 
> Outputs:
> 
> instance_id = "i-1234567890abcdef0"
> instance_public_ip = "51.20.123.45"
> instance_ssh_url = "ssh -i ~/.ssh/votre-cle-ssh.pem ubuntu@51.20.123.45"
> public_subnet_id = "subnet-1234567890abcdef0"
> vpc_id = "vpc-1234567890abcdef0"
> ```

### 3. Afficher les Outputs à Tout Moment
```bash
# Afficher les outputs sans appliquer de changements
terraform output
```

> **✅ Résultat attendu** : Vous devriez voir la liste des outputs et leurs valeurs.

---

## 📝 Étape 7 : Détruire l'Infrastructure

Il est **très important** de **détruire l'infrastructure** après avoir terminé l'exercice pour éviter des **frais inutiles**.

### 1. Vérifier les Ressources à Détruire
```bash
# Voir le plan de destruction
terraform plan -destroy
```

> **✅ Résultat attendu** : Vous devriez voir un résumé des ressources à **supprimer** :
> ```
> Plan: 0 to add, 0 to change, 7 to destroy.
> ```

### 2. Détruire l'Infrastructure
```bash
# Détruire toutes les ressources
terraform destroy
```

> **⚠️ Attention** : Terraform va **supprimer toutes les ressources** créées. Confirmez avec `yes`.

> **✅ Résultat attendu** : Après confirmation, Terraform devrait supprimer toutes les ressources :
> ```
> aws_instance.p5_exercise_4: Destroying... [id=i-1234567890abcdef0]
> aws_route_table_association.p5_public_assoc: Destroying... [id=rtassoc-1234567890abcdef0]
> aws_route_table.p5_public_rt: Destroying... [id=rtb-1234567890abcdef0]
> aws_internet_gateway.p5_igw: Destroying... [id=igw-1234567890abcdef0]
> aws_subnet.p5_public_subnet: Destroying... [id=subnet-1234567890abcdef0]
> aws_security_group.p5_sg: Destroying... [id=sg-1234567890abcdef0]
> aws_vpc.p5_vpc: Destroying... [id=vpc-1234567890abcdef0]
> 
> Destroy complete! Resources: 7 destroyed.
> ```

### 3. Vérifier sur AWS
1. Allez sur la [Console EC2](https://console.aws.amazon.com/ec2/v2/home).
2. Vérifiez que **aucune instance** n'est en cours d'exécution.
3. Allez sur la [Console VPC](https://console.aws.amazon.com/vpc/home) et vérifiez que **toutes les ressources** ont été supprimées.

---

## ✅ Vérification

Pour vérifier que vous avez **bien compris** cet exercice, répondez aux questions suivantes :

### 1. Qu'est-ce que Terraform ?
<details>
<summary>💡 Réponse</summary>
Terraform est un outil d'**Infrastructure as Code (IaC)** qui permet de **provisionner** et de **gérer** une infrastructure cloud de manière **déclarative**. Avec Terraform, vous définissez l'**état souhaité** de votre infrastructure, et l'outil se charge de l'atteindre.
</details>

### 2. Qu'est-ce qu'un provider Terraform ?
<details>
<summary>💡 Réponse</summary>
Un **provider** est un plugin Terraform qui permet d'**interagir avec une plateforme cloud** (AWS, Azure, GCP, etc.). Chaque provider expose des **ressources** (ex: `aws_instance`, `aws_vpc`) et des **data sources** pour récupérer des informations.
</details>

### 3. Qu'est-ce qu'une ressource Terraform ?
<details>
<summary>💡 Réponse</summary>
Une **ressource** est une **unité d'infrastructure** (ex: instance EC2, bucket S3, VPC, etc.) définie dans un fichier `.tf`. Chaque ressource a un **type** (ex: `aws_instance`) et un **nom** (ex: `p5_exercise_4`).
</details>

### 4. À quoi sert `terraform init` ?
<details>
<summary>💡 Réponse</summary>
`terraform init` permet d'**initialiser** Terraform :
- Télécharger les **providers** spécifiés.
- Initialiser le **backend** (pour stocker l'état Terraform).
- Créer un fichier `.terraform.lock.hcl` pour verrouiller les versions des providers.
</details>

### 5. À quoi sert `terraform plan` ?
<details>
<summary>💡 Réponse</summary>
`terraform plan` permet de **voir le plan d'exécution** :
- Affiche les **changements** que Terraform va appliquer.
- Ne **modifie pas** l'infrastructure (c'est une simulation).
- Montre les ressources à **créer** (`+`), **modifier** (`~`), ou **supprimer** (`-`).
</details>

### 6. À quoi sert `terraform apply` ?
<details>
<summary>💡 Réponse</summary>
`terraform apply` permet d'**appliquer les changements** :
- Crée les ressources définies dans les fichiers `.tf`.
- Affiche un **résumé** des changements avant de les appliquer.
- Demande une **confirmation** (`yes` pour valider).
</details>

### 7. À quoi sert `terraform destroy` ?
<details>
<summary>💡 Réponse</summary>
`terraform destroy` permet de **supprimer toutes les ressources** créées par Terraform. C'est utile pour **nettoyer** l'infrastructure et éviter des frais inutiles.
</details>

### 8. Qu'est-ce que le fichier `terraform.tfstate` ?
<details>
<summary>💡 Réponse</summary>
Le fichier `terraform.tfstate` est un **fichier JSON** qui stocke l'**état actuel** de votre infrastructure. Il permet à Terraform de **savoir quelles ressources existent** et de **détecter les changements**.

> **⚠️ Important** :
> - **Ne jamais modifier manuellement** ce fichier.
> - **Ne jamais le supprimer** (sauf si vous savez ce que vous faites).
> - En production, stockez-le dans un **backend distant** (S3, Azure Blob Storage, etc.).
</details>

### 9. À quoi servent les variables dans Terraform ?
<details>
<summary>💡 Réponse</summary>
Les **variables** permettent de **paramétrer** votre infrastructure et de la rendre plus **flexible**. Elles peuvent être définies dans :
- Un fichier `variables.tf` (déclaration).
- Un fichier `terraform.tfvars` (valeurs).
- La ligne de commande (`-var "variable=valeur"`).
- Des variables d'environnement (`TF_VAR_variable`).
</details>

### 10. À quoi servent les outputs dans Terraform ?
<details>
<summary>💡 Réponse</summary>
Les **outputs** permettent d'**afficher des informations** sur les ressources créées (ex: IP publique, ID, URL, etc.). Ils sont utiles pour :
- **Récupérer des informations** après un `terraform apply`.
- **Passer des valeurs** à d'autres outils ou scripts.
- **Documenter** les ressources créées.
</details>

---

## 🔍 Résolution des Problèmes

Voici les **problèmes courants** et leurs solutions :

| **Problème** | **Cause Possible** | **Solution** |
|--------------|-------------------|--------------|
| `Error: No valid credential sources found` | Les clés AWS ne sont pas configurées. | Configurez AWS CLI avec `aws configure` ou utilisez des variables d'environnement. |
| `Error: Invalid AMI ID` | L'AMI spécifiée n'existe pas dans la région. | Vérifiez l'AMI pour votre région (ex: `ami-0c55b159cbfafe1f0` pour Ubuntu 22.04 en eu-west-3). |
| `Error: Invalid key pair name` | La clé SSH n'existe pas. | Créez une clé SSH dans la [Console EC2](https://console.aws.amazon.com/ec2/v2/home#KeyPairs:). |
| `Error: Instance limit exceeded` | Vous avez atteint la limite d'instances (Free Tier). | Supprimez les instances inutilisées ou demandez une augmentation de limite. |
| `Error: Insufficient permissions` | Les permissions IAM sont insuffisantes. | Vérifiez que votre utilisateur IAM a les permissions `EC2FullAccess` et `VPCFullAccess`. |
| `Error: Resource already exists` | La ressource existe déjà. | Supprimez la ressource manuellement ou utilisez `terraform import`. |
| `Error: Failed to query available provider packages` | Problème de réseau ou de cache. | Exécutez `terraform init -upgrade` pour forcer le téléchargement des providers. |
| `Error: Configuration language expressions may not be used here` | Erreur de syntaxe dans un fichier `.tf`. | Vérifiez la syntaxe avec `terraform validate`. |

---

## 📚 Pour Aller Plus Loin

### Ressources Officielles
- [Documentation Terraform](https://developer.hashicorp.com/terraform)
- [Registry de Modules Terraform](https://registry.terraform.io/)
- [Provider AWS](https://registry.terraform.io/providers/hashicorp/aws/latest)

### Tutoriels
- [Terraform Get Started](https://learn.hashicorp.com/terraform)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Livres
- [Terraform: Up & Running](https://www.oreilly.com/library/view/terraform-up/9781492046899/) (Yevgeniy Brikman)
- [Terraform in Action](https://www.manning.com/books/terraform-in-action) (Scott Winkler)

### Prochains Exercices
- **[Exercice 3 : Configuration avec Ansible](../exercise-3/README.md)** : Si vous ne l'avez pas encore fait.
- **[Exercice 5 : Orchestration avec Kubernetes](../exercise-5/README.md)** : Déployez une application sur un cluster Kubernetes.

---

## 🎉 Félicitations !

Vous avez **terminé l'Exercice 4** ! 🎉
Vous savez maintenant :
✅ **Installer** Terraform sur votre machine.
✅ **Configurer** un provider (AWS).
✅ **Créer** des ressources cloud (VPC, subnet, instance EC2, etc.).
✅ **Utiliser** des variables et des outputs.
✅ **Gérer** l'état Terraform (`terraform.tfstate`).
✅ **Détruire** une infrastructure de manière propre.

**Passez à l'[Exercice 5](../exercise-5/README.md) pour apprendre à orchestrer des conteneurs avec Kubernetes !** 🚀
