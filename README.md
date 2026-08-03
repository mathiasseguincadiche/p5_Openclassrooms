# 🚀 Projet 5 OpenClassrooms : Déployez et suivez l'Infrastructure-as-Code

**Pourquoi ce projet ?**
Ce projet vous permet de **maîtriser les outils DevOps essentiels** (Terraform, Ansible, ELK) en les appliquant à un cas concret :
→ **Déployer une infrastructure cloud** (AWS) **en 100% code** (IaC).
→ **Automatiser la configuration** de serveurs avec Ansible.
→ **Centraliser et visualiser les logs** avec un stack ELK (OpenSearch + Kibana).
→ **Équilibrer la charge** entre plusieurs serveurs avec HAProxy.

💡 **Ce que vous allez apprendre** :
- Comment **créer une infrastructure reproducible** avec Terraform.
- Comment **configurer des serveurs automatiquement** avec Ansible.
- Comment **monitorer une application** avec Kibana.

---

## 🛠️ Outils Utilisés

| **Catégorie**       | **Outil**       | **Rôle** | **Pourquoi ?** | **Exercice** |
|---------------------|-----------------|----------|----------------|--------------|
| 🏗️ **Infrastructure** | **Terraform** | Déploiement de l'infrastructure cloud (VPC, EC2, Security Groups) en **Infrastructure-as-Code**. | Pour **automatiser la création** de ressources AWS et éviter les erreurs manuelles. | 1, 2, 3 |
| 🎭 **Configuration** | **Ansible** | Configuration des serveurs (NGINX, Node.js, Angular) via des **playbooks**. | Pour **standardiser** la configuration et la reproduire à l'identique sur plusieurs machines. | 1 |
| 🐳 **Conteneurisation** | **Docker** | Conteneurisation des applications (OpenSearch, Kibana, nginxdemos/hello). | Pour **isoler** les applications et les déployer facilement. | 2, 3 |
| 🔍 **Monitoring** | **OpenSearch** | Moteur de recherche et d'analyse de logs. | Pour **stocker et analyser** les logs de l'application. | 2 |
| 📊 **Visualisation** | **Kibana** | Interface web pour créer des **tableaux de bord** et visualiser les logs. | Pour **comprendre** le trafic et les erreurs de l'application. | 2 |
| 📜 **Collecte de logs** | **Filebeat** | Agent léger qui envoie les logs vers OpenSearch. | Pour **centraliser** les logs de plusieurs serveurs. | 2 |
| ⚖️ **Load Balancing** | **HAProxy** | Répartit la charge entre plusieurs instances `nginxdemos/hello`. | Pour **améliorer la disponibilité** et la performance. | 3 |
| 🌐 **Serveur Web** | **NGINX** | Serveur web pour héberger l'application Angular. | Pour **servir** l'application frontend de manière optimisée. | 1 |
| 💻 **Frontend** | **Angular** | Framework pour construire l'application web. | Pour **créer une interface moderne** et dynamique. | 1 |

---

## 📊 Schéma des Exercices

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                     🎯 PROJET 5 : IaC + ELK (OpenClassrooms)                     │
├───────────────────────────────────────────────────────────────────────────────┤
│                                                                               │
│  🟢 EXERCICE 1 : Infrastructure + Application Angular                          │
│  ┌───────────────┐     ┌───────────────┐     ┌─────────────────┐               │
│  │  Terraform    │────▶│   Ansible     │────▶│   Application    │               │
│  │ (VPC, EC2)    │     │ (NGINX,       │     │   Angular        │               │
│  └───────────────┘     │  Node.js)     │     └─────────────────┘               │
│                        └───────────────┘                                       │
│                                                                               │
│  🟡 EXERCICE 2 : Stack ELK (Logs + Monitoring)                                 │
│  ┌───────────────┐     ┌───────────────┐     ┌─────────────────┐               │
│  │  Terraform    │────▶│   Docker      │────▶│   OpenSearch    │               │
│  │ (OpenSearch)  │     │ (OpenSearch,  │     │   (Logs)         │               │
│  └───────────────┘     │   Kibana)     │     └─────────────────┘               │
│                        └───────────────┘                                       │
│                              │                                                 │
│                              ▼                                                 │
│                        ┌─────────────────┐                                       │
│                        │   Kibana        │                                       │
│                        │ (Dashboard)     │                                       │
│                        └─────────────────┘                                       │
│                                                                               │
│  🔴 EXERCICE 3 : Load Balancing avec HAProxy                                  │
│  ┌───────────────┐     ┌─────────────────────────────┐                        │
│  │  Terraform    │────▶│       Docker (2x)           │                        │
│  │ (HAProxy +    │     │   ┌─────────────────┐       │                        │
│  │  2x EC2)      │────▶│   │ nginxdemos/hello │       │                        │
│  └───────────────┘     │   └─────────────────┘       │                        │
│                        └─────────────────────────────┘                        │
│                              │                                                 │
│                              ▼                                                 │
│                        ┌─────────────────┐                                       │
│                        │   HAProxy        │                                       │
│                        │ (Port 80 + 8404) │                                       │
│                        └─────────────────┘                                       │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

