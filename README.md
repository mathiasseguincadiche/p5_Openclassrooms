# 🚀 Projet 5 OpenClassrooms : Déployez et suivez l'Infrastructure-as-Code grâce à Terraform, Ansible et un stack ELK

---

## 📌 **Présentation du Projet**

### **Contexte**
Ce projet s'inscrit dans le cadre de la **formation DevOps** d'OpenClassrooms. L'objectif est de **déployer une infrastructure complète en mode Infrastructure-as-Code (IaC)** et de **mettre en place un système de monitoring** pour suivre les performances et les logs.

### **Mission**
Vous allez :
1. **Déployer une infrastructure cloud** (AWS) avec Terraform.
2. **Configurer des serveurs** avec Ansible pour héberger une application Angular.
3. **Mettre en place un stack ELK** (Elasticsearch, Logstash, Kibana) pour centraliser et visualiser les logs.
4. **Configurer un load balancer** (HAProxy) pour répartir la charge entre plusieurs instances.

---

## 🛠️ **Outils Utilisés et Leurs Rôles**

| **Outil**       | **Rôle**                                                                                     | **Exercice**          |
|-----------------|---------------------------------------------------------------------------------------------|-----------------------|
| **Terraform**   | Déploiement de l'infrastructure cloud (VPC, EC2, Security Groups, etc.) en IaC.               | 1, 2, 3               |
| **Ansible**     | Configuration des serveurs (installation de NGINX, Node.js, Angular, etc.).                  | 1                     |
| **Docker**      | Conteneurisation des applications (nginxdemos/hello, OpenSearch, Kibana).                     | 2, 3                  |
| **OpenSearch**  | Moteur de recherche et d'analyse de logs (alternative open-source à Elasticsearch).           | 2                     |
| **Kibana**      | Interface de visualisation pour les logs et métriques (tableaux de bord).                    | 2                     |
| **Filebeat**    | Agent de collecte de logs (envoie les logs vers OpenSearch).                                | 2                     |
| **HAProxy**     | Load balancer pour répartir la charge entre plusieurs instances nginxdemos/hello.          | 3                     |
| **NGINX**       | Serveur web pour héberger l'application Angular.                                             | 1                     |
| **Angular**     | Framework frontend pour l'application web.                                                  | 1                     |

---

## 📊 **Schéma Global des Exercices**

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                                PROJET 5 : IaC + ELK                                │
├─────────────────────┬─────────────────────┬─────────────────────────────────┤
│   EXERCICE 1         │   EXERCICE 2         │         EXERCICE 3                │
│  Terraform + Ansible │ OpenSearch + Kibana  │      HAProxy + nginxdemos         │
│                     │                     │                                    │
│  ┌───────────────┐  │  ┌───────────────┐  │  ┌─────────────────────────────┐  │
│  │  Terraform    │  │  │  Terraform    │  │  │       Terraform              │  │
│  │  (VPC, EC2)   │──▶│  │  (OpenSearch) │  │  │  (2x nginxdemos/hello +      │  │
│  └───────────────┘  │  └───────────────┘  │  │        HAProxy)               │  │
│         │           │         │           │  │         │                    │  │
│  ┌───────────────┐  │  ┌───────────────┐  │  │  ┌─────────────────────────┐  │  │
│  │  Ansible      │  │  │  Docker       │  │  │  │   Docker (nginxdemos/hello)│  │  │
│  │  (NGINX +     │  │  │  (OpenSearch, │  │  │  │   + HAProxy                │  │  │
│  │   Angular)    │  │  │   Kibana)     │  │  │  └─────────────────────────┘  │  │
│  └───────────────┘  │  └───────────────┘  │  │         │                    │  │
│                     │         │           │  │  ┌─────────────────────────┐  │  │
│  ┌───────────────┐  │  ┌───────────────┐  │  │  │   HAProxy (Load Balancer) │  │  │
│  │  Application   │  │  │  Filebeat     │  │  │  │   (Port 80 + 8404/stats)   │  │  │
│  │  Angular       │  │  │  (Logs →     │  │  │  └─────────────────────────┘  │  │
│  └───────────────┘  │  │   OpenSearch) │  │  │                                    │  │
└─────────────────────┴─────────────────────┴─────────────────────────────────┘
     │                         │                              │
     ▼                         ▼                              ▼
