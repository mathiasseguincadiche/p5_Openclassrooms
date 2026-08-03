# 📁 Templates Terraform

**Bienvenue dans la section des templates Terraform !**
Ici, vous trouverez des **fichiers de configuration prêts à l'emploi** pour Terraform, **commentés et expliqués** pour provisionner votre infrastructure cloud.

---

## 📌 Table des Matières

1. [Fichier `main.tf`](#-fichier-maintf)
2. [Fichier `variables.tf`](#-fichier-variablestf)
3. [Bonnes Pratiques](#-bonnes-pratiques)

---

## 📄 Fichier `main.tf`

**Fichier** : [`main.tf`](main.tf)

**Description** : Template de **fichier principal Terraform** pour provisionner une infrastructure cloud complète sur AWS. Il inclut :
- Configuration du **provider AWS**.
- Création d'un **VPC** (Virtual Private Cloud).
- Création de **subnets** (public et privé).
- Création d'une **Internet Gateway** et d'une **NAT Gateway**.
- Création de **groupes de sécurité**.
- Création d'une **instance EC2**.

**Cas d'Usage** :
- Provisionnement d'une infrastructure cloud pour une application.
- Déploiement de serveurs, bases de données, load balancers, etc.
- Gestion de réseaux et de sécurité.

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/terraform/main.tf ./main.tf

# 2. Copiez le fichier variables.tf
cp TEMPLATES/terraform/variables.tf ./variables.tf

# 3. Configurez vos clés AWS (via AWS CLI ou variables d'environnement)

# 4. Initialisez Terraform
tf init

# 5. Voir le plan d'exécution
tf plan

# 6. Appliquez les changements
tf apply
```

---

## 📄 Fichier `variables.tf`

**Fichier** : [`variables.tf`](variables.tf)

**Description** : Template de **fichier de variables Terraform** pour paramétrer votre infrastructure. Il permet de :
- Définir des **variables** pour personnaliser votre infrastructure.
- Spécifier des **valeurs par défaut**.
- Documenter les **paramètres** de votre infrastructure.

**Cas d'Usage** :
- Personnaliser les ressources créées (ex: région AWS, type d'instance).
- Rendre votre infrastructure **réutilisable** et **modulaire**.
- Faciliter la collaboration avec d'autres développeurs.

**Exemple d'utilisation** :
```bash
# 1. Copiez le template dans votre projet
cp TEMPLATES/terraform/variables.tf ./variables.tf

# 2. Personnalisez les variables (ex: changez la région AWS, le type d'instance)

# 3. Créez un fichier terraform.tfvars pour surcharger les valeurs
cp TEMPLATES/terraform/terraform.tfvars.example ./terraform.tfvars

# 4. Modifiez terraform.tfvars avec vos valeurs
```

---

## 🌟 Bonnes Pratiques

### 1. Modularisez votre Code
- Utilisez des **modules** pour réutiliser du code.
- Un module est un **dossier** contenant des fichiers `.tf` pour une fonctionnalité spécifique.

Exemple de structure :
```bash
modules/
  vpc/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
  ec2/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### 2. Versionnez votre État
- **Ne jamais modifier manuellement** le fichier `terraform.tfstate`.
- Utilisez un **backend distant** pour stocker l'état (ex: S3, Azure Blob Storage).

Exemple :
```hcl
terraform {
  backend "s3" {
    bucket = "mon-bucket-terraform"
    key    = "mon-projet/terraform.tfstate"
    region = "eu-west-3"
  }
}
```

### 3. Utilisez des Variables
- **Ne hardcodez pas** les valeurs dans les fichiers `.tf`.
- Utilisez des **variables** avec des valeurs par défaut.

Exemple :
```hcl
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

resource "aws_instance" "app" {
  instance_type = var.instance_type
}
```

### 4. Verrouillez les Versions des Providers
- Spécifiez les **versions des providers** pour éviter les surprises.

Exemple :
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"  # Version 4.x du provider AWS
    }
  }
}
```

### 5. Utilisez des Outputs
- Utilisez des **outputs** pour afficher des informations sur les ressources créées.

Exemple :
```hcl
output "instance_public_ip" {
  description = "IP publique de l'instance EC2"
  value       = aws_instance.app.public_ip
}
```

### 6. Planifiez les Changements
- **Toujours exécuter `terraform plan`** avant `terraform apply`.
- Utilisez `-out` pour sauvegarder le plan.

Exemple :
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### 7. Détruyez l'Infrastructure Inutilisée
- **Pensez à détruire** l'infrastructure après utilisation pour éviter des frais inutiles.

Exemple :
```bash
terraform destroy
```

### 8. Utilisez des Workspaces
- Utilisez des **workspaces** pour gérer plusieurs environnements (dev, staging, prod).

Exemple :
```bash
# Créer un workspace pour l'environnement de développement
terraform workspace new dev

# Sélectionner le workspace
terraform workspace select dev

# Appliquer les changements
terraform apply
```

### 9. Documentez votre Infrastructure
- Ajoutez des **commentaires** dans vos fichiers `.tf` pour expliquer chaque ressource.
- Utilisez des **descriptions** pour les variables et les outputs.

Exemple :
```hcl
# Créer une instance EC2 pour l'application
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  
  tags = {
    Name = "mon-app"
  }
}
```

---

## 📚 Ressources

- [Documentation Terraform](https://developer.hashicorp.com/terraform)
- [Registry de Modules Terraform](https://registry.terraform.io/)
- [Provider AWS](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

**Bonne utilisation des templates Terraform !** 🚀