**Légende** :
- 🟢 = Exercice 1 (Terraform + Ansible + Angular)
- 🟡 = Exercice 2 (Terraform + Docker + OpenSearch + Kibana)
- 🔴 = Exercice 3 (Terraform + Docker + HAProxy + nginxdemos/hello)
- `────▶` = Déploiement/Configuration
- `│` = Dépendance

---

## 📂 Arborescence du Projet

```
p5_Openclassrooms/
├── .gitignore                          # 🗑️ Fichiers à ignorer par Git
├── README.md                           # 📖 Ce guide (vous êtes ici !)
│
├── 📦 ansible/                          # 🎭 Tout ce qui concerne Ansible
│   ├── 📁 files/                         # 📄 Fichiers statiques et configurations
│   │   ├── 📁 angular-app/                # 🌐 Application Angular (Exercice 1)
│   │   │   ├── favicon.ico
│   │   │   └── index.html
│   │   └── nginx-angular.conf          # ⚙️ Configuration NGINX pour Angular
│   ├── 📁 inventories/                   # 📋 Inventaires Ansible
│   │   └── hosts_aws.example
│   └── 📁 playbooks/                     # 🎬 Playbooks Ansible
│       └── deploy.yml                  # 🚀 Déploiement NGINX + Angular (Exercice 1)
│
├── 🏗️ terraform/                          # 🏗️ Infrastructure as Code (Terraform)
│   ├── 📁 exercice-1/                     # 1️⃣ Infrastructure de base (VPC, EC2, NGINX)
│   │   ├── main.tf                    # 📜 Ressources AWS
│   │   ├── variables.tf               # 🔧 Variables configurables
│   │   └── outputs.tf                 # 📤 Sorties Terraform
│   ├── 📁 exercice-2/                     # 2️⃣ Stack ELK (OpenSearch + Kibana)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── 📁 samples/                    # 📄 Échantillons de logs
│   │       └── nginx-access.log.sample
│   └── 📁 exercice-3/                     # 3️⃣ Load Balancing (HAProxy + nginxdemos/hello)
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── 🤖 scripts/                            # 🤖 Scripts d'automatisation pédagogique
│   ├── runbook.sh                      # 🎯 Menu principal (point d'entrée)
│   ├── phase-0-preparation.sh          # 🛠️ Préparation de l'environnement
│   ├── phase-1-terraform-ansible.sh     # 1️⃣ Exercice 1 : Terraform + Ansible
│   ├── phase-2-opensearch-kibana.sh    # 2️⃣ Exercice 2 : OpenSearch + Kibana
│   ├── phase-3-haproxy.sh              # 3️⃣ Exercice 3 : HAProxy + nginxdemos
│   ├── phase-4-livrables.sh            # 📝 Génération des livrables
│   ├── phase-5-nettoyage.sh            # 🧹 Nettoyage des ressources AWS
│   └── 📁 utils/                          # 🔧 Fonctions utilitaires
│       ├── colors.sh
│       ├── prompts.sh
│       ├── checks.sh
│       ├── health-checks.sh
│       ├── kibana-api.sh
│       ├── logging.sh
│       └── capture-screenshots.sh
│
└── 📚 docs/                               # 📚 Documentation et livrables
    └── 📁 livrables/                      # 📄 Livrables OpenClassrooms (format officiel)
        ├── SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md
        ├── SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md
        ├── SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md
        ├── SEGUIN-CADICHE_Mathias_decisions_techniques_02082026.md
        └── SEGUIN-CADICHE_Mathias_journal_session_02082026.md
```

---

## 🚀 Comment Lancer le Projet ? (Guide pour Débutants)

### ⚠️ Prérequis Obligatoires
Avant de commencer, assurez-vous d'avoir installé :