┌─────────────────┐   ┌─────────────────┐            ┌─────────────────┐
│  Livrable 1      │   │  Livrable 2      │            │  Livrable 3      │
│  (Terraform +    │   │  (Kibana +       │            │  (HAProxy +      │
│   Ansible +      │   │   Dashboard)     │            │   nginxdemos)    │
│   Angular)       │   └─────────────────┘            └─────────────────┘
└─────────────────┘
```

---

## 📂 **Arborescence du Projet**

```
p5_Openclassrooms/
├── .gitignore                          # Fichiers à ignorer par Git
├── README.md                           # Ce guide
│
├── ansible/                            # Configuration Ansible
│   ├── files/                         # Fichiers statiques et configurations
│   │   ├── angular-app/                # Application Angular (Exercice 1)
│   │   │   ├── favicon.ico
│   │   │   └── index.html
│   │   └── nginx-angular.conf          # Configuration NGINX pour Angular
│   ├── inventories/                   # Inventaires Ansible
│   │   └── hosts_aws.example
│   └── playbooks/                     # Playbooks Ansible
│       └── deploy.yml                  # Déploiement NGINX + Angular (Exercice 1)
│
├── terraform/                          # Infrastructure as Code (Terraform)
│   ├── exercice-1/                     # Infrastructure de base (Exercice 1)
│   │   ├── main.tf                    # Ressources AWS (VPC, EC2, NGINX)
│   │   ├── variables.tf               # Variables configurables
│   │   └── outputs.tf                 # Sorties Terraform
│   ├── exercice-2/                     # Stack ELK (Exercice 2)
│   │   ├── main.tf                    # OpenSearch + Kibana
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── samples/                    # Échantillons de logs
│   │       └── nginx-access.log.sample
│   └── exercice-3/                     # Load Balancing (Exercice 3)
│       ├── main.tf                    # HAProxy + nginxdemos/hello
│       ├── variables.tf
│       └── outputs.tf
│
├── scripts/                            # Scripts d'automatisation pédagogique
│   ├── runbook.sh                      # Menu principal
│   ├── phase-0-preparation.sh          # Préparation de l'environnement
│   ├── phase-1-terraform-ansible.sh     # Exercice 1 : Terraform + Ansible
│   ├── phase-2-opensearch-kibana.sh    # Exercice 2 : OpenSearch + Kibana
│   ├── phase-3-haproxy.sh              # Exercice 3 : HAProxy + nginxdemos
│   ├── phase-4-livrables.sh            # Génération des livrables
│   ├── phase-5-nettoyage.sh            # Nettoyage des ressources AWS
│   └── utils/                          # Fonctions utilitaires
│       ├── colors.sh                   # Couleurs pour les logs
│       ├── prompts.sh                  # Invites utilisateur
│       ├── checks.sh                   # Vérifications
│       ├── health-checks.sh            # Vérifications de santé
│       ├── kibana-api.sh               # Interaction avec Kibana
│       ├── logging.sh                  # Journalisation
│       └── capture-screenshots.sh       # Capture d'écran pour Kibana
│
└── docs/                               # Documentation et livrables
    └── livrables/                      # Livrables OpenClassrooms (format officiel)
        ├── SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md
        ├── SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md
        ├── SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md
        ├── SEGUIN-CADICHE_Mathias_decisions_techniques.md
        └── SEGUIN-CADICHE_Mathias_journal_session.md
```

---

## 🚀 **Comment Lancer le Projet ?**

### **Prérequis**
- Un compte **AWS** (avec des droits IAM pour créer des ressources).
- **Terraform** installé (`>= 1.15.0`).
- **Ansible** installé (`>= 2.10`).
- **Docker** installé (pour les conteneurs OpenSearch, Kibana, nginxdemos/hello).
- **Git** installé.
- Une **paire de clés SSH** pour AWS (ex: `p5-key`).

---

### **Étapes de Déploiement**

#### 1️⃣ **Préparation de l'environnement**
```bash
# Cloner le dépôt
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms

