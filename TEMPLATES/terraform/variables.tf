# =============================================
# TEMPLATE : Variables Terraform pour AWS
# =============================================
# Ce fichier permet de définir les variables utilisées dans votre infrastructure Terraform.
# Chaque variable est documentée avec une description, un type, et une valeur par défaut.
#
# Pour utiliser ce template :
# 1. Copiez ce fichier dans votre projet sous le nom "variables.tf".
# 2. Personnalisez les variables selon vos besoins.
# 3. Créez un fichier terraform.tfvars pour surcharger les valeurs.

# =============================================
# VARIABLES GLOBALES
# =============================================

# Nom du projet (utilisé pour taguer les ressources)
variable "project_name" {
  description = "Nom du projet (utilisé pour taguer les ressources AWS)"
  type        = string
  default     = "p5-openclassrooms"
}

# Région AWS à utiliser
variable "aws_region" {
  description = "Région AWS à utiliser (ex: eu-west-3 pour Paris)"
  type        = string
  default     = "eu-west-3"
}

# =============================================
# VARIABLES POUR LE PROVIDER AWS (OPTIONNEL)
# =============================================
# ⚠️ ATTENTION : Ne stockez jamais de clés AWS dans le code !
# Utilisez plutôt AWS CLI ou des variables d'environnement.
# Ces variables sont commentées par défaut pour des raisons de sécurité.

# variable "aws_access_key" {
#   description = "Clé d'accès AWS"
#   type        = string
#   sensitive   = true  # Masque la valeur dans les logs
# }

# variable "aws_secret_key" {
#   description = "Clé secrète AWS"
#   type        = string
#   sensitive   = true  # Masque la valeur dans les logs
# }

# =============================================
# VARIABLES POUR LE VPC
# =============================================

# Plage d'adresses IP pour le VPC (CIDR)
variable "vpc_cidr" {
  description = "Plage d'adresses IP pour le VPC (ex: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

# Plage d'adresses IP pour le subnet public (CIDR)
variable "public_subnet_cidr" {
  description = "Plage d'adresses IP pour le subnet public (ex: 10.0.1.0/24)"
  type        = string
  default     = "10.0.1.0/24"
}

# Plage d'adresses IP pour le subnet privé (CIDR)
variable "private_subnet_cidr" {
  description = "Plage d'adresses IP pour le subnet privé (ex: 10.0.2.0/24)"
  type        = string
  default     = "10.0.2.0/24"
}

# =============================================
# VARIABLES POUR LES INSTANCES EC2
# =============================================

# AMI (Amazon Machine Image) à utiliser pour les instances
# Exemples :
# - Ubuntu 22.04 LTS (eu-west-3) : ami-0c55b159cbfafe1f0
# - Amazon Linux 2 (eu-west-3) : ami-08ca3fed11864d6bb550
# - CentOS 7 (eu-west-3) : ami-04e6017b5838a3683
variable "ami_id" {
  description = "AMI à utiliser pour les instances EC2"
  type        = string
}

# Type d'instance EC2
# Exemples :
# - t2.micro (Free Tier)
# - t2.small
# - t3.medium
# - m5.large
variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

# Nom de la clé SSH pour se connecter aux instances
variable "key_name" {
  description = "Nom de la clé SSH pour se connecter aux instances EC2"
  type        = string
}

# =============================================
# VARIABLES POUR LA SÉCURITÉ
# =============================================

# Plages d'adresses IP autorisées pour SSH (CIDR)
variable "ssh_cidr_blocks" {
  description = "Plages d'adresses IP autorisées pour SSH (ex: [\"203.0.113.10/32\"])"
  type        = list(string)
}

# Plages d'adresses IP autorisées pour HTTP/HTTPS (CIDR)
variable "web_cidr_blocks" {
  description = "Plages d'adresses IP autorisées pour HTTP/HTTPS (ex: [\"0.0.0.0/0\"])"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =============================================
# VARIABLES POUR LES BASES DE DONNÉES (OPTIONNEL)
# =============================================

# Type de base de données (ex: postgres, mysql, mariadb)
variable "db_engine" {
  description = "Type de base de données (ex: postgres, mysql)"
  type        = string
  default     = "postgres"
}

# Version de la base de données
variable "db_engine_version" {
  description = "Version de la base de données"
  type        = string
  default     = "13.4"
}

# Nom de la base de données
variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "mydb"
}

# Nom d'utilisateur de la base de données
variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "admin"
}

# Mot de passe de la base de données (sensible)
variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

# =============================================
# EXPLICATIONS :
# =============================================
# 1. variable : Mot-clé pour définir une variable.
#    - description : Description de la variable (affichée dans l'aide).
#    - type : Type de la variable (string, number, bool, list, map, etc.).
#    - default : Valeur par défaut (optionnelle).
#    - sensitive : Masque la valeur dans les logs (pour les secrets).
#
# 2. Types de variables :
#    - string : Chaîne de caractères.
#    - number : Nombre.
#    - bool : Booléen (true/false).
#    - list(type) : Liste de valeurs d'un type donné.
#    - map(type) : Dictionnaire (clé: valeur).
#    - any : N'importe quel type.
#
# 3. Valeurs par défaut :
#    - Les valeurs par défaut sont utilisées si la variable n'est pas définie.
#    - Vous pouvez surcharger les valeurs dans un fichier terraform.tfvars.
#
# 4. Variables sensibles :
#    - Utilisez sensitive = true pour masquer les valeurs dans les logs.
#    - Exemple : mots de passe, clés API, tokens.
# =============================================

# =============================================
# UTILISATION :
# =============================================
# 1. Copiez ce fichier dans votre projet sous le nom "variables.tf".
# 2. Personnalisez les variables selon vos besoins.
# 3. Créez un fichier terraform.tfvars pour surcharger les valeurs :
#    project_name = "mon-projet"
#    aws_region = "us-east-1"
#    ami_id = "ami-12345678"
#    instance_type = "t2.small"
#    key_name = "ma-cle-ssh"
# 4. Utilisez les variables dans vos fichiers .tf :
#    resource "aws_instance" "app" {
#      ami           = var.ami_id
#      instance_type = var.instance_type
#    }
# =============================================

# =============================================
# BONNES PRATIQUES :
# =============================================
# 1. Utilisez des noms de variables clairs et descriptifs.
# 2. Ajoutez toujours une description pour chaque variable.
# 3. Spécifiez toujours un type pour chaque variable.
# 4. Utilisez des valeurs par défaut pour les variables optionnelles.
# 5. Utilisez sensitive = true pour les variables sensibles.
# 6. Ne stockez jamais de secrets dans le code (même dans des variables).
# 7. Utilisez des fichiers .tfvars pour surcharger les valeurs.
# 8. Documentez vos variables avec des commentaires.
# =============================================
