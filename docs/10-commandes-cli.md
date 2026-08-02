# 💻 Récapitulatif des Commandes CLI Essentielles

**Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code**

---

## 📌 Table des Matières

1. [Commandes Générales](#-commandes-générales)
2. [Terraform](#-terraform)
3. [Ansible](#-ansible)
4. [AWS CLI](#-aws-cli)
5. [SSH](#-ssh)
6. [NGINX](#-nginx)
7. [OpenSearch](#-opensearch)
8. [HAProxy](#-haproxy)
9. [Dépannage](#-dépannage)

---

## 🌐 Commandes Générales

| Action | Commande | Exercice |
|--------|----------|----------|
| Initialiser Terraform | `terraform init` | 1, 2, 3 |
| Vérifier le plan Terraform | `terraform plan` | 1, 2, 3 |
| Appliquer Terraform | `terraform apply -auto-approve` | 1, 2, 3 |
| Supprimer Terraform | `terraform destroy -auto-approve` | 1, 2, 3 |
| Tester la connexion Ansible | `ansible all -i hosts_aws -m ping` | 1 |
| Exécuter un playbook Ansible | `ansible-playbook -i hosts_aws deploy.yml` | 1 |
| Lister les instances EC2 | `aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, PublicIpAddress, State.Name]" --output table` | 1, 2, 3 |
| Vérifier OpenSearch | `aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status" --output text` | 2 |
| Tester OpenSearch | `curl -k -X GET "$OPENSEARCH_ENDPOINT" -H "Content-Type: application/json"` | 2 |
| Tester HAProxy | `curl http://$HAPROXY_IP` | 3 |
| Tester le load balancing | `for i in {1..5}; do curl -s http://$HAPROXY_IP | grep -o "Welcome to nginx from [^<]*"; echo "---"; done` | 3 |

---

## ⛏️ Terraform

### Commandes de Base

| Commande | Description | Options Courantes |
|----------|-------------|------------------|
| `terraform init` | Initialise Terraform et télécharge les providers | `-backend-config`, `-reconfigure` |
| `terraform plan` | Affiche les changements à appliquer | `-out`, `-var`, `-target` |
| `terraform apply` | Applique les changements | `-auto-approve`, `-var`, `-target` |
| `terraform destroy` | Supprime toutes les ressources | `-auto-approve`, `-var`, `-target` |
| `terraform output` | Affiche les outputs | `-json`, `-raw` |
| `terraform state list` | Liste toutes les ressources gérées | - |
| `terraform validate` | Valide la syntaxe des fichiers | - |
| `terraform fmt` | Formate les fichiers Terraform | `-check`, `-diff`, `-write` |

### Exemples Complets

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
terraform apply -var 'instance_type=t2.micro' -var 'aws_region=us-east-1'

# Supprimer toutes les ressources
terraform destroy -auto-approve

# Cibler une ressource spécifique
terraform apply -target=aws_instance.nginx_1

# Afficher une output spécifique
terraform output nginx_1_public_ip

# Valider la syntaxe
terraform validate

# Formater les fichiers
terraform fmt
```

---

## 🎭 Ansible

### Commandes de Base

| Commande | Description | Options Courantes |
|----------|-------------|------------------|
| `ansible` | Exécute des commandes ad-hoc | `-i`, `-m`, `-a`, `-u`, `--become` |
| `ansible-playbook` | Exécute un playbook | `-i`, `-l`, `-v`, `--check`, `--diff` |
| `ansible-inventory` | Gère les inventaires | `--list`, `--graph` |

### Options Courantes

| Option | Description | Exemple |
|--------|-------------|---------|
| `-i inventory` | Spécifie l'inventaire | `ansible -i hosts_aws all -m ping` |
| `-l subset` | Limite aux hôtes d'un sous-groupe | `ansible-playbook -i hosts_aws -l webservers playbook.yml` |
| `-v, -vv, -vvv` | Mode verbose | `ansible-playbook -i hosts_aws playbook.yml -v` |
| `--check` | Mode dry-run | `ansible-playbook -i hosts_aws playbook.yml --check` |
| `--diff` | Affiche les différences | `ansible-playbook -i hosts_aws playbook.yml --diff` |
| `--become` | Exécute avec sudo | `ansible all -m ping --become` |
| `-u user` | Spécifie l'utilisateur | `ansible all -m ping -u ubuntu` |
| `--private-key` | Spécifie la clé SSH | `ansible all -m ping --private-key=p5-key.pem` |

### Exemples Complets

```bash
# Tester la connectivité à tous les hôtes
ansible all -i hosts_aws -m ping

# Exécuter un playbook
ansible-playbook -i hosts_aws deploy.yml

# Exécuter un playbook en mode verbose
ansible-playbook -i hosts_aws deploy.yml -v

# Exécuter un playbook en mode dry-run
ansible-playbook -i hosts_aws deploy.yml --check

# Exécuter une commande sur tous les hôtes
ansible all -i hosts_aws -a "uptime"

# Exécuter une commande avec sudo
ansible all -i hosts_aws -a "apt update" --become

# Récupérer les facts d'un hôte
ansible all -i hosts_aws -m setup

# Lister les hôtes d'un inventaire
ansible-inventory -i hosts_aws --list
```

---

## 🌐 AWS CLI

### Configuration

| Commande | Description |
|----------|-------------|
| `aws configure` | Configure les credentials AWS |
| `aws sts get-caller-identity` | Affiche l'identité actuelle |

### EC2

| Commande | Description | Options Courantes |
|----------|-------------|------------------|
| `aws ec2 describe-instances` | Liste les instances EC2 | `--instance-ids`, `--filters`, `--query` |
| `aws ec2 run-instances` | Lance une nouvelle instance | `--image-id`, `--instance-type`, `--key-name` |
| `aws ec2 terminate-instances` | Termine une instance | `--instance-ids` |
| `aws ec2 describe-images` | Liste les AMIs | `--owners`, `--filters` |

### OpenSearch

| Commande | Description | Options Courantes |
|----------|-------------|------------------|
| `aws es describe-domain` | Affiche les détails d'un domaine OpenSearch | `--domain-name`, `--query` |
| `aws es list-domain-names` | Liste tous les domaines OpenSearch | - |

### Exemples Complets

```bash
# Configurer AWS CLI
aws configure

# Vérifier l'identité actuelle
aws sts get-caller-identity

# Lister toutes les instances EC2
aws ec2 describe-instances

# Lister les instances en cours d'exécution
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# Lister les instances avec un tag spécifique
aws ec2 describe-instances --filters "Name=tag:Project,Values=p5-openclassrooms"

# Récupérer l'IP publique d'une instance
aws ec2 describe-instances --instance-ids i-1234567890abcdef0 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# Vérifier OpenSearch
aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status" --output text

# Tester OpenSearch
curl -k -X GET "https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com" -H "Content-Type: application/json"
```

---

## 🔑 SSH

### Commandes de Base

| Commande | Description | Options Courantes |
|----------|-------------|------------------|
| `ssh` | Se connecte à un serveur distant | `-i`, `-p`, `-l`, `-v` |
| `ssh-keygen` | Génère une paire de clés SSH | `-t`, `-b`, `-f`, `-N` |
| `ssh-copy-id` | Copie une clé publique sur un serveur | `-i`, `-p` |
| `scp` | Copie des fichiers via SSH | `-i`, `-P`, `-r` |

### Exemples Complets

```bash
# Générer une paire de clés SSH (sans phrase de passe)
ssh-keygen -t rsa -b 4096 -f p5-key -N ""

# Se connecter à un serveur avec une clé SSH
ssh -i p5-key.pem ubuntu@54.123.45.67

# Copier une clé publique sur un serveur
ssh-copy-id -i p5-key.pub ubuntu@54.123.45.67

# Copier un fichier vers un serveur distant
scp -i p5-key.pem fichier.txt ubuntu@54.123.45.67:/tmp/

# Se connecter en mode verbose (pour le dépannage)
ssh -v -i p5-key.pem ubuntu@54.123.45.67
```

---

## 🌐 NGINX

### Commandes de Base

| Commande | Description |
|----------|-------------|
| `nginx -v` | Affiche la version |
| `nginx -t` | Teste la configuration |
| `nginx -s signal` | Envoie un signal (reload, stop, etc.) |

### Gestion du Service (Systemd)

| Commande | Description |
|----------|-------------|
| `sudo systemctl start nginx` | Démarre NGINX |
| `sudo systemctl stop nginx` | Arrête NGINX |
| `sudo systemctl restart nginx` | Redémarre NGINX |
| `sudo systemctl reload nginx` | Recharge la configuration |
| `sudo systemctl status nginx` | Affiche le statut |
| `sudo systemctl enable nginx` | Active au démarrage |

### Exemples Complets

```bash
# Démarrer NGINX
sudo systemctl start nginx

# Vérifier que NGINX est démarré
sudo systemctl status nginx

# Tester la configuration NGINX
sudo nginx -t

# Recharger la configuration NGINX (sans interruption)
sudo nginx -s reload

# Redémarrer NGINX
sudo systemctl restart nginx

# Voir les logs d'accès en temps réel
sudo tail -f /var/log/nginx/access.log

# Voir les logs d'erreur
sudo tail -f /var/log/nginx/error.log
```

---

## 🔍 OpenSearch

### Commandes de Base

| Commande | Description |
|----------|-------------|
| `curl -X GET "$OPENSEARCH_ENDPOINT"` | Teste l'API OpenSearch |
| `curl -X GET "$OPENSEARCH_ENDPOINT/_cat/health?v"` | Affiche l'état du cluster |
| `curl -X GET "$OPENSEARCH_ENDPOINT/_cat/nodes?v"` | Liste les nœuds |

### Exemples Complets

```bash
# Tester l'API OpenSearch
curl -k -X GET "https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com" -H "Content-Type: application/json"

# Voir l'état du cluster
curl -k -X GET "https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_cat/health?v"

# Lister les nœuds
curl -k -X GET "https://vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com/_cat/nodes?v"
```

---

## 🌐 HAProxy

### Commandes de Base

| Commande | Description |
|----------|-------------|
| `haproxy -v` | Affiche la version |
| `haproxy -c -f config` | Teste la configuration |
| `haproxy -f config` | Démarre HAProxy |

### Gestion du Service (Systemd)

| Commande | Description |
|----------|-------------|
| `sudo systemctl start haproxy` | Démarre HAProxy |
| `sudo systemctl stop haproxy` | Arrête HAProxy |
| `sudo systemctl restart haproxy` | Redémarre HAProxy |
| `sudo systemctl reload haproxy` | Recharge la configuration |
| `sudo systemctl status haproxy` | Affiche le statut |

### Exemples Complets

```bash
# Tester la configuration HAProxy
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Démarrer HAProxy
sudo systemctl start haproxy

# Vérifier que HAProxy est démarré
sudo systemctl status haproxy

# Recharger la configuration HAProxy (sans interruption)
sudo systemctl reload haproxy

# Tester HAProxy
curl http://54.200.100.50

# Tester le load balancing
for i in {1..5}; do curl -s http://54.200.100.50 | grep -o "Welcome to nginx from [^<]*"; echo "---"; done
```

---

## 🛠️ Dépannage

### Terraform

```bash
# Valider la syntaxe
terraform validate

# Voir les ressources gérées
terraform state list

# Voir les détails d'une ressource
terraform state show aws_instance.nginx_1

# Forcer le refresh du state
terraform refresh
```

### Ansible

```bash
# Tester la connectivité
ansible all -i hosts_aws -m ping

# Voir les facts
ansible all -i hosts_aws -m setup

# Mode verbose
ansible-playbook -i hosts_aws playbook.yml -v

# Mode dry-run
ansible-playbook -i hosts_aws playbook.yml --check
```

### AWS

```bash
# Vérifier les credentials
aws sts get-caller-identity

# Lister les instances
aws ec2 describe-instances

# Voir les logs d'une instance
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

### Réseau

```bash
# Tester la connectivité
ping 54.123.45.67

# Tester un port
nc -zv 54.123.45.67 80

# Voir les connexions
sudo netstat -tulnp

# Voir les processus réseau
sudo lsof -i
```

---

**Bonne utilisation des commandes CLI !** 💻

> *"Un bon développeur connaît ses outils."* — **Proverbe DevOps**
