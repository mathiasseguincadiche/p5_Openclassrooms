# 🚀 P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
**Runbook Pédagogique Ultime - Guide Pas à Pas avec Explications, Commandes Commentées et Vérifications**

---

## 📜 **À PROPOS DE CE RUNBOOK**

Ce document est votre **guide ultime** pour réussir votre **Projet 5 OpenClassrooms (4091)** :
> **"Déployer et suivre l'infrastructure as code grâce à Terraform, Ansible et la stack ELK"**

✅ **100% orienté débutant** – Chaque concept est expliqué simplement, avec des analogies.
✅ **100% pratique** – Commandes à copier-coller, résultats attendus, vérifications à chaque étape.
✅ **100% pédagogique** – Pour chaque action : **LE QUOI, LE POURQUOI, LE COMMENT**.
✅ **100% conforme OpenClassrooms** – Aligné avec les consignes officielles (Angular, Kibana, nginxdemos/hello).
✅ **100% reproductible** – Refaisable à l'identique dans 6 mois.

💡 **Ce runbook est conçu pour que vous COMPRENIEZ chaque étape, pas juste que vous l'EXÉCUTEZ.**

---

## 🎯 **OBJECTIFS PÉDAGOGIQUES**

| Compétence | Description | Outils | Exercices |
|------------|-------------|-------|-----------|
| **Infrastructure as Code (IaC)** | Décrire et déployer une infrastructure via du code | Terraform | 1, 2, 3 |
| **Configuration Management** | Configurer automatiquement des serveurs | Ansible | 1, 3 |
| **Déploiement d'applications** | Déployer une application Angular sur NGINX | NGINX, Angular | 1 |
| **Centralisation des logs** | Stocker et analyser des logs avec OpenSearch/Kibana | OpenSearch, Kibana | 2 |
| **Load Balancing** | Répartir la charge entre plusieurs serveurs | HAProxy | 3 |
| **Bonnes pratiques DevOps** | Nettoyage, documentation, vérifications | Git, AWS CLI | Tous |

---

## ⚠️ **PRÉREQUIS OBLIGATOIRES**

### 📋 **Matériel et Logiciels**

| Élément | Commande de vérification | Solution si manquant | Obligatoire |
|---------|--------------------------|----------------------|-------------|
| **Fedora 44 (Cosmic/KDE)** | `cat /etc/os-release` | Installez Fedora 44 | ✅ |
| **KVM/QEMU/libvirt** | `virsh list --all` | `sudo dnf install -y qemu-kvm libvirt virt-install virt-manager` | ✅ |
| **VM vm-devops (Ubuntu 26.04)** | `ssh devops@<IP>` | Créez-la avec `virt-manager` (4 Go RAM, 2 vCPU, 20 Go disque) | ✅ |
| **Compte AWS** | `aws sts get-caller-identity` | Créez un compte AWS | ✅ |
| **Clés AWS** | `aws configure` | Créez-les dans IAM > Security Credentials | ✅ |
| **Git** | `git --version` | `sudo apt install -y git` | ✅ |
| **Terraform** | `terraform -version` | `sudo apt install -y terraform` | ✅ |
| **Ansible** | `ansible --version` | `sudo apt install -y ansible` | ✅ |
| **AWS CLI** | `aws --version` | `sudo apt install -y awscli` | ✅ |
| **Node.js + npm** | `node --version && npm --version` | `sudo apt install -y nodejs npm` | ✅ |

---

### 🌍 **Configuration AWS**
- **Région** : `us-east-1` **(OBLIGATOIRE)**.
- **Budget** : Prévoyez **20€ max** (10-15€ si vous suivez les consignes).
- **Free Tier** : Les instances **t2.micro** sont gratuites pendant 12 mois.

---

## 📌 **CONSEILS AVANT DE COMMENCER**

🔹 **Ne modifiez pas** les fichiers du pack original → Travaillez dans une copie.
🔹 **Ne commitez JAMAIS** dans Git : `.tfvars`, clés SSH privées, outputs sensibles.
🔹 **Vérifiez toujours** avec `terraform plan` avant `terraform apply`.
🔹 **Ne sautez jamais** un point **⚠️ STOP** dans ce runbook.
🔹 **Notez toutes vos actions** dans un journal de bord (pour les livrables).

---

---