| **Outil** | **Version** | **Lien d'installation** | **Vérification** |
|----------|-------------|--------------------------|------------------|
| Git | >= 2.0 | [git-scm.com](https://git-scm.com/) | `git --version` |
| Terraform | >= 1.15.0 | [terraform.io](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) | `terraform --version` |
| Ansible | >= 2.10 | [ansible.com](https://docs.ansible.com/ansible/latest/installation_guide/index.html) | `ansible --version` |
| Docker | >= 20.10 | [docker.com](https://docs.docker.com/get-docker/) | `docker --version` |
| AWS CLI | >= 2.0 | [aws.amazon.com/cli](https://aws.amazon.com/cli/) | `aws --version` |
| Un compte AWS | Free Tier | [aws.amazon.com](https://aws.amazon.com/) | ✅ Créé et configuré |

---

### 📥 Étape 1 : Cloner le Projet
```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```
✅ **Vérifiez** : Vous êtes dans le dossier `p5_Openclassrooms/`.

---

### ⚙️ Étape 2 : Configurer AWS (OBLIGATOIRE)

1. **Créer une paire de clés SSH** (si ce n'est pas déjà fait) :
   ```bash
   ssh-keygen -t rsa -b 4096 -f p5-key
   ```
   → **Ne pas oublier** de l'importer dans AWS (EC2 > Key Pairs > Import Key Pair).

2. **Configurer les identifiants AWS** :
   - **Option 1** : Variables d'environnement (recommandé) :
     ```bash
     export AWS_ACCESS_KEY_ID="votre_access_key"
     export AWS_SECRET_ACCESS_KEY="votre_secret_key"
     export AWS_DEFAULT_REGION="us-east-1"
     ```
   - **Option 2** : Fichier `~/.aws/credentials` :
     ```ini
     [default]
     aws_access_key_id = votre_access_key
     aws_secret_access_key = votre_secret_key
     ```

> ⚠️ **⚠️ ATTENTION : SÉCURITÉ**
> - **Ne jamais commiter** vos clés AWS dans Git !
> - Utilisez le **Free Tier** pour éviter les coûts (2 VMs t2.micro = gratuit).

---

### 🌍 Étape 3 : Lancer un Exercice (2 Méthodes)

#### 🎯 Méthode 1 : Avec les Scripts Pédagogiques (Recommandé pour les débutants)
Les scripts vous guident **pas à pas** et expliquent chaque étape.

```bash
# 1. Donner les permissions aux scripts
chmod +x scripts/*.sh scripts/utils/*.sh

# 2. Lancer le menu principal
./scripts/runbook.sh

# 3. Choisir un exercice (ex: 1 pour l'Exercice 1)
#    → Le script vous guidera !
```

**Exemple pour l'Exercice 1** :
```bash
./scripts/phase-1-terraform-ansible.sh --auto  # Mode automatique (rapide)
# ou
./scripts/phase-1-terraform-ansible.sh       # Mode interactif (pédagogique)
```

#### 🛠️ Méthode 2 : Manuellement (Pour comprendre en détail)

**Exercice 1 : Terraform + Ansible + Angular**
```bash
# 1. Aller dans le dossier Terraform
cd terraform/exercice-1

# 2. Initialiser Terraform
terraform init

# 3. Voir le plan (optionnel)
terraform plan

# 4. Appliquer les changements
terraform apply -auto-approve

# 5. Configurer les serveurs avec Ansible
cd ../..
ansible-playbook -i terraform/exercice-1/hosts_aws.example ansible/playbooks/deploy.yml
```

**Exercice 2 : OpenSearch + Kibana + Filebeat**
```bash
cd terraform/exercice-2
terraform init
terraform apply -auto-approve
# Suivre les instructions pour configurer Filebeat et Kibana
```

**Exercice 3 : HAProxy + nginxdemos/hello**
```bash
cd terraform/exercice-3
terraform init
terraform apply -auto-approve
# HAProxy et nginxdemos/hello seront déployés automatiquement via user_data
```

---

### 🧹 Étape 4 : Nettoyer les Ressources (IMPORTANT !)

> ⚠️ **⚠️ ATTENTION : COÛTS AWS ⚠️**
> - **1 VM t2.micro** = Gratuit pendant 12 mois (750h/mois).
> - **2 VMs t2.micro** = Toujours gratuit (si vous restez dans les limites).
> - **Nettoyez TOUJOURS** après utilisation pour éviter les coûts.

```bash
# Méthode 1 : Avec le script (recommandé)
./scripts/phase-5-nettoyage.sh --auto

# Méthode 2 : Manuellement (pour chaque exercice)
cd terraform/exercice-1 && terraform destroy -auto-approve
cd ../exercice-2 && terraform destroy -auto-approve
cd ../exercice-3 && terraform destroy -auto-approve
```

---

## 📜 Livrables à Soumettre

Tous les livrables sont **déjà générés** dans `docs/livrables/` au **format officiel OpenClassrooms** (`NOM_PRENOM_n°_description_date.md`).

| **Livrable** | **Fichier** | **Contenu** | **Exercice** | **Lien** |
|--------------|-------------|-------------|--------------|----------|
| **Exercice 1** | `SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md` | Description du déploiement Terraform + Ansible + Angular. | 1 | [Voir](docs/livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| **Exercice 2** | `SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md` | Description du stack ELK + captures Kibana. | 2 | [Voir](docs/livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| **Exercice 3** | `SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md` | Description de HAProxy + nginxdemos/hello. | 3 | [Voir](docs/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |
| **Décisions Techniques** | `SEGUIN-CADICHE_Mathias_decisions_techniques_02082026.md` | Choix techniques (outils, architectures). | Tous | [Voir](docs/livrables/SEGUIN-CADICHE_Mathias_decisions_techniques_02082026.md) |
| **Journal de Session** | `SEGUIN-CADICHE_Mathias_journal_session_02082026.md` | Récapitulatif des actions et problèmes rencontrés. | Tous | [Voir](docs/livrables/SEGUIN-CADICHE_Mathias_journal_session_02082026.md) |

💡 **Conseil** :
- **Relisez chaque livrable** avant soumission pour vous assurer qu'il est complet.
- **Vérifiez les captures d'écran** dans l'Exercice 2 (Kibana).

---

## 📚 Ressources et Documentation

### 📖 Documentation Officielle
| **Outil** | **Lien** | **Description** |
|----------|----------|-----------------|
| Terraform | [Documentation](https://developer.hashicorp.com/terraform/docs) | Guide officiel pour Terraform. |
| Ansible | [Documentation](https://docs.ansible.com/) | Guide officiel pour Ansible. |
| OpenSearch | [Documentation](https://opensearch.org/docs/) | Guide officiel pour OpenSearch. |
| Kibana | [Documentation](https://www.elastic.co/guide/en/kibana/current/index.html) | Guide officiel pour Kibana. |
| HAProxy | [Documentation](http://www.haproxy.org/documentation/) | Guide officiel pour HAProxy. |

### 🎓 Tutoriels Recommandés
- [Terraform pour Débutants](https://learn.hashicorp.com/terraform)
- [Ansible pour Débutants](https://docs.ansible.com/ansible/latest/user_guide/index.html)
- [Docker pour Débutants](https://docs.docker.com/get-started/)

---

## ⚠️ Bonnes Pratiques et Dépannage

> ⚠️ **⚠️ ATTENTION : COÛTS AWS ⚠️**
> - **Utilisez le Free Tier** pour éviter les coûts.
> - **1 VM t2.micro** = Gratuit pendant 12 mois (750h/mois).
> - **2 VMs t2.micro** = Toujours gratuit (si vous restez dans les limites).
> - **Nettoyez TOUJOURS** après utilisation avec `./scripts/phase-5-nettoyage.sh --auto`.

---

### 🔐 Sécurité
- **Ne jamais commiter** vos clés AWS dans Git (utilisez `.gitignore`).
- **Limitez les droits IAM** : Donnez uniquement les permissions nécessaires.
- **Utilisez des variables d'environnement** pour les secrets :
  ```bash
  export AWS_ACCESS_KEY_ID="votre_clé"
  export AWS_SECRET_ACCESS_KEY="votre_secret"
  ```

---

### 🐛 Dépannage Courant

| **Problème** | **Cause Probable** | **Solution** |
|--------------|--------------------|--------------|
| `terraform apply` échoue | Identifiants AWS incorrects | Vérifiez `~/.aws/credentials` ou les variables d'environnement. |
| Ansible ne se connecte pas | Clé SSH manquante ou mauvaise | Vérifiez `ansible/playbooks/deploy.yml` et `hosts_aws.example`. |
| Kibana ne s'affiche pas | OpenSearch non démarré | Vérifiez `docker ps` sur le serveur OpenSearch. |
| HAProxy ne redirige pas | Mauvaises IPs dans la config | Vérifiez `terraform/exercice-3/main.tf` (user_data). |
| Coûts AWS inattendus | Ressources non supprimées | Lancez `./scripts/phase-5-nettoyage.sh --auto`. |

---

## 🙏 Remerciements et Contributions

Merci d'avoir consulté ce projet ! 🎉

**Auteur** : [Mathias SEGUIN-CADICHE](https://github.com/mathiasseguincadiche)
**Date** : 02/08/2026
**Projet** : P5 OpenClassrooms - Déployez et suivez l'Infrastructure-as-Code

---

### 🌟 Badges
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/ansible-%23EE0000.svg?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![OpenSearch](https://img.shields.io/badge/OpenSearch-%23005EB8.svg?style=for-the-badge&logo=opensearch&logoColor=white)

---
**✨ Bonne chance pour votre projet DevOps ! ✨**
