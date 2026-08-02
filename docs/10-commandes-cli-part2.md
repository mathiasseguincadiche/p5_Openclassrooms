# 💻 Récapitulatif des Commandes CLI Essentielles - Partie 2

**P5 OpenClassrooms - Déploiement d'Infrastructure-as-Code**

---

## 📋 **Table des Matières**

1. [SSH](#-ssh)
2. [Git](#-git)
3. [NGINX](#-nginx)
4. [OpenSearch](#-opensearch)
5. [Logstash](#-logstash)
6. [Filebeat](#-filebeat)
7. [HAProxy](#-haproxy)
8. [Système (Linux)](#-système-linux)
9. [Réseau](#-réseau)
10. [Dépannage](#-dépannage)

---

## 🔑 **SSH**

### **Commandes de Base**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `ssh` | Se connecte à un serveur distant | `-i`, `-p`, `-l`, `-v` | `ssh user@host` |
| `ssh-keygen` | Génère une paire de clés SSH | `-t`, `-b`, `-f`, `-N` | `ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key` |
| `ssh-copy-id` | Copie une clé publique sur un serveur | `-i`, `-p` | `ssh-copy-id -i ~/.ssh/p5-key.pub user@host` |
| `ssh-agent` | Agent pour gérer les clés SSH | `-s`, `-k` | `eval "$(ssh-agent -s)"` |
| `ssh-add` | Ajoute une clé à l'agent SSH | `-l`, `-D`, `-d` | `ssh-add ~/.ssh/p5-key` |
| `scp` | Copie des fichiers via SSH | `-i`, `-P`, `-r` | `scp -i ~/.ssh/p5-key file.txt user@host:/tmp/` |
| `sftp` | Transfert de fichiers via SSH | `-i`, `-P` | `sftp -i ~/.ssh/p5-key user@host` |

### **Options Courantes**

| Option | Description | Exemple |
|--------|-------------|---------|
| `-i identity_file` | Spécifie le fichier de clé privée | `ssh -i ~/.ssh/p5-key user@host` |
| `-p port` | Spécifie le port SSH | `ssh -p 2222 user@host` |
| `-l login_name` | Spécifie le nom d'utilisateur | `ssh -l ec2-user host` |
| `-v` | Mode verbose | `ssh -v user@host` |
| `-t type` | Spécifie le type de clé | `ssh-keygen -t rsa` |
| `-b bits` | Spécifie la taille de la clé | `ssh-keygen -b 4096` |
| `-N new_passphrase` | Spécifie la phrase de passe | `ssh-keygen -N ""` |
| `-f filename` | Spécifie le nom du fichier | `ssh-keygen -f ~/.ssh/p5-key` |

### **Exemples Complets**

```bash
# Générer une paire de clés SSH (sans phrase de passe)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key -N ""

# Se connecter à un serveur avec une clé SSH
ssh -i ~/.ssh/p5-key ec2-user@52.47.123.45

# Se connecter avec un port personnalisé
ssh -i ~/.ssh/p5-key -p 2222 ec2-user@52.47.123.45

# Copier une clé publique sur un serveur
ssh-copy-id -i ~/.ssh/p5-key.pub ec2-user@52.47.123.45

# Démarrer l'agent SSH et ajouter une clé
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/p5-key

# Copier un fichier vers un serveur distant
scp -i ~/.ssh/p5-key fichier.txt ec2-user@52.47.123.45:/tmp/

# Copier un répertoire vers un serveur distant
scp -i ~/.ssh/p5-key -r dossier/ ec2-user@52.47.123.45:/tmp/

# Se connecter en mode verbose (pour le dépannage)
ssh -v -i ~/.ssh/p5-key ec2-user@52.47.123.45
```

---

## 📦 **Git**

### **Commandes de Base**

| Commande | Description | Options Courantes | Exemple |
|----------|-------------|------------------|---------|
| `git init` | Initialise un dépôt Git | - | `git init` |
| `git clone` | Clone un dépôt distant | `--depth`, `--branch` | `git clone https://github.com/user/repo.git` |
| `git status` | Affiche l'état du dépôt | `-s`, `--short` | `git status` |
| `git add` | Ajoute des fichiers à l'index | `-A`, `-u`, `--all` | `git add fichier.txt` |
| `git commit` | Commite les changements | `-m`, `-a`, `--amend` | `git commit -m "Message de commit"` |
| `git push` | Pousse les commits | `-u`, `--force`, `--force-with-lease` | `git push origin main` |
| `git pull` | Tire les commits | `--rebase`, `--no-rebase` | `git pull origin main` |
| `git fetch` | Récupère les changements | `--all`, `--prune` | `git fetch origin` |
| `git merge` | Fusionne des branches | `--no-ff`, `--squash` | `git merge feature-branch` |
| `git checkout` | Change de branche ou restaure des fichiers | `-b`, `-B` | `git checkout -b feature-branch` |
| `git switch` | Change de branche | `-c`, `-C` | `git switch feature-branch` |
| `git branch` | Gère les branches | `-a`, `-r`, `-d`, `-D` | `git branch -a` |
| `git log` | Affiche l'historique | `--oneline`, `--graph`, `--all` | `git log --oneline` |

### **Options Courantes**

| Option | Description | Exemple |
|--------|-------------|---------|
| `-m message` | Spécifie le message de commit | `git commit -m "Message"` |
| `-a` | Ajoute tous les fichiers modifiés | `git commit -a -m "Message"` |
| `--amend` | Modifie le dernier commit | `git commit --amend` |
| `-u` | Définit l'upstream | `git push -u origin main` |
| `--force` | Force le push (attention !) | `git push --force` |
| `--force-with-lease` | Force le push de manière plus sûre | `git push --force-with-lease` |
| `--rebase` | Rejoue les commits locaux | `git pull --rebase` |
| `-b branch` | Crée une nouvelle branche | `git checkout -b feature` |
| `-d branch` | Supprime une branche locale | `git branch -d feature` |
| `-D branch` | Supprime une branche locale (forcé) | `git branch -D feature` |
| `--oneline` | Affiche le log en une ligne | `git log --oneline` |
| `--graph` | Affiche le log sous forme de graphe | `git log --graph --oneline` |

### **Exemples Complets**

```bash
# Cloner un dépôt
 git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git

# Initialiser un dépôt Git
git init

# Vérifier l'état du dépôt
git status

# Ajouter tous les fichiers modifiés
git add -A

# Commiter les changements
git commit -m "Ajout de la configuration Terraform pour l'Exercice 1"

# Pousser vers le dépôt distant (première fois)
git push -u origin main

# Pousser vers le dépôt distant (fois suivantes)
git push

# Tirer les changements depuis le dépôt distant
git pull

# Créer une nouvelle branche
git checkout -b exercice-2

# Changer de branche
git switch main

# Fusionner une branche
git merge exercice-2

# Voir l'historique des commits
git log --oneline --graph --all

# Voir les différences non commitées
git diff

# Voir les différences commitées mais non poussées
git diff origin/main

# Réinitialiser les changements non commités
git reset --hard

# Annuler le dernier commit (en gardant les changements)
git reset --soft HEAD~1

# Annuler un commit spécifique
git revert abc123

# Stocker temporairement les changements
git stash push -m "Modifications en cours"

# Récupérer les changements stockés
git stash pop

# Lister les dépôts distants
git remote -v

# Configurer Git
git config --global user.name "Votre Nom"
git config --global user.email "votre@email.com"
```

---

## 🌐 **NGINX**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `nginx -v` | Affiche la version | `nginx -v` |
| `nginx -V` | Affiche la version et les options | `nginx -V` |
| `nginx -t` | Teste la configuration | `nginx -t` |
| `nginx -s signal` | Envoie un signal | `nginx -s reload` |

### **Gestion du Service (Systemd)**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start nginx` | Démarre NGINX | `sudo systemctl start nginx` |
| `systemctl stop nginx` | Arrête NGINX | `sudo systemctl stop nginx` |
| `systemctl restart nginx` | Redémarre NGINX | `sudo systemctl restart nginx` |
| `systemctl reload nginx` | Recharge la configuration | `sudo systemctl reload nginx` |
| `systemctl status nginx` | Affiche le statut | `sudo systemctl status nginx` |
| `systemctl enable nginx` | Active au démarrage | `sudo systemctl enable nginx` |

### **Logs NGINX**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `tail -f /var/log/nginx/access.log` | Logs d'accès en temps réel | `sudo tail -f /var/log/nginx/access.log` |
| `tail -f /var/log/nginx/error.log` | Logs d'erreur en temps réel | `sudo tail -f /var/log/nginx/error.log` |
| `grep "error" /var/log/nginx/error.log` | Recherche les erreurs | `sudo grep "error" /var/log/nginx/error.log` |

### **Exemples Complets**

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

# Vérifier les ports ouverts par NGINX
sudo netstat -tulnp | grep nginx

# Compter le nombre de requêtes dans les logs
sudo wc -l /var/log/nginx/access.log

# Voir la version de NGINX
nginx -v

# Arrêter NGINX
sudo systemctl stop nginx
```

---

## 🔍 **OpenSearch**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `opensearch -v` | Affiche la version | `opensearch -v` |
| `curl -X GET "http://localhost:9200/"` | Teste l'API | `curl -X GET "http://localhost:9200/"` |

### **Gestion du Service (Systemd)**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start opensearch` | Démarre OpenSearch | `sudo systemctl start opensearch` |
| `systemctl stop opensearch` | Arrête OpenSearch | `sudo systemctl stop opensearch` |
| `systemctl status opensearch` | Affiche le statut | `sudo systemctl status opensearch` |

### **API REST OpenSearch**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `curl -X GET "http://localhost:9200/_cat/health?v"` | État du cluster | `curl -X GET "http://localhost:9200/_cat/health?v"` |
| `curl -X GET "http://localhost:9200/_cat/nodes?v"` | Liste les nœuds | `curl -X GET "http://localhost:9200/_cat/nodes?v"` |
| `curl -X GET "http://localhost:9200/_cat/indices?v"` | Liste les index | `curl -X GET "http://localhost:9200/_cat/indices?v"` |
| `curl -X GET "http://localhost:9200/logs-nginx-*/_count?pretty"` | Compte les documents | `curl -X GET "http://localhost:9200/logs-nginx-*/_count?pretty"` |

### **Exemples Complets**

```bash
# Démarrer OpenSearch
sudo systemctl start opensearch

# Vérifier que OpenSearch est démarré
sudo systemctl status opensearch

# Tester l'API OpenSearch
curl -X GET "http://localhost:9200/"

# Voir l'état du cluster
curl -X GET "http://localhost:9200/_cat/health?v"

# Lister les nœuds
curl -X GET "http://localhost:9200/_cat/nodes?v"

# Lister les index
curl -X GET "http://localhost:9200/_cat/indices?v"

# Compter les documents dans un index
curl -X GET "http://localhost:9200/logs-nginx-*/_count?pretty"

# Voir les logs OpenSearch
sudo tail -f /var/log/opensearch/opensearch.log

# Arrêter OpenSearch
sudo systemctl stop opensearch
```

---

## 🔧 **Logstash**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `logstash -v` | Affiche la version | `logstash -v` |
| `logstash -f config` | Exécute avec un fichier de config | `logstash -f /etc/logstash/conf.d/logstash.conf` |
| `logstash -t` | Teste la configuration | `logstash -f config -t` |
| `logstash --config.test_and_exit` | Teste et quitte | `logstash -f config --config.test_and_exit` |

### **Gestion du Service (Systemd)**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start logstash` | Démarre Logstash | `sudo systemctl start logstash` |
| `systemctl stop logstash` | Arrête Logstash | `sudo systemctl stop logstash` |
| `systemctl status logstash` | Affiche le statut | `sudo systemctl status logstash` |

### **Exemples Complets**

```bash
# Tester la configuration Logstash
sudo /usr/share/logstash/bin/logstash -f /etc/logstash/conf.d/logstash.conf --config.test_and_exit

# Démarrer Logstash
sudo systemctl start logstash

# Vérifier que Logstash est démarré
sudo systemctl status logstash

# Voir les logs Logstash
sudo tail -f /var/log/logstash/logstash-plain.log

# Arrêter Logstash
sudo systemctl stop logstash

# Redémarrer Logstash
sudo systemctl restart logstash
```

---

## 📡 **Filebeat**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `filebeat -v` | Affiche la version | `filebeat -v` |
| `filebeat test config` | Teste la configuration | `filebeat test config` |
| `filebeat test output` | Teste la connexion | `filebeat test output` |
| `filebeat modules enable nginx` | Active le module NGINX | `filebeat modules enable nginx` |
| `filebeat setup` | Configure les index | `filebeat setup -e` |

### **Gestion du Service (Systemd)**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start filebeat` | Démarre Filebeat | `sudo systemctl start filebeat` |
| `systemctl stop filebeat` | Arrête Filebeat | `sudo systemctl stop filebeat` |
| `systemctl status filebeat` | Affiche le statut | `sudo systemctl status filebeat` |

### **Exemples Complets**

```bash
# Tester la configuration Filebeat
sudo filebeat test config

# Tester la connexion à la sortie (Logstash)
sudo filebeat test output

# Activer le module NGINX
sudo filebeat modules enable nginx

# Configurer Filebeat (créer les index dans OpenSearch)
sudo filebeat setup -e

# Démarrer Filebeat
sudo systemctl start filebeat

# Vérifier que Filebeat est démarré
sudo systemctl status filebeat

# Voir les logs Filebeat
sudo tail -f /var/log/filebeat/filebeat

# Arrêter Filebeat
sudo systemctl stop filebeat
```

---

## 🌐 **HAProxy**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `haproxy -v` | Affiche la version | `haproxy -v` |
| `haproxy -c -f config` | Teste la configuration | `haproxy -c -f /etc/haproxy/haproxy.cfg` |
| `haproxy -f config` | Démarre HAProxy | `haproxy -f /etc/haproxy/haproxy.cfg` |

### **Gestion du Service (Systemd)**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start haproxy` | Démarre HAProxy | `sudo systemctl start haproxy` |
| `systemctl stop haproxy` | Arrête HAProxy | `sudo systemctl stop haproxy` |
| `systemctl status haproxy` | Affiche le statut | `sudo systemctl status haproxy` |
| `systemctl reload haproxy` | Recharge la configuration | `sudo systemctl reload haproxy` |

### **Statistiques HAProxy**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `curl http://localhost:8404/stats` | Affiche les statistiques | `curl http://localhost:8404/stats` |

### **Exemples Complets**

```bash
# Tester la configuration HAProxy
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# Démarrer HAProxy
sudo systemctl start haproxy

# Vérifier que HAProxy est démarré
sudo systemctl status haproxy

# Voir les processus HAProxy
ps aux | grep haproxy

# Voir les ports ouverts par HAProxy
sudo netstat -tulnp | grep haproxy

# Voir les statistiques HAProxy
curl http://localhost:8404/stats

# Recharger la configuration HAProxy (sans interruption)
sudo systemctl reload haproxy

# Arrêter HAProxy
sudo systemctl stop haproxy
```

---

## 🐧 **Système (Linux)**

### **Gestion des Services**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `systemctl start service` | Démarre un service | `sudo systemctl start nginx` |
| `systemctl stop service` | Arrête un service | `sudo systemctl stop nginx` |
| `systemctl restart service` | Redémarre un service | `sudo systemctl restart nginx` |
| `systemctl status service` | Affiche le statut | `sudo systemctl status nginx` |
| `systemctl enable service` | Active au démarrage | `sudo systemctl enable nginx` |
| `systemctl is-active service` | Vérifie si actif | `systemctl is-active nginx` |

### **Gestion des Processus**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ps aux` | Affiche tous les processus | `ps aux` |
| `ps aux \| grep nginx` | Filtre les processus | `ps aux | grep nginx` |
| `kill PID` | Tue un processus | `kill 1234` |
| `kill -9 PID` | Tue un processus de force | `kill -9 1234` |
| `killall nginx` | Tue tous les processus nginx | `killall nginx` |
| `pkill nginx` | Tue les processus correspondant | `pkill nginx` |

### **Gestion de la Mémoire et du CPU**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `free -h` | Affiche l'utilisation mémoire | `free -h` |
| `top` | Affiche les processus | `top` |
| `htop` | Affiche les processus (amélioré) | `htop` |
| `df -h` | Affiche l'utilisation disque | `df -h` |
| `du -sh /var/log` | Affiche la taille d'un dossier | `du -sh /var/log` |

### **Logs Système**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `journalctl` | Affiche les logs systemd | `journalctl` |
| `journalctl -u nginx` | Affiche les logs d'un service | `journalctl -u nginx` |
| `journalctl -f` | Suit les logs en temps réel | `journalctl -f` |
| `journalctl -u nginx -f` | Suit les logs d'un service | `journalctl -u nginx -f` |

---

## 🌐 **Réseau**

### **Commandes de Base**

| Commande | Description | Exemple |
|----------|-------------|---------|
| `ping google.com` | Teste la connectivité | `ping google.com` |
| `ping -c 4 google.com` | Teste avec 4 paquets | `ping -c 4 google.com` |
| `traceroute google.com` | Affiche le chemin réseau | `traceroute google.com` |
| `mtr google.com` | Combine ping et traceroute | `mtr google.com` |
| `nslookup google.com` | Requête DNS | `nslookup google.com` |
| `dig google.com` | Requête DNS (plus puissante) | `dig google.com` |
| `curl http://example.com` | Requête HTTP | `curl http://example.com` |
| `curl -v http://example.com` | Requête HTTP verbose | `curl -v http://example.com` |
| `curl -I http://example.com` | Affiche les en-têtes HTTP | `curl -I http://example.com` |
| `nc -zv host port` | Teste une connexion TCP | `nc -zv google.com 80` |
| `netstat -tulnp` | Affiche les ports ouverts | `sudo netstat -tulnp` |
| `ss -tulnp` | Affiche les ports ouverts (alternative) | `sudo ss -tulnp` |
| `lsof -i :80` | Affiche les processus sur le port 80 | `sudo lsof -i :80` |

---

## 🛠️ **Dépannage**

### **Terraform**

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

### **Ansible**

```bash
# Tester la connectivité
ansible -i inventory.ini all -m ping

# Voir les facts
ansible -i inventory.ini all -m setup

# Mode verbose
ansible-playbook -i inventory.ini playbook.yml -v

# Mode dry-run
ansible-playbook -i inventory.ini playbook.yml --check
```

### **AWS**

```bash
# Vérifier les credentials
aws sts get-caller-identity

# Lister les instances
aws ec2 describe-instances

# Voir les logs d'une instance
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

### **Réseau**

```bash
# Tester la connectivité
ping 52.47.123.45

# Tester un port
nc -zv 52.47.123.45 80

# Voir les connexions
sudo netstat -tulnp

# Voir les processus réseau
sudo lsof -i
```

---

## 🎯 **Résumé des Commandes les Plus Utilisées**

### **Top 5 par Outil**

**Terraform** :
1. `terraform init`
2. `terraform plan`
3. `terraform apply`
4. `terraform destroy`
5. `terraform output`

**Ansible** :
1. `ansible -i inventory.ini all -m ping`
2. `ansible-playbook -i inventory.ini playbook.yml`
3. `ansible -i inventory.ini all -a "command"`
4. `ansible -i inventory.ini all -m setup`
5. `ansible-inventory -i inventory.ini --list`

**AWS CLI** :
1. `aws configure`
2. `aws sts get-caller-identity`
3. `aws ec2 describe-instances`
4. `aws ec2 describe-vpcs`
5. `aws ec2 describe-security-groups`

**SSH** :
1. `ssh -i ~/.ssh/key user@host`
2. `ssh-keygen -t rsa -b 4096`
3. `scp -i ~/.ssh/key file user@host:/path/`
4. `ssh -v user@host`
5. `ssh-copy-id -i ~/.ssh/key.pub user@host`

**Git** :
1. `git clone repo`
2. `git status`
3. `git add .`
4. `git commit -m "message"`
5. `git push`

---

**Bonne utilisation des commandes CLI !** 💻

> *"La ligne de commande est votre meilleure amie."* — **Anonyme**
