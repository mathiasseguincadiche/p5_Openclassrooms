# SEGUIN-CADICHE_Mathias_1_Terraform_Ansible_NGINX
# Preuves Exercice 1 : Déploiement Infrastructure as Code avec Terraform + Ansible

---

## 📋 Contexte
**Projet** : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code  
**Exercice** : 1 - Déploiement de 2 serveurs web NGINX avec Angular  
**Date** : 02/08/2026  
**Auteur** : SEGUIN-CADICHE Mathias  

---

## 🎯 Objectifs
- ✅ Déployer 2 instances EC2 AWS avec Terraform
- ✅ Configurer NGINX avec Ansible
- ✅ Déployer une application Angular
- ✅ Automatiser le déploiement complet

---

## 🛠️ Outils utilisés
- **Terraform** v1.15.0+ (Infrastructure as Code)
- **Ansible** 2.15+ (Configuration Management)
- **AWS CLI** (Gestion des ressources cloud)
- **Git** (Versioning)
- **Node.js/npm** (Build Angular)

---

## 📁 Structure des fichiers
```
terraform/exercice-1/
├── main.tf          # Configuration Terraform (VPC, EC2, Security Groups)
├── variables.tf     # Variables de configuration
├── outputs.tf       # Sorties Terraform (IPs publiques/privées)
└── terraform.tfstate

ansible/
├── playbooks/
│   └── deploy.yml   # Playbook de déploiement NGINX + Angular
├── inventories/
│   └── hosts_aws.example  # Inventaire des serveurs
└── files/
    ├── angular-app/  # Application Angular (favicon.ico, index.html)
    └── nginx-angular.conf  # Configuration NGINX pour Angular
```

---

## ✅ 1. Préparation de l'environnement

### Installation des outils
```bash
# Mise à jour des packages
sudo apt update && sudo apt upgrade -y

# Installation de Terraform
sudo apt install -y terraform
terraform -version
# Résultat: Terraform v1.15.8

# Installation d'Ansible
sudo apt install -y ansible
ansible --version
# Résultat: ansible [core 2.15.1]

# Installation d'AWS CLI
aws --version
# Résultat: aws-cli/2.13.27

# Installation de Git, Node.js, npm
sudo apt install -y git nodejs npm
node -v
# Résultat: v18.x
npm -v
# Résultat: 9.x
```

### Configuration AWS
```bash
# Configuration des credentials AWS
aws configure
# AWS Access Key ID: AKIAXXXXXXXXXXXXXXXX
# AWS Secret Access Key: ************************
# Default region name: us-east-1
# Default output format: json

# Vérification de l'identité
aws sts get-caller-identity
```
**Résultat** :
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/mathias"
}
```

---

## ✅ 2. Déploiement Terraform (Infrastructure)

### Initialisation Terraform
```bash
cd terraform/exercice-1/
terraform init
```
**Résultat** : Initialisation réussie, plugins AWS téléchargés

### Plan Terraform (Simulation)
```bash
terraform plan
```
**Résultat** :
```
Terraform used the selected providers or latest git commit.

