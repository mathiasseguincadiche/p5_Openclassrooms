# 🚀 P5 - Déploiement d'Infrastructure-as-Code avec Terraform, Ansible et ELK

**Projet OpenClassrooms - Parcours DevOps**

---

## 🎯 **Introduction et Contexte**

### **Objectifs Pédagogiques**
Ce projet a pour but de vous former aux **bonnes pratiques DevOps** en vous faisant :
- ✅ **Comprendre** les concepts d'Infrastructure-as-Code (IaC)
- ✅ **Maîtriser** Terraform pour le provisionnement d'infrastructure
- ✅ **Automatiser** la configuration avec Ansible
- ✅ **Déployer** une stack ELK (OpenSearch) pour la centralisation des logs
- ✅ **Mettre en place** un Load Balancer avec HAProxy
- ✅ **Documenter** votre travail de manière professionnelle

### **Scénario du Projet**
Vous êtes **DevOps Engineer** dans une entreprise qui souhaite :
1. **Automatiser** le déploiement de son infrastructure AWS
2. **Centraliser** les logs de ses applications
3. **Équilibrer** la charge entre plusieurs serveurs web
4. **Garantir** la reproductibilité et la maintenabilité

---

## 📚 **Prérequis**

### **Compétences Requises**
- ⚠️ Connaissances de base en **Linux** (commandes CLI)
- ⚠️ Compréhension des concepts **réseau** (IP, DNS, ports)
- ⚠️ Notions de **virtualisation** et **cloud** (AWS)
- ⚠️ Expérience avec **Git** et GitHub