# 🗺️ **RUNBOOK : FEUILLE DE ROUTE DE A À Z**
*Suivez ce guide **pas à pas** pour réaliser votre projet sans vous perdre.*
*⏳ **Temps total estimé : ~12-15h** (réparti sur plusieurs sessions).

---

## 📌 **PHASE 0 : PRÉPARATION (30 min - 1h)**
*Objectif : Configurer votre environnement de travail.*

### 📋 **Checklist de Préparation**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 1 | Créer la VM `vm-devops` (Ubuntu 26.04) | `virt-manager` | VM accessible en SSH | [ ] |
| 2 | Se connecter à la VM | `ssh devops@<IP_VM_DEVOPS>` | Connexion réussie | [ ] |
| 3 | Mettre à jour les packages | `sudo apt update && sudo apt upgrade -y` | Pas d'erreurs | [ ] |
| 4 | Installer Terraform | `sudo apt install -y terraform` | `terraform -version` → v1.15+ | [ ] |
| 5 | Installer Ansible | `sudo apt install -y ansible` | `ansible --version` → 2.15+ | [ ] |
| 6 | Installer AWS CLI | `sudo apt install -y awscli` | `aws --version` → 2.x.x | [ ] |
| 7 | Installer Git | `sudo apt install -y git` | `git --version` → 2.x.x | [ ] |
| 8 | Installer Node.js + npm | `sudo apt install -y nodejs npm` | `node --version` → v16+ | [ ] |
| 9 | Configurer AWS CLI | `aws configure` | `aws sts get-caller-identity` → OK | [ ] |
| 10 | Cloner ce dépôt | `git clone <URL>` | Dépôt local prêt | [ ] |

---

### ⚠️ **VÉRIFICATION FINALE PHASE 0**
```bash
# Vérifiez que tout est installé
terraform -version && ansible --version && aws --version && git --version && node --version && npm --version
```
**✅ Résultat attendu** : Toutes les commandes retournent une version valide.
**💡 POURQUOI ?** Ces outils sont **indispensables** pour déployer et configurer votre infrastructure.

---

## 📌 **PHASE 1 : EXERCICE 1 - TERRAFORM + ANSIBLE + ANGULAR (4-5h)**
*Objectif : Déployer 2 VMs AWS avec NGINX + Application Angular.*

---

### 📚 **CONCEPTS CLÉS**

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **IaC (Infrastructure as Code)** | Décrire votre infrastructure dans du code (fichiers `.tf`). | Automatise la création de serveurs, réseaux, etc. | Plan de construction |
| **Terraform** | Outil pour appliquer l'IaC. | Crée/supprime des ressources cloud de manière reproductible | Architecte |
| **Ansible** | Outil pour configurer des serveurs à distance. | Installe et configure automatiquement des logiciels | Décorateur |
| **Angular** | Framework JavaScript pour créer des applications web dynamiques. | Permet de créer des interfaces réactives | Recette de cuisine |
| **NGINX** | Serveur web pour servir des pages statiques. | Affiche votre application Angular | Serveur dans un restaurant |

---

### 🚀 **ÉTAPES D'EXÉCUTION**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 1 | Aller dans le dossier Exercice 1 | `cd 04_EXERCICES/01_TERRAFORM_ANSIBLE/` | Dossier accessible | [ ] |
| 2 | Initialiser Terraform | `terraform init` | `Terraform has been successfully initialized!` | [ ] |
| 3 | Vérifier le plan | `terraform plan` | Liste des ressources à créer (VPC, subnets, 2 VMs, etc.) | [ ] |
| 4 | **⚠️ STOP : Vérifiez le plan** | - | Pas de ressources inattendues | [ ] |
| 5 | Appliquer Terraform | `terraform apply -auto-approve` | `Apply complete! Resources: X added` | [ ] |
| 6 | Récupérer les IPs des VMs | `terraform output` | 2 IPs publiques affichées | [ ] |
| 7 | **⚠️ STOP : Notez les IPs** | - | IPs sauvegardées (ex: `54.123.45.67`, `54.123.45.68`) | [ ] |

---

### 📝 **CRÉER L'INVENTAIRE ANSIBLE**
```bash
nano hosts_aws
```
**Contenu** :
```ini
[webservers]
<IP_VM1> ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
<IP_VM2> ansible_user=ubuntu ansible_ssh_private_key_file=p5-key.pem
```
*(Remplacez `<IP_VM1>` et `<IP_VM2>` par vos IPs publiques.)*