# Configurer les variables Terraform (exemple pour exercice-1)
cd terraform/exercice-1
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs (aws_access_key, aws_secret_key, etc.)
```

#### 2️⃣ **Lancer les exercices via les scripts pédagogiques**
Les scripts dans `scripts/` vous guident **pas à pas** :

| **Script**                     | **Description**                                                                 | **Exercice** |
|-------------------------------|---------------------------------------------------------------------------------|--------------|
| `./scripts/runbook.sh`         | Menu interactif pour lancer tous les exercices.                                | 1, 2, 3      |
| `./scripts/phase-0-preparation.sh` | Préparation de l'environnement (installation des outils, vérifications).       | Tous         |
| `./scripts/phase-1-terraform-ansible.sh` | Déploiement de l'infrastructure + application Angular (Exercice 1).          | 1            |
| `./scripts/phase-2-opensearch-kibana.sh` | Déploiement du stack ELK + création du dashboard Kibana (Exercice 2).       | 2            |
| `./scripts/phase-3-haproxy.sh`  | Déploiement de HAProxy + nginxdemos/hello (Exercice 3).                         | 3            |
| `./scripts/phase-4-livrables.sh` | Génération automatique des livrables OpenClassrooms.                          | Tous         |
| `./scripts/phase-5-nettoyage.sh` | Nettoyage des ressources AWS pour éviter les coûts.                           | Tous         |

**Exemple pour lancer l'Exercice 1 :**
```bash
chmod +x scripts/*.sh scripts/utils/*.sh
./scripts/phase-1-terraform-ansible.sh --auto  # Mode automatique
# ou
./scripts/phase-1-terraform-ansible.sh       # Mode interactif (pédagogique)
```

#### 3️⃣ **Lancer manuellement (sans scripts)**
Si vous préférez tout faire manuellement :

**Exercice 1 : Terraform + Ansible + Angular**
```bash
# Déployer l'infrastructure avec Terraform
cd terraform/exercice-1
terraform init
terraform plan
terraform apply -auto-approve

# Configurer les serveurs avec Ansible
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

## 📜 **Livrables à Soumettre**

Les livrables sont **déjà générés** dans `docs/livrables/` au format requis par OpenClassrooms :

| **Livrable** | **Fichier** | **Contenu** |
|--------------|-------------|-------------|
| Exercice 1   | `SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md` | Description du déploiement Terraform + Ansible + Angular. |
| Exercice 2   | `SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md` | Description du stack ELK + captures Kibana. |
| Exercice 3   | `SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md` | Description de HAProxy + nginxdemos/hello. |
| Décisions techniques | `SEGUIN-CADICHE_Mathias_decisions_techniques.md` | Choix techniques (outils, architectures). |
| Journal de session | `SEGUIN-CADICHE_Mathias_journal_session.md` | Récapitulatif des actions et problèmes rencontrés. |

---

## 📚 **Documentation Complémentaire**

- **Terraform** : [Documentation officielle](https://developer.hashicorp.com/terraform/docs)
- **Ansible** : [Documentation officielle](https://docs.ansible.com/)
- **OpenSearch** : [Documentation officielle](https://opensearch.org/docs/)
- **Kibana** : [Documentation officielle](https://www.elastic.co/guide/en/kibana/current/index.html)
- **HAProxy** : [Documentation officielle](http://www.haproxy.org/documentation/)

---

## ⚠️ **Bonnes Pratiques et Avertissements**

### **Coûts AWS**
- Utilisez le **Free Tier** d'AWS pour éviter les coûts.
- **Nettoyez toujours** vos ressources après utilisation avec :
  ```bash
  ./scripts/phase-5-nettoyage.sh --auto
  # ou manuellement :
  cd terraform/exercice-1 && terraform destroy -auto-approve
  cd ../exercice-2 && terraform destroy -auto-approve
  cd ../exercice-3 && terraform destroy -auto-approve
  ```

### **Sécurité**
- Ne **jamais** commiter vos clés AWS dans Git.
- Utilisez des **variables d'environnement** ou `terraform.tfvars` (exclu via `.gitignore`).
- Limitez les droits IAM au strict minimum.

### **Dépannage**
- Si un script échoue, relisez les **logs** et vérifiez les **prérequis**.
- Consultez les **livrables** (`docs/livrables/`) pour des solutions aux problèmes courants.

---

## 🙏 **Remerciements et Contributions**

Ce projet a été réalisé dans le cadre de la **formation DevOps d'OpenClassrooms**.

**Auteur** : Mathias SEGUIN-CADICHE
**Date** : 02/08/2026

---

**✨ Bonne chance pour votre projet ! ✨**