### **Outils Nécessaires**
| Outil | Version | Lien | Installation |
|-------|---------|------|--------------|
| **Terraform** | ≥ 1.5.x | [terraform.io](https://www.terraform.io) | `brew install terraform` |
| **Ansible** | ≥ 2.14.x | [ansible.com](https://www.ansible.com) | `pip install ansible` |
| **AWS CLI** | ≥ 2.x | [aws.amazon.com/cli](https://aws.amazon.com/cli) | `brew install awscli` |
| **OpenSearch** | 2.x | [opensearch.org](https://opensearch.org) | Docker/VM |
| **HAProxy** | ≥ 2.6 | [haproxy.org](https://www.haproxy.org) | `apt install haproxy` |
| **NGINX** | ≥ 1.23 | [nginx.org](https://nginx.org) | `apt install nginx` |
| **Git** | ≥ 2.x | [git-scm.com](https://git-scm.com) | `brew install git` |

### **Configuration AWS**
1. **Créer un compte AWS** (si ce n'est pas déjà fait)
2. **Configurer les credentials** :
   ```bash
   aws configure
   # AWS Access Key ID: [VOTRE_KEY]
   # AWS Secret Access Key: [VOTRE_SECRET]
   # Default region name: eu-west-3 (Paris)
   # Default output format: json
   ```
3. **Créer une paire de clés SSH** :
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/p5-key
   ```

### **Vérification de l'Environnement**
```bash
# Vérifier les versions installées
terraform --version
ansible --version
aws --version
git --version

# Vérifier la connectivité AWS
aws sts get-caller-identity
```

---

## 🏗️ **Architecture du Projet**

> ⚠️ **Voir le fichier détaillé** : [📄 02-architecture.md](./docs/02-architecture.md)

### **Schéma Global**
```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CLOUD AWS (VPC)                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────────┐  │
│  │   Client    │───▶│  HAProxy    │───▶│        NGINX Servers         │  │
│  │ (Utilisateur)│    │ (Load       │    │   (Exercice 1 - Ansible)      │  │
│  └─────────────┘    │  Balancer)   │    └─────────────┬───────────────┘  │
│                     └─────────────┘                  │                  │
│                                                          │                  │
│                     ┌─────────────────────────────────────────────────┐  │
│                     │                    OpenSearch                     │  │
│                     │   ┌─────────────┐    ┌─────────────────────────┐  │  │
│                     │   │  OpenSearch │◀───│   Logstash (Collecte)    │  │  │
│                     │   │   (Master)  │    └─────────────────────────┘  │  │
│                     │   └─────────────┘                                │  │
│                     │         │                                         │  │
│                     │   ┌─────────────┐    ┌─────────────────────────┐  │  │
│                     │   │  OpenSearch │    │   Filebeat (Sur chaque    │  │  │
│                     │   │   (Node)    │◀───│   serveur NGINX)          │  │  │
│                     │   └─────────────┘    └─────────────────────────┘  │  │
│                     │                                                 │  │
│                     │   ┌─────────────────────────────────────────┐  │  │
│                     │   │            Kibana (Visualisation)        │  │  │
│                     │   └─────────────────────────────────────────┘  │  │
│                     └─────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### **Légende**
| Composant | Rôle | Technologie |
|-----------|------|-------------|
| **HAProxy** | Load Balancer | HAProxy 2.6 |
| **NGINX** | Serveur Web | NGINX 1.23 |
| **OpenSearch** | Moteur de recherche/logs | OpenSearch 2.x |
| **Logstash** | Collecte et traitement des logs | ELK Stack |
| **Filebeat** | Agent de collecte de logs | Beats |
| **Kibana** | Interface de visualisation | OpenSearch Dashboards |

---

## 📖 **Structure du Dépôt**

```
p5_Openclassrooms/
├── README.md                          # 📌 Ce fichier
├── .gitignore                        # 🔒 Fichiers à ignorer
│
├── docs/                              # 📚 Documentation
│   ├── 01-introduction.md            # 🎯 Introduction détaillée
│   ├── 02-architecture.md            # 🏗️ Architecture complète
│   ├── 09-glossaire.md               # 📖 Définitions techniques
│   ├── 10-commandes-cli.md           # 💻 Récapitulatif CLI
│   │
│   ├── exercices/                    # 🔥 Exercices pratiques
│   │   ├── exercice-1-terraform-ansible-nginx.md
│   │   ├── exercice-2-opensearch.md
│   │   └── exercice-3-haproxy.md
│   │
│   ├── livrables/                    # 📦 Livrables à rendre
│   │   ├── journal-session.md         # 📝 Journal de session
│   │   ├── decisions.md              # ✅ Décisions techniques
│   │   ├── preuves-exercice-1.md      # 🎯 Preuves Exercice 1
│   │   ├── captures-exercice-2.md     # 📸 Captures Exercice 2
│   │   └── preuves-exercice-3.md      # 🎯 Preuves Exercice 3
│   │
│   └── references/                   # 🔗 Ressources utiles
│       └── liens-utiles.md
│
├── terraform/                        # ⛏️ Code Terraform
│   ├── modules/                      # 🧩 Modules réutilisables
│   │   ├── ec2/                      # Module EC2
│   │   ├── vpc/                      # Module VPC
│   │   ├── security-group/           # Module Security Groups
│   │   └── iam/                      # Module IAM
│   │
│   ├── exercice-1/                   # 🔥 Exercice 1
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   ├── exercice-2/                   # 🔥 Exercice 2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── exercice-3/                   # 🔥 Exercice 3
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── ansible/                          # 🎭 Playbooks Ansible
│   ├── roles/                        # 🎭 Rôles Ansible
│   │   ├── nginx/                    # Rôle NGINX
│   │   │   ├── tasks/
│   │   │   ├── handlers/
│   │   │   ├── templates/
│   │   │   └── vars/
│   │   │
│   │   ├── opensearch/               # Rôle OpenSearch
│   │   ├── logstash/                 # Rôle Logstash
│   │   ├── filebeat/                 # Rôle Filebeat
│   │   └── haproxy/                  # Rôle HAProxy
│   │
│   ├── playbooks/                    # 📜 Playbooks
│   │   ├── deploy-nginx.yml
│   │   ├── deploy-opensearch.yml
│   │   └── deploy-haproxy.yml
│   │
│   └── inventories/                  # 📋 Inventaires
│       ├── exercice-1.ini
│       ├── exercice-2.ini
│       └── exercice-3.ini
│
├── scripts/                          # 🐍 Scripts utilitaires
│   ├── setup-aws.sh                  # Configuration AWS
│   ├── test-connectivity.sh          # Test de connectivité
│   └── cleanup-all.sh                # 🧹 Nettoyage complet
│
└── captures/                         # 📸 Captures d'écran
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

---

## 🚀 **Par où commencer ?**

### **Ordre Recommandé**
1. **Lire** [01-introduction.md](./docs/01-introduction.md) pour comprendre le contexte
2. **Étudier** [02-architecture.md](./docs/02-architecture.md) pour visualiser le projet
3. **Commencer** par [Exercice 1 - Terraform + Ansible + NGINX](./docs/exercices/exercice-1-terraform-ansible-nginx.md)
4. **Poursuivre** avec [Exercice 2 - OpenSearch (ELK)](./docs/exercices/exercice-2-opensearch.md)
5. **Terminer** par [Exercice 3 - HAProxy](./docs/exercices/exercice-3-haproxy.md)
6. **Documenter** vos livrables dans `docs/livrables/`
7. **Vérifier** avec le [glossaire](./docs/09-glossaire.md) et les [commandes CLI](./docs/10-commandes-cli.md)

---

## 📞 **Support et Aide**

### **Ressources Officielles**
- [Documentation Terraform](https://developer.hashicorp.com/terraform/docs)
- [Documentation Ansible](https://docs.ansible.com)
- [Documentation AWS](https://docs.aws.amazon.com)
- [Documentation OpenSearch](https://opensearch.org/docs)

### **Communauté**
- [Forum OpenClassrooms](https://openclassrooms.com/forum)
- [Stack Overflow - Terraform](https://stackoverflow.com/questions/tagged/terraform)
- [Stack Overflow - Ansible](https://stackoverflow.com/questions/tagged/ansible)

---

## ⚠️ **Avertissements Importants**

1. **Coûts AWS** : Ce projet utilise des ressources AWS **payantes**. Pensez à :
   - Utiliser le **Free Tier** quand c'est possible
   - **Supprimer** toutes les ressources après utilisation
   - Voir [Nettoyage Final](./docs/references/nettoyage-final.md) pour la procédure

2. **Sécurité** :
   - Ne **jamais** commiter vos clés AWS dans Git
   - Utilisez toujours le **.gitignore** fourni
   - Limitez les permissions IAM au strict nécessaire

3. **Bonnes Pratiques** :
   - **Versionnez** votre code Terraform (Git)
   - **Testez** en local avant de déployer
   - **Documentez** chaque étape

---

## 🎓 **Compétences Acquises**

À la fin de ce projet, vous saurez :
- ✅ **Provisionner** une infrastructure cloud avec Terraform
- ✅ **Configurer** des serveurs avec Ansible
- ✅ **Déployer** une stack ELK complète
- ✅ **Mettre en place** un Load Balancer
- ✅ **Centraliser** et analyser des logs
- ✅ **Documenter** un projet technique
- ✅ **Estimer** les coûts cloud
- ✅ **Dépanner** des problèmes d'infrastructure

---

**Bonne chance dans votre apprentissage !** 💪

> *"Le code est de la poésie qui fonctionne."* — **Linus Torvalds**