---

### 🚀 **SUITE DES ÉTAPES**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 8 | Tester la connexion Ansible | `ansible all -i hosts_aws -m ping` | `pong` pour les 2 VMs | [ ] |
| 9 | **⚠️ STOP : Vérifiez la connexion SSH** | `ssh -i p5-key.pem ubuntu@<IP>` | Connexion réussie | [ ] |
| 10 | Exécuter le playbook Ansible | `ansible-playbook -i hosts_aws deploy.yml` | Toutes les tâches en `ok` ou `changed` | [ ] |
| 11 | Vérifier NGINX | `curl http://<IP_VM1>` | Page Angular affichée (pas "Welcome to nginx!") | [ ] |
| 12 | **⚠️ STOP : Vérifiez l'application** | - | Application Angular accessible | [ ] |

---

### 💡 **POURQUOI ON FAIT ÇA ?**
- **Terraform** : Pour **créer automatiquement** les 2 VMs AWS avec VPC, subnets et Security Groups.
- **Ansible** : Pour **configurer automatiquement** les VMs avec NGINX et l'application Angular.
- **Angular** : Pour **servir une vraie application** (conforme aux consignes OpenClassrooms).

---

### ❓ **DÉPANNAGE PHASE 1**

| Problème | Cause | Solution |
|----------|-------|----------|
| `No valid credential sources` | AWS CLI non configuré | `aws configure` puis `aws sts get-caller-identity` |
| `Permission denied (publickey)` | Clé SSH manquante | Vérifiez `p5-key.pem` et le Security Group (port 22) |
| `No package named 'nginx'` | Cache APT non mis à jour | `sudo apt update` sur les VMs |
| `Job for nginx.service failed` | Config NGINX invalide | `sudo nginx -t` pour tester |
| `angular-app not found` | Repo manquant | Utilisez le repo officiel OpenClassrooms |

---

### ✅ **VÉRIFICATION FINALE PHASE 1**
- [ ] 2 VMs AWS en cours d'exécution (`Running`).
- [ ] NGINX installé sur les 2 VMs.
- [ ] Application Angular **accessible** via `http://<IP>`.
- [ ] Playbook Ansible exécuté sans erreur.