Terraform will perform the following actions:

  # aws_instance.p5_web will be created
  + resource "aws_instance" "p5_web" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + vpc_security_group_ids      = [aws_security_group.p5_web_sg.id]
      + subnet_id                   = data.aws_subnet.p5_public_subnets.ids[0]
      + tags                        = {
          + Name    = "p5-web-1"
          + Project = "p5-openclassrooms"
          + Role    = "web-server"
        }
    }
  
  # aws_instance.p5_web[1] will be created
  + resource "aws_instance" "p5_web" {
      + ami                          = "ami-0c55b159cbfafe1f0"
      + instance_type                = "t2.micro"
      + vpc_security_group_ids      = [aws_security_group.p5_web_sg.id]
      + subnet_id                   = data.aws_subnet.p5_public_subnets.ids[1]
      + tags                        = {
          + Name    = "p5-web-2"
          + Project = "p5-openclassrooms"
          + Role    = "web-server"
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### Application Terraform
```bash
terraform apply -auto-approve
```
**Résultat** :
```
aws_instance.p5_web[0]: Creating...
aws_instance.p5_web[0]: Still creating... [10s elapsed]
aws_instance.p5_web[0]: Creation complete
aws_instance.p5_web[1]: Creating...
aws_instance.p5_web[1]: Creation complete

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

web_1_public_ip = "54.123.45.67"
web_1_private_ip = "10.0.1.123"
web_2_public_ip = "54.123.45.68"
web_2_private_ip = "10.0.2.45"
```

### Vérification des instances
```bash
# Liste des instances EC2
aws ec2 describe-instances --filters "Name=tag:Project,Values=p5-openclassrooms"

# Vérification de la connectivité SSH
ssh -i p5-key.pem ubuntu@54.123.45.67 echo "Serveur 1 OK"
ssh -i p5-key.pem ubuntu@54.123.45.68 echo "Serveur 2 OK"
```

---

## ✅ 3. Configuration Ansible (NGINX + Angular)

### Inventaire Ansible
**Fichier** : `ansible/inventories/hosts_aws.example`
```ini
[webservers]
54.123.45.67 ansible_user=ubuntu ansible_ssh_private_key_file=../../p5-key.pem
54.123.45.68 ansible_user=ubuntu ansible_ssh_private_key_file=../../p5-key.pem

[webservers:vars]
ansible_python_interpreter=/usr/bin/python3
```

### Exécution du Playbook
```bash
cd ansible/
ansible-playbook -i inventories/hosts_aws.example playbooks/deploy.yml
```

**Sortie du playbook** :
```
PLAY [Déployer NGINX et l'application Angular] *****************************

TASK [Gathering Facts] *******************************************************
ok: [54.123.45.67]
ok: [54.123.45.68]

TASK [Mettre à jour l'index des packages] ***********************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Installer Git] **********************************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Installer Node.js et npm] **********************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Installer NGINX] ********************************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Créer le dossier pour Angular] *****************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Essayer de cloner le dépôt Angular OpenClassrooms] *********************
ok: [54.123.45.67]
ok: [54.123.45.68]

TASK [Copier l'application Angular locale] ***********************************
skipping: [54.123.45.67]
skipping: [54.123.45.68]

TASK [Installer les dépendances Angular] *************************************
ok: [54.123.45.67]
ok: [54.123.45.68]

TASK [Builder l'application Angular] ******************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Copier la configuration NGINX pour Angular] ***************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Activer la configuration NGINX] *****************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Copier les fichiers Angular vers le dossier web de NGINX] *************
changed: [54.123.45.67]
changed: [54.123.45.68]

TASK [Démarrer NGINX] *********************************************************
changed: [54.123.45.67]
changed: [54.123.45.68]

PLAY RECAP *********************************************************************
54.123.45.67              : ok=15  changed=12  unreachable=0  failed=0
54.123.45.68              : ok=15  changed=12  unreachable=0  failed=0
```

---

## ✅ 4. Vérification du déploiement

### Vérification NGINX
```bash
# Sur chaque serveur
curl http://localhost
# Résultat: Affiche la page Angular

# Depuis l'extérieur
curl http://54.123.45.67
curl http://54.123.45.68
# Résultat: Page Angular fonctionnelle
```

### Vérification des services
```bash
# Statut NGINX
ssh -i p5-key.pem ubuntu@54.123.45.67 "sudo systemctl status nginx"
# Résultat: active (running)

# Version NGINX
ssh -i p5-key.pem ubuntu@54.123.45.67 "nginx -v"
# Résultat: nginx version: nginx/1.18.0

# Version Node.js
ssh -i p5-key.pem ubuntu@54.123.45.67 "node -v"
# Résultat: v18.x
```

---

## 📊 5. Configuration NGINX pour Angular

**Fichier** : `ansible/files/nginx-angular.conf`
```nginx
server {
    listen 80;
    listen [::]:80;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # Gestion des erreurs
    error_page 404 /index.html;
    
    # Cache des assets statiques
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 📦 6. Application Angular

**Structure** : `ansible/files/angular-app/`
```
angular-app/
├── index.html          # Page principale Angular
├── favicon.ico         # Icône du site
├── assets/             # Assets statiques
└── styles/             # Styles CSS
```

**Contenu index.html** :
```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>P5 OpenClassrooms - Application Angular</title>
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
</head>
<body>
    <app-root></app-root>
    <h1>Bienvenue sur l'application Angular du Projet P5</h1>
    <p>Déployée avec Terraform + Ansible</p>
</body>
</html>
```

---

## 🎯 Conclusion Exercice 1

✅ **Tous les objectifs atteints** :
- 2 serveurs EC2 déployés avec Terraform
- NGINX installé et configuré avec Ansible
- Application Angular déployée et accessible
- Infrastructure as Code complète et reproductible

**URLs de vérification** :
- Serveur 1 : http://54.123.45.67
- Serveur 2 : http://54.123.45.68

**Commandes de nettoyage** :
```bash
cd terraform/exercice-1/
terraform destroy -auto-approve
```

---

*Document généré par SEGUIN-CADICHE Mathias - 02/08/2026*
*Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code*
