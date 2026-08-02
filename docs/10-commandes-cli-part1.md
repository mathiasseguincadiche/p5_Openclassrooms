# 💻 Récapitulatif des Commandes CLI Essentielles - Partie 1

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📌 **Instructions**

Ce document contient **toutes les commandes CLI essentielles** pour réaliser ce projet. Il est divisé en plusieurs parties pour faciliter la lecture.

**Partie 1** : Commandes Générales, Terraform, Ansible, AWS CLI

---

## 📋 **Table des Matières**

1. [Commandes Générales](#-commandes-générales)
2. [Terraform](#-terraform)
3. [Ansible](#-ansible)
4. [AWS CLI](#-aws-cli)

---

## 🌐 **Commandes Générales**

### **Navigation et Gestion de Fichiers**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `pwd` | Affiche le répertoire courant | `pwd` |
| `ls` | Liste les fichiers | `ls -la` |
| `ls -la` | Liste détaillée avec fichiers cachés | `ls -la` |
| `cd` | Change de répertoire | `cd terraform/exercice-1` |
| `cd ..` | Remonte d'un niveau | `cd ..` |
| `cd ~` | Va dans le répertoire home | `cd ~` |
| `mkdir` | Crée un répertoire | `mkdir -p terraform/exercice-1` |
| `rm` | Supprime un fichier | `rm fichier.txt` |
| `rm -rf` | Supprime un répertoire récursivement | `rm -rf dossier/` |
| `cp` | Copie un fichier | `cp fichier.txt backup/` |
| `cp -r` | Copie un répertoire récursivement | `cp -r dossier/ backup/` |
| `mv` | Déplace/renomme un fichier | `mv ancien.txt nouveau.txt` |

### **Visualisation de Fichiers**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `cat` | Affiche le contenu | `cat fichier.txt` |
| `less` | Affiche page par page | `less fichier.txt` |
| `head` | Affiche les premières lignes | `head -n 20 fichier.txt` |
| `tail` | Affiche les dernières lignes | `tail -n 20 fichier.txt` |
| `tail -f` | Suit les modifications en temps réel | `tail -f /var/log/nginx/access.log` |

### **Recherche et Filtrage**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `grep` | Recherche un motif | `grep "error" /var/log/nginx/error.log` |
| `grep -r` | Recherche récursive | `grep -r "pattern" /dossier/` |
| `grep -i` | Recherche insensible à la casse | `grep -i "error" fichier.txt` |
| `find` | Recherche des fichiers | `find . -name "*.tf"` |
| `find -type f` | Recherche uniquement les fichiers | `find . -type f -name "*.conf"` |
| `wc` | Compte lignes/mots/caractères | `wc -l fichier.txt` |
| `sort` | Trie les lignes | `sort fichier.txt` |
| `uniq` | Affiche les lignes uniques | `sort fichier.txt \| uniq` |

### **Système**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `echo` | Affiche un texte | `echo "Hello World"` |
| `date` | Affiche la date/heure | `date` |
| `whoami` | Affiche l'utilisateur courant | `whoami` |
| `hostname` | Affiche le nom de la machine | `hostname` |
| `uname -a` | Affiche les infos système | `uname -a` |
| `uptime` | Affiche le temps de fonctionnement | `uptime` |
| `w` | Affiche les utilisateurs connectés | `w` |
| `history` | Affiche l'historique des commandes | `history` |
| `!!` | Exécute la dernière commande | `!!` |
| `!n` | Exécute la commande n°n | `!123` |

---

## ⛏️ **Terraform**

### **Commandes de Base**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `terraform init` | Initialise Terraform et télécharge les providers | `-backend-config`, `-reconfigure` | `terraform init` |
| `terraform plan` | Affiche les changements à appliquer | `-out`, `-var`, `-target` | `terraform plan` |
| `terraform apply` | Applique les changements | `-auto-approve`, `-var`, `-target` | `terraform apply` |
| `terraform destroy` | Supprime toutes les ressources | `-auto-approve`, `-var`, `-target` | `terraform destroy -auto-approve` |
| `terraform output` | Affiche les outputs | `-json`, `-raw` | `terraform output nginx_1_public_ip` |
| `terraform state list` | Liste toutes les ressources gérées | - | `terraform state list` |
| `terraform state show` | Affiche les détails d'une ressource | - | `terraform state show aws_instance.nginx_1` |
| `terraform validate` | Valide la syntaxe des fichiers | - | `terraform validate` |
| `terraform fmt` | Formate les fichiers Terraform | `-check`, `-diff`, `-write` | `terraform fmt` |

### **Options Courantes**

| Option | Description | Exemple |
|--------|-------------|---------|
| `-var 'name=value'` | Définit une variable | `terraform apply -var 'instance_type=t2.micro'` |
| `-var-file=filename` | Charge les variables depuis un fichier | `terraform apply -var-file=prod.tfvars` |
| `-target=resource` | Cible une ressource spécifique | `terraform apply -target=aws_instance.nginx_1` |
| `-auto-approve` | Approuve automatiquement | `terraform apply -auto-approve` |

### **Exemples Complets**

```bash
# Initialiser Terraform
terraform init

# Voir le plan des changements
terraform plan

# Appliquer les changements (avec confirmation)
terraform apply

# Appliquer les changements (sans confirmation)
terraform apply -auto-approve

# Appliquer avec des variables
terraform apply -var 'instance_type=t2.micro' -var 'aws_region=eu-west-3'

# Appliquer avec un fichier de variables
terraform apply -var-file=terraform.tfvars

# Supprimer toutes les ressources
terraform destroy -auto-approve

# Cibler une ressource spécifique
terraform apply -target=aws_instance.nginx_1

# Afficher une output spécifique
terraform output nginx_1_public_ip

# Lister toutes les ressources
terraform state list

# Valider la syntaxe
terraform validate

# Formater les fichiers
terraform fmt
```

---

## 🎭 **Ansible**

### **Commandes de Base**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `ansible` | Exécute des commandes ad-hoc | `-i`, `-m`, `-a`, `-u`, `--become` | `ansible all -m ping` |
| `ansible-playbook` | Exécute un playbook | `-i`, `-l`, `-v`, `--check`, `--diff` | `ansible-playbook playbook.yml` |
| `ansible-inventory` | Gère les inventaires | `--list`, `--graph` | `ansible-inventory -i inventory.ini --list` |
| `ansible-doc` | Affiche la documentation des modules | `-l`, `-s` | `ansible-doc -l` |
| `ansible-galaxy` | Gère les rôles et collections | `init`, `install`, `list` | `ansible-galaxy init role_name` |

### **Options Courantes**

| Option | Description | Exemple |
|--------|-------------|---------|
| `-i inventory` | Spécifie l'inventaire | `ansible -i inventory.ini all -m ping` |
| `-l subset` | Limite aux hôtes d'un sous-groupe | `ansible-playbook -i inventory.ini -l webservers playbook.yml` |
| `-v, -vv, -vvv` | Mode verbose | `ansible-playbook -i inventory.ini playbook.yml -v` |
| `--check` | Mode dry-run | `ansible-playbook -i inventory.ini playbook.yml --check` |
| `--diff` | Affiche les différences | `ansible-playbook -i inventory.ini playbook.yml --diff` |
| `--become` | Exécute avec sudo | `ansible all -m ping --become` |
| `-u user` | Spécifie l'utilisateur | `ansible all -m ping -u ec2-user` |
| `--private-key` | Spécifie la clé SSH | `ansible all -m ping --private-key=~/.ssh/p5-key` |
| `-m module` | Spécifie le module | `ansible all -m setup` |
| `-a args` | Arguments du module | `ansible all -m command -a "uptime"` |

### **Modules Courants**

| Module | Description | Exemple |
|--------|-------------|---------|
| `ping` | Test de connectivité | `ansible all -m ping` |
| `setup` | Récupère les facts | `ansible all -m setup` |
| `command` | Exécute une commande | `ansible all -m command -a "date"` |
| `shell` | Exécute une commande dans un shell | `ansible all -m shell -a "echo $HOME"` |
| `yum` | Gère les packages avec Yum | `ansible all -m yum -a "name=nginx state=present"` |
| `apt` | Gère les packages avec Apt | `ansible all -m apt -a "name=nginx state=present"` |
| `copy` | Copie un fichier | `ansible all -m copy -a "src=file dest=/tmp/file"` |
| `template` | Génère un fichier à partir d'un template | `ansible all -m template -a "src=file.j2 dest=/etc/file"` |
| `file` | Gère les fichiers et répertoires | `ansible all -m file -a "path=/tmp dir=yes"` |
| `service` | Gère les services | `ansible all -m service -a "name=nginx state=started"` |

### **Exemples Complets**

```bash
# Tester la connectivité à tous les hôtes
ansible -i inventories/exercice-1.ini all -m ping

# Exécuter un playbook
ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml

# Exécuter un playbook en mode verbose
ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml -v

# Exécuter un playbook en mode dry-run
ansible-playbook -i inventories/exercice-1.ini playbooks/deploy-nginx.yml --check

# Exécuter une commande sur tous les hôtes
ansible -i inventories/exercice-1.ini all -a "uptime"

# Exécuter une commande avec sudo
ansible -i inventories/exercice-1.ini all -a "apt update" --become

# Récupérer les facts d'un hôte
ansible -i inventories/exercice-1.ini nginx-1 -m setup

# Lister les hôtes d'un inventaire
ansible-inventory -i inventories/exercice-1.ini --list

# Créer un nouveau rôle Ansible
ansible-galaxy init roles/nginx

# Installer un rôle depuis Galaxy
ansible-galaxy install geerlingguy.nginx
```

---

## 🌐 **AWS CLI**

### **Configuration**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `aws configure` | Configure les credentials AWS | `aws configure` |
| `aws sts get-caller-identity` | Affiche l'identité actuelle | `aws sts get-caller-identity` |
| `aws configure list` | Affiche la configuration actuelle | `aws configure list` |
| `aws configure set region eu-west-3` | Définit la région | `aws configure set region eu-west-3` |

### **EC2**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `aws ec2 describe-instances` | Liste les instances EC2 | `--instance-ids`, `--filters`, `--query` | `aws ec2 describe-instances` |
| `aws ec2 run-instances` | Lance une nouvelle instance | `--image-id`, `--instance-type`, `--key-name` | `aws ec2 run-instances --image-id ami-12345 --instance-type t2.micro` |
| `aws ec2 terminate-instances` | Termine une instance | `--instance-ids` | `aws ec2 terminate-instances --instance-ids i-1234567890abcdef0` |
| `aws ec2 stop-instances` | Arrête une instance | `--instance-ids` | `aws ec2 stop-instances --instance-ids i-1234567890abcdef0` |
| `aws ec2 start-instances` | Démarre une instance | `--instance-ids` | `aws ec2 start-instances --instance-ids i-1234567890abcdef0` |
| `aws ec2 describe-images` | Liste les AMIs | `--owners`, `--filters` | `aws ec2 describe-images --owners amazon` |
| `aws ec2 describe-key-pairs` | Liste les paires de clés SSH | - | `aws ec2 describe-key-pairs` |
| `aws ec2 create-key-pair` | Crée une paire de clés SSH | `--key-name`, `--query`, `--output` | `aws ec2 create-key-pair --key-name p5-key --query 'KeyMaterial' --output text > ~/.ssh/p5-key.pub` |

### **VPC et Réseau**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `aws ec2 describe-vpcs` | Liste les VPC | `--vpc-ids`, `--filters` | `aws ec2 describe-vpcs` |
| `aws ec2 describe-subnets` | Liste les subnets | `--subnet-ids`, `--filters` | `aws ec2 describe-subnets` |
| `aws ec2 describe-security-groups` | Liste les Security Groups | `--group-ids`, `--filters` | `aws ec2 describe-security-groups` |
| `aws ec2 create-security-group` | Crée un Security Group | `--group-name`, `--description`, `--vpc-id` | `aws ec2 create-security-group --group-name p5-sg --description "SG pour P5" --vpc-id vpc-xxxxx` |
| `aws ec2 authorize-security-group-ingress` | Ajoute une règle entrante | `--group-id`, `--protocol`, `--port`, `--cidr` | `aws ec2 authorize-security-group-ingress --group-id sg-xxxxx --protocol tcp --port 80 --cidr 0.0.0.0/0` |

### **Elastic IP**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `aws ec2 describe-addresses` | Liste les Elastic IP | `--allocation-ids`, `--filters` | `aws ec2 describe-addresses` |
| `aws ec2 allocate-address` | Alloue une Elastic IP | `--domain` | `aws ec2 allocate-address --domain vpc` |
| `aws ec2 associate-address` | Associe une Elastic IP | `--allocation-id`, `--instance-id` | `aws ec2 associate-address --allocation-id eipalloc-xxxxx --instance-id i-1234567890abcdef0` |

### **Options Courantes**

| Option | Description | Exemple |
|--------|-------------|---------|
| `--region` | Spécifie la région AWS | `aws ec2 describe-instances --region eu-west-3` |
| `--output` | Spécifie le format de sortie | `aws ec2 describe-instances --output json` |
| `--query` | Filtre la sortie avec JMESPath | `aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId'` |
| `--filters` | Filtre les résultats | `aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"` |

### **Exemples Complets**

```bash
# Configurer AWS CLI
aws configure

# Vérifier l'identité actuelle
aws sts get-caller-identity

# Lister toutes les instances EC2
aws ec2 describe-instances

# Lister les instances en cours d'exécution
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Lister les instances avec le tag Project=p5-openclassrooms
aws ec2 describe-instances --filters "Name=tag:Project,Values=p5-openclassrooms"

# Récupérer l'IP publique d'une instance
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Lister les VPC
aws ec2 describe-vpcs

# Lister les Security Groups
aws ec2 describe-security-groups

# Créer une paire de clés SSH
aws ec2 create-key-pair --key-name p5-key --query 'KeyMaterial' --output text > ~/.ssh/p5-key.pub

# Allouer une Elastic IP
aws ec2 allocate-address --domain vpc

# Associer une Elastic IP à une instance
aws ec2 associate-address --allocation-id eipalloc-xxxxx --instance-id i-1234567890abcdef0
```

---

**La suite dans [Partie 2](10-commandes-cli-part2.md) avec SSH, Git, NGINX, OpenSearch, Logstash, Filebeat, HAProxy, Système et Réseau !**

---

## 📌 **Conseils**

1. **Marquez cette page** : Gardez ce document ouvert dans votre navigateur
2. **Recherchez rapidement** : Utilisez `Ctrl+F` pour trouver une commande
3. **Pratiquez** : Essayez les commandes dans un environnement de test
4. **Personnalisez** : Ajoutez vos propres exemples

> *"Un bon développeur connaît ses outils."* — **Proverbe DevOps**