**→ Si tout est validé, passez à la [Phase 2](#phase-2-exercice-2-opensearch--kibana--dashboard-3-4h).**

---

---

## 📌 **PHASE 2 : EXERCICE 2 - OPENSEARCH + KIBANA + DASHBOARD (3-4h)**
*Objectif : Déployer OpenSearch + Kibana, charger les logs NGINX et créer un dashboard avec 3 diagrammes.*

---

### 📚 **CONCEPTS CLÉS**

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **OpenSearch** | Moteur de recherche et d'analyse open source. | Stocke et analyse les logs à grande échelle | Système de rangement intelligent |
| **Kibana** | Interface de visualisation pour OpenSearch. | Crée des dashboards et graphiques | Tableau de bord |
| **Index** | Ensemble de documents similaires. | Organise les logs par type (ex: `nginx-access-2026.08.02`) | Dossier dans un classeur |
| **Index Pattern** | Configuration pour accéder à un index dans Kibana. | Permet de lier Kibana à vos logs | Clé pour ouvrir un dossier |
| **Visualisation** | Graphique créé dans Kibana. | Affiche des données sous forme visuelle | Diagramme |

---

### 🚀 **ÉTAPES D'EXÉCUTION**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 1 | Aller dans le dossier Exercice 2 | `cd 04_EXERCICES/02_OPENSEARCH/` | Dossier accessible | [ ] |
| 2 | Initialiser Terraform | `terraform init` | `Terraform has been successfully initialized!` | [ ] |
| 3 | Vérifier le plan | `terraform plan` | Création du domaine OpenSearch | [ ] |
| 4 | **⚠️ STOP : Vérifiez le plan** | - | Domaine OpenSearch avec Kibana activé | [ ] |
| 5 | Appliquer Terraform | `terraform apply -auto-approve` | `Apply complete!` (5-10 min) | [ ] |
| 6 | Récupérer l'endpoint | `terraform output opensearch_endpoint` | URL du cluster affichée | [ ] |
| 7 | **⚠️ STOP : Notez l'endpoint** | - | Ex: `vpc-p5-opensearch-xxxxxxxx.us-east-1.es.amazonaws.com` | [ ] |

---

### 🔐 **CONFIGURER L'ACCÈS SÉCURISÉ (OBLIGATOIRE)**
```bash
# 1. Récupérer votre IP publique
MY_IP=$(curl -s ifconfig.me)

# 2. Créer le fichier access-policy.json
cat > access-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"AWS": "*"},
    "Action": ["es:*"],
    "Resource": "arn:aws:es:us-east-1:$(aws sts get-caller-identity --query Account --output text):domain/p5-opensearch/*",
    "Condition": {"IpAddress": {"aws:SourceIp": ["$MY_IP/32"]}}
  }]
}
EOF

# 3. Appliquer la policy
aws es update-domain-config --domain-name p5-opensearch --access-policies file://access-policy.json
```
**⚠️ STOP : Attendez 1-2 min** pour que la policy soit appliquée.

---

### 📤 **CHARGER LES LOGS NGINX**
```bash
# 1. Vérifiez que le fichier nginx-access.log existe
ls -lh data/nginx-access.log

# 2. Charger les logs dans OpenSearch (méthode simple avec curl + jq)
sudo apt install -y jq
while IFS= read -r line; do
  ip=$(echo "$line" | awk '{print $1}')
  date_time=$(echo "$line" | awk '{print $4,$5}')
  method=$(echo "$line" | awk -F'"' '{print $2}')
  url=$(echo "$line" | awk -F'"' '{print $3}')
  status=$(echo "$line" | awk '{print $9}')
  size=$(echo "$line" | awk '{print $10}')
  
  json_doc=$(jq -n --arg ip "$ip" --arg timestamp "$date_time" --arg method "$method" --arg url "$url" --arg status "$status" --arg size "$size" '{
    "@timestamp": $timestamp,
    "client_ip": $ip,
    "method": $method,
    "url": $url,
    "status": $status,
    "size": $size
  }')
  
  curl -k -X POST "$OPENSEARCH_ENDPOINT/nginx-access-$(date +%Y.%m.%d)/_doc" -H "Content-Type: application/json" -d "$json_doc"
done < data/nginx-access.log
```
**⚠️ STOP : Vérifiez que les logs sont chargés** :
```bash
curl -k -X GET "$OPENSEARCH_ENDPOINT/_cat/indices?v" -H "Content-Type: application/json"
```
**→ Vous devriez voir l'index `nginx-access-*`.**

---

### 🎨 **CRÉER LES 3 DIAGRAMMES OBLIGATOIRES DANS KIBANA**
*(À faire dans l'interface Kibana : `https://<votre-endpoint>/_dashboards`)*

| # | Diagramme | Type | Configuration | ✅ |
|---|-----------|------|---------------|---|
| 1 | Répartition des verbes HTTP | Donut Chart | **Metrics**: Count, **Buckets**: Terms (field: `method`) | [ ] |
| 2 | Quantité cumulée de données par tranche de 12h | Histogram | **Metrics**: Sum (field: `size`), **X-Axis**: Date Histogram (interval: `12h`) | [ ] |
| 3 | Top 5 des requêtes par tranche de 12h | Cumulative Histogram | **Metrics**: Count, **X-Axis**: Date Histogram (interval: `12h`), **Split Series**: Terms (field: `url`, size: 5, order: Descending, cumulative: ✅) | [ ] |

---

### 📸 **GÉNÉRER LES 4 CAPTURES D'ÉCRAN (OBLIGATOIRE)**

| # | Capture | Description | Nom du fichier |
|---|---------|-------------|----------------|
| 1 | Dashboard complet | Dashboard avec les 3 diagrammes | `SEGUIN-CADICHE_Mathias_2_dashboard_complet_<date>.png` |
| 2 | Diagramme Donut | Répartition des verbes HTTP | `SEGUIN-CADICHE_Mathias_2_diagramme_donut_<date>.png` |
| 3 | Diagramme Histogramme | Quantité cumulée de données | `SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_<date>.png` |
| 4 | Diagramme Histogramme cumulé | Top 5 des requêtes | `SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_cumule_<date>.png` |

**💡 POURQUOI ?** OpenClassrooms **exige** ces 4 captures pour valider l'Exercice 2.

---

### ❓ **DÉPANNAGE PHASE 2**

| Problème | Cause | Solution |
|----------|-------|----------|
| `Domain already exists` | Domaine OpenSearch déjà créé | `aws es delete-domain --domain-name p5-opensearch` puis attendez 10-15 min |
| `Access Denied` (Kibana) | Access policy non configurée | Vérifiez l'[étape de configuration](#configurer-laccès-sécurisé-obligatoire) |
| `No data` dans Kibana | Logs non chargés | Vérifiez que l'index `nginx-access-*` existe avec `curl -k -X GET "$OPENSEARCH_ENDPOINT/_cat/indices?v"` |
| Kibana ne s'affiche pas | Cluster non prêt | Attendez que le statut soit `Active` (`aws es describe-domain --domain-name p5-opensearch --query "DomainStatus.Status"`) |

---

### ✅ **VÉRIFICATION FINALE PHASE 2**
- [ ] Cluster OpenSearch déployé avec Kibana activé.
- [ ] Fichier `nginx-access.log` chargé dans OpenSearch.
- [ ] Index `nginx-access-*` visible dans Kibana.
- [ ] **3 diagrammes créés** (donut, histogramme, histogramme cumulé).
- [ ] **4 captures d'écran générées** (dashboard + 3 diagrammes).

**→ Si tout est validé, passez à la [Phase 3](#phase-3-exercice-3-haproxy--nginxdemoshello-2-3h).**

---

---

## 📌 **PHASE 3 : EXERCICE 3 - HAPROXY + NGINXDEMOS/HELLO (2-3h)**
*Objectif : Déployer HAProxy devant 2 instances de `nginxdemos/hello` et vérifier l'alternance des requêtes.*

---

### 📚 **CONCEPTS CLÉS**

| Concept | Explication | Pourquoi c'est utile ? | Analogie |
|---------|-------------|------------------------|----------|
| **Load Balancer** | Répartit le trafic entre plusieurs serveurs. | Évite la surcharge d'un seul serveur | Réceptionniste |
| **Round Robin** | Algorithme de répartition simple. | Équilibre la charge de manière équitable | Tour de rôle |
| **Health Check** | Vérification automatique de la santé des serveurs. | Exclut les serveurs en panne | Contrôle de santé |
| **Reverse Proxy** | Intermédiaire entre les clients et les serveurs backend. | Masque les serveurs backend | Intermédiaire |
| **`nginxdemos/hello`** | Image Docker officielle pour tester NGINX. | Affiche un `Server name` unique par conteneur | Carte de visite |

---

### 🚀 **ÉTAPES D'EXÉCUTION**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 1 | Aller dans le dossier Exercice 3 | `cd 04_EXERCICES/03_HAPROXY/` | Dossier accessible | [ ] |
| 2 | Initialiser Terraform | `terraform init` | `Terraform has been successfully initialized!` | [ ] |
| 3 | Vérifier le plan | `terraform plan` | Création de 2 VMs + 1 VM HAProxy | [ ] |
| 4 | **⚠️ STOP : Vérifiez le plan** | - | 3 VMs (2 backend + 1 HAProxy) | [ ] |
| 5 | Appliquer Terraform | `terraform apply -auto-approve` | `Apply complete!` | [ ] |
| 6 | Récupérer les IPs privées des VMs backend | `terraform output` | 2 IPs privées affichées | [ ] |
| 7 | **⚠️ STOP : Notez les IPs privées** | - | Ex: `10.0.1.123`, `10.0.2.45` | [ ] |

---

### 🔧 **GÉNÉRER LA CONFIGURATION HAPROXY**
```bash
# 1. Exécuter le script de génération
./scripts/generer-haproxy-config.sh <IP_PRIVEE_VM1> <IP_PRIVEE_VM2>

# 2. Vérifier le fichier généré
cat haproxy.cfg
```
**✅ Résultat attendu** : Configuration HAProxy avec `balance roundrobin` et les 2 serveurs backend.

---

### 🚀 **SUITE DES ÉTAPES**

| # | Action | Commande | Résultat attendu | ✅ |
|---|--------|----------|------------------|---|
| 8 | Récupérer l'IP publique de HAProxy | `terraform output haproxy_public_ip` | IP affichée | [ ] |
| 9 | **⚠️ STOP : Notez l'IP de HAProxy** | - | Ex: `54.200.100.50` | [ ] |
| 10 | Copier haproxy.cfg sur la VM HAProxy | `scp -i p5-key.pem haproxy.cfg ubuntu@<IP_HAPROXY>:/tmp/` | Fichier copié | [ ] |
| 11 | Se connecter à la VM HAProxy | `ssh -i p5-key.pem ubuntu@<IP_HAPROXY>` | Connexion réussie | [ ] |
| 12 | Déployer la configuration | `sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg && sudo chmod 644 /etc/haproxy/haproxy.cfg` | Fichier déployé | [ ] |
| 13 | Tester la configuration | `sudo haproxy -c -f /etc/haproxy/haproxy.cfg` | `Configuration file is valid` | [ ] |
| 14 | Redémarrer HAProxy | `sudo systemctl restart haproxy` | Service redémarré | [ ] |

---

### 🎯 **VÉRIFIER LE LOAD BALANCING (OBLIGATOIRE)**
```bash
# Tester l'alternance des Server name (10 requêtes)
for i in {1..10}; do 
  curl -s http://<IP_HAPROXY> | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//'; 
  echo "---";
done
```
**✅ Résultat attendu** : Alternance des `Server name` (ex: `faf376c0f0b1`, `3a8f2b1c4d5e`).
**💡 POURQUOI ?** OpenClassrooms **exige** cette vérification pour valider l'Exercice 3.

---

### 🛡️ **TESTER LA TOLÉRANCE AUX PANNES**
```bash
# 1. Arrêter un conteneur nginxdemos/hello (sur la VM backend 1)
ssh -i p5-key.pem ubuntu@<IP_VM1>
docker stop nginx-hello

# 2. Tester l'accès via HAProxy
for i in {1..5}; do 
  curl -s http://<IP_HAPROXY> | grep -o "Server name: [^<]*" | sed 's/Server name: //;s/<\/strong>//'; 
  echo "---";
done
```
**✅ Résultat attendu** : Toutes les requêtes sont servies par **le même conteneur** (celui qui est encore UP).

---

### ❓ **DÉPANNAGE PHASE 3**

| Problème | Cause | Solution |
|----------|-------|----------|
| `Configuration file is invalid` | Syntaxe HAProxy invalide | `sudo haproxy -c -f /etc/haproxy/haproxy.cfg` |
| `Connection refused` (port 80) | HAProxy non démarré | `sudo systemctl status haproxy` |
| `No server is available` | Serveurs backend non accessibles | Vérifiez les IPs privées dans `haproxy.cfg` |
| `Server name` ne change pas | Round Robin non activé | Vérifiez `balance roundrobin` dans `haproxy.cfg` |

---

### ✅ **VÉRIFICATION FINALE PHASE 3**
- [ ] 2 instances `nginxdemos/hello` déployées.
- [ ] VM HAProxy déployée et configurée.
- [ ] **Alternance des `Server name` vérifiée** (OBLIGATOIRE).
- [ ] Tolérance aux pannes testée.
- [ ] Fichier `haproxy.cfg` prêt à être livré.

**→ Si tout est validé, passez à la [Phase 4](#phase-4-livrables-1h).**

---

---

## 📌 **PHASE 4 : LIVRABLES (1h)**
*Objectif : Préparer les livrables conformes au format OpenClassrooms.*

---

### 📁 **STRUCTURE DU DOSSIER ZIP À LIVRER**
```
P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE.zip
├── Exercice_1/
│   ├── SEGUIN-CADICHE_Mathias_1_fichiers_terraform_<date>/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   └── SEGUIN-CADICHE_Mathias_1_playbook_ansible_<date>.yml
├── Exercice_2/
│   ├── SEGUIN-CADICHE_Mathias_2_dashboard_complet_<date>.png
│   ├── SEGUIN-CADICHE_Mathias_2_diagramme_donut_<date>.png
│   ├── SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_<date>.png
│   └── SEGUIN-CADICHE_Mathias_2_diagramme_histogramme_cumule_<date>.png
├── Exercice_3/
│   └── SEGUIN-CADICHE_Mathias_3_haproxy_cfg_<date>.cfg
├── SEGUIN-CADICHE_Mathias_journal_session_<date>.md
└── SEGUIN-CADICHE_Mathias_decisions_techniques_<date>.md
```

---

### 📋 **RÈGLES DE NOMMAGE (OBLIGATOIRE)**

| Type | Format | Exemple |
|------|--------|---------|
| **Dossier ZIP** | `P5_4091_Deployez_et_suivez_l_IaC_Nom_Prenom` | `P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE` |
| **Fichiers** | `Nom_Prenom_n°_du_livrable_nom_du_livrable_date` | `SEGUIN-CADICHE_Mathias_1_fichiers_terraform_02082026` |
| **Date** | `JJMMAAAA` | `02082026` (2 août 2026) |

---

### 📝 **GÉNÉRER LE ZIP DES LIVRABLES**
```bash
# 1. Créer les dossiers
mkdir -p Exercice_1 Exercice_2 Exercice_3

# 2. Copier les fichiers Terraform (Exercice 1)
cp -r terraform/exercice-1/* Exercice_1/SEGUIN-CADICHE_Mathias_1_fichiers_terraform_$(date +%d%m%Y)/
cp ansible/playbooks/deploy.yml Exercice_1/SEGUIN-CADICHE_Mathias_1_playbook_ansible_$(date +%d%m%Y).yml

# 3. Copier les captures (Exercice 2)
cp *.png Exercice_2/

# 4. Copier haproxy.cfg (Exercice 3)
cp terraform/exercice-3/haproxy.cfg Exercice_3/SEGUIN-CADICHE_Mathias_3_haproxy_cfg_$(date +%d%m%Y).cfg

# 5. Créer le ZIP
zip -r P5_4091_Deployez_et_suivez_l_IaC_Mathias_SEGUIN-CADICHE.zip Exercice_1/ Exercice_2/ Exercice_3/ SEGUIN-CADICHE_Mathias_*.md
```

---

### ⚠️ **FICHIERS À NE PAS LIVRER**
- ❌ `.tfvars` (contiennent vos clés AWS).
- ❌ Clés SSH privées (ex: `p5-key.pem`).
- ❌ Fichiers temporaires (ex: `access-policy.json`).

---

### ✅ **VÉRIFICATION FINALE PHASE 4**
- [ ] Dossier ZIP créé avec la bonne structure.
- [ ] Tous les fichiers sont nommés selon le format OpenClassrooms.
- [ ] 4 captures d'écran pour l'Exercice 2.
- [ ] Fichier `haproxy.cfg` inclus.
- [ ] Journal de session et décisions techniques remplis.

---

---

## 📌 **PHASE 5 : NETTOYAGE (30 min)**
*Objectif : Supprimer toutes les ressources AWS pour éviter des coûts inutiles.*

---

### 🧹 **NETTOYER LES RESSOURCES**
```bash
# Exercice 1 : Supprimer les VMs NGINX
cd 04_EXERCICES/01_TERRAFORM_ANSIBLE/
terraform destroy -auto-approve

# Exercice 2 : Supprimer le cluster OpenSearch
cd ../02_OPENSEARCH/
terraform destroy -auto-approve

# Exercice 3 : Supprimer la VM HAProxy
cd ../03_HAPROXY/
terraform destroy -auto-approve
```

---

### ✅ **VÉRIFIER LE NETTOYAGE**
```bash
# Vérifier qu'il n'y a plus de ressources
aws ec2 describe-instances --query "Reservations[].Instances[?State.Name=='running'].InstanceId" --output text
aws es list-domain-names
```
**✅ Résultat attendu** : Aucune ressource en cours d'exécution.

---

---

## 🎓 **APPROFONDISSEMENT (Optionnel)**

### 📚 **Pour aller plus loin après le projet**
- **Terraform** : Modules, workspaces, autres providers (Azure, GCP).
- **Ansible** : Rôles, templates Jinja2, collections.
- **OpenSearch** : Configuration avancée, alertes, index lifecycle.
- **Kibana** : Dashboards avancés, Machine Learning.
- **Docker** : Docker Swarm, Kubernetes.
- **CI/CD** : Jenkins, GitHub Actions, GitLab CI.
- **Monitoring** : Prometheus + Grafana.

---

## ❓ **FAQ (Questions Fréquentes)**

### 🔹 **Général**

| Question | Réponse |
|----------|---------|
| **Combien de temps pour finir le projet ?** | ~12-15h (réparti sur plusieurs jours). |
| **Puis-je utiliser une autre région AWS ?** | Non, **us-east-1 est obligatoire** pour ce projet. |
| **Combien ça coûte ?** | ~10-15€ si vous suivez les consignes (Free Tier pour les t2.micro). |
| **Puis-je utiliser Docker en local ?** | Non, ce guide se concentre sur **AWS uniquement**. |
| **Que faire si je suis bloqué ?** | Vérifiez les sections **Dépannage** ou demandez de l'aide. |

---

### 🔹 **Terraform**

| Question | Réponse |
|----------|---------|
| **Pourquoi `terraform plan` avant `apply` ?** | Pour éviter les mauvaises surprises (ex: suppression de ressources). |
| **Que faire si `terraform apply` échoue ?** | Vérifiez les erreurs, corrigez, puis relancez `terraform apply`. |
| **Comment supprimer une ressource ?** | `terraform destroy -target=aws_instance.nom_de_la_ressource`. |
| **Où sont stockés les states Terraform ?** | Dans `terraform.tfstate` (ne le supprimez pas !). |

---

### 🔹 **Ansible**

| Question | Réponse |
|----------|---------|
| **Pourquoi utiliser `--become` ?** | Pour exécuter les tâches en **root** (nécessaire pour NGINX). |
| **Comment tester la connexion Ansible ?** | `ansible all -i hosts_aws -m ping`. |
| **Que faire si une tâche échoue ?** | Vérifiez les logs avec `-vvv` : `ansible-playbook -i hosts_aws deploy.yml -vvv`. |
| **Comment exécuter une seule tâche ?** | `ansible-playbook -i hosts_aws deploy.yml --tags "nom_du_tag"`. |

---

### 🔹 **AWS**

| Question | Réponse |
|----------|---------|
| **Pourquoi us-east-1 ?** | C'est la région **obligatoire** pour ce projet (compatibilité avec les AMIs). |
| **Comment vérifier mes coûts AWS ?** | Allez dans **AWS Cost Explorer** ou utilisez `aws ce get-cost-and-usage`. |
| **Que faire si je dépasse le Free Tier ?** | Supprimez les ressources inutiles avec `terraform destroy`. |
| **Comment voir mes instances EC2 ?** | `aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId, PublicIpAddress, State.Name]" --output table`. |

---

## 📚 **RESSOURCES UTILES**

### 🔹 **Documentations Officielles**
- [Terraform](https://developer.hashicorp.com/terraform/docs)
- [Ansible](https://docs.ansible.com)
- [AWS EC2](https://docs.aws.amazon.com/ec2/)
- [OpenSearch](https://opensearch.org/docs/)
- [Kibana](https://www.elastic.co/guide/en/kibana/current/index.html)
- [HAProxy](https://www.haproxy.org/documentation/)
- [NGINX](https://nginx.org/en/docs/)
- [Angular](https://angular.io/docs)

---

### 🔹 **Tutoriels Recommandés**
- [Terraform pour débutants](https://learn.hashicorp.com/terraform)
- [Ansible pour débutants](https://docs.ansible.com/ansible/latest/user_guide/intro.html)
- [OpenSearch + Kibana](https://opensearch.org/docs/latest/opensearch/rest-api/)
- [Load Balancing avec HAProxy](https://www.haproxy.com/blog/haproxy-load-balancing-guide/)

---

## 🏆 **RÉSUMÉ DES COMPÉTENCES ACQUISES**

À la fin de ce projet, vous saurez :

✅ **Créer une infrastructure as code** avec Terraform.
✅ **Configurer des serveurs automatiquement** avec Ansible.
✅ **Déployer une application Angular** sur NGINX.
✅ **Centraliser et analyser des logs** avec OpenSearch + Kibana.
✅ **Mettre en place un load balancer** avec HAProxy.
✅ **Gérer un projet DevOps de A à Z** (déploiement, configuration, documentation, nettoyage).
✅ **Respecter les bonnes pratiques** (sécurité, coûts, documentation).

---

## 🎉 **FÉLICITATIONS !**

Vous avez maintenant **toutes les clés** pour réussir votre **Projet 5 OpenClassrooms** avec une **note maximale** !

💡 **Conseil final** :
- **Prenez votre temps** pour comprendre chaque étape.
- **Notez tout** dans votre journal de session.
- **Testez chaque commande** avant de passer à la suite.
- **Nettoyez toujours** vos ressources AWS à la fin.

---

**Guide créé spécialement pour Mathias SEGUIN-CADICHE**
**Dernière mise à jour** : 02/08/2026
**Version** : 2.0 (Aligné 100% avec OpenClassrooms)
**Compatibilité** : AWS (us-east-1) + Ubuntu 26.04
