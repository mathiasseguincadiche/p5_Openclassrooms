# 🚀 Projet P5 OpenClassrooms - Déployer et suivre l'infrastructure as code

**Guide Pédagogique Ultime avec Logique, Explications et Commandes Commentées**

---

## 📌 À propos de ce guide

Ce document est votre **compagnon ultime** pour réussir votre **Projet 5 OpenClassrooms (4091)** :
> **"Déployer et suivre l'infrastructure as code grâce à Terraform, Ansible et la stack ELK"**

✅ **100% orienté débutant** – Explications claires, sans jargon, avec des analogies pour tout comprendre.
✅ **100% pratique** – Commandes à copier-coller, résultats attendus, vérifications à chaque étape.
✅ **100% pédagogique** – Pour chaque action : **LE QUOI, LE POURQUOI, LE COMMENT**.
✅ **100% reproductible** – Vous pourrez refaire ce projet n'importe quand, même dans 6 mois.

💡 **Ce guide est conçu pour que vous COMPRENIEZ, pas juste que vous EXÉCUTEZ.**
Chaque concept est vulgarisé, chaque commande est expliquée, chaque étape a un but clair.

---

## 🎯 SOMMAIRE (Suivez ce plan pour ne rien oublier !)

| Partie | Titre | Durée | Fichier |
|--------|-------|-------|--------|
| 0 | Introduction et Prérequis | 30 min | [Lire](#-0-introduction-et-prérequis) |
| 1 | Architecture du Projet | 20 min | [Lire](#-1-architecture-du-projet) |
| 2 | Exercice 1 : Terraform + Ansible (NGINX) | 4-5h | [docs/exercices/exercice-1.md](docs/exercices/exercice-1.md) |
| 3 | Exercice 2 : OpenSearch (ELK) | 3-4h | [docs/exercices/exercice-2.md](docs/exercices/exercice-2.md) |
| 4 | Exercice 3 : HAProxy (Load Balancer) | 2-3h | [docs/exercices/exercice-3.md](docs/exercices/exercice-3.md) |
| 5 | Livrables à rendre | 1h | [docs/livrables/](docs/livrables/) |
| 6 | Nettoyage Final | 30 min | [scripts/cleanup-all.sh](scripts/cleanup-all.sh) |
| 7 | Glossaire | 15 min | [docs/09-glossaire.md](docs/09-glossaire.md) |
| 8 | Commandes CLI | 10 min | [docs/10-commandes-cli.md](docs/10-commandes-cli.md) |

---

## 🎯 0. INTRODUCTION ET PRÉREQUIS

### 📚 Contexte du Projet

**Pourquoi ce projet ?**
En tant que **DevOps/Ingénieur Cloud**, votre rôle est de :
- ✅ **Automatiser** la création et la configuration des infrastructures (serveurs, bases de données, réseaux).
- ✅ **Garantir** que tout est reproductible, fiable et scalable.
- ✅ **Surveiller** et optimiser les performances.
- ✅ **Documenter** votre travail pour que d'autres puissent le comprendre.

Ce projet vous fait pratiquer ces compétences en déployant :
- **2 serveurs web (NGINX)** avec Terraform + Ansible
- **1 cluster OpenSearch** (pour les logs) avec Terraform
- **1 load balancer (HAProxy)** pour répartir le trafic

→ **C'est un projet REALISTE** qui reproduit ce que vous ferez en entreprise !

---

### 🎯 Objectifs Pédagogiques

| Objectif | Compétence acquise | Outils |
|----------|-------------------|-------|
| Déployer une infrastructure automatiquement | Maîtriser l'Infrastructure as Code (IaC) | Terraform |
| Configurer des serveurs à distance | Maîtriser le Configuration Management | Ansible |
| Déployer une base de données NoSQL | Comprendre OpenSearch/ELK | Terraform, OpenSearch |
| Répartir la charge entre serveurs | Maîtriser le Load Balancing | HAProxy |
| Gérer un projet de A à Z | Organiser son travail, documenter | Git, Markdown |

---

### 📋 Prérequis Matériels et Logiciels

#### ✅ Ce que vous devez AVOIR

| Prérequis | Commande de vérification | Solution si manquant | Obligatoire |
|-----------|--------------------------|----------------------|-------------|
| **Fedora 44 (Cosmic ou KDE)** | `cat /etc/os-release` | Installez Fedora 44 | ⭐⭐⭐⭐⭐ |
| **KVM/QEMU/libvirt** | `virsh list --all` | `sudo dnf install -y qemu-kvm libvirt virt-install virt-manager` | ⭐⭐⭐⭐⭐ |
| **VM vm-devops (Ubuntu 26.04)** | `ssh devops@<IP>` | Créez-la avec virt-manager (4 Go RAM, 2 vCPU, 20 Go disque) | ⭐⭐⭐⭐⭐ |
| **Compte AWS** | `aws sts get-caller-identity` | Créez un compte AWS | ⭐⭐⭐⭐⭐ |
| **Clés AWS (Access Key + Secret Key)** | `aws configure` | Créez-les dans IAM > Security Credentials | ⭐⭐⭐⭐⭐ |
| **Git** | `git --version` | `sudo dnf install -y git` (Fedora) / `sudo apt install -y git` (Ubuntu) | ⭐⭐⭐⭐ |
| **GitHub** | Compte + dépôt privé | Créez un compte GitHub | ⭐⭐⭐⭐ |

---

### ⚠️ IMPORTANT

🔴 **Région AWS : `us-east-1` (OBLIGATOIRE pour le projet)**.

💰 **Budget : Prévois 20€ max** (le projet ne devrait pas dépasser 10-15€ si vous suivez les consignes).

🆓 **Free Tier AWS** : Utilisez des instances **t2.micro** (gratuites pendant 12 mois pour les nouveaux comptes).

---

### 💡 Conseils avant de commencer

🔹 **Ne modifiez pas** les fichiers du pack original → Travaillez dans une copie.

🔹 **Ne commitez JAMAIS** dans Git :
- Les fichiers `.tfvars` (contiennent vos clés AWS)
- Les clés SSH privées (ex : `p5-key.pem`)
- Les outputs Terraform sensibles

🔹 **Vérifiez toujours** avec `terraform plan` avant `terraform apply`.

🔹 **Ne sautez jamais** un point **STOP** dans les runbooks.

🔹 **Notez toutes vos actions** dans un journal de bord (pour les livrables).

---

## 🏗️ 1. ARCHITECTURE DU PROJET

### 🗺️ Schéma Global (Comment tout s'emboîte)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              TA MACHINE (Fedora 44 Cosmic)                                      │
│                                                                                                     │
│  ┌─────────────────┐                                                                                 │
│  │   KVM/QEMU      │    ┌─────────────────────────────────────────────────────────────────┐  │
│  │  (Hyperviseur)   │    │                     vm-devops (Ubuntu 26.04)                     │  │
│  └─────────────────┘    │  ┌─────────────┐  ┌─────────────┐  ┌───────────────────────┐  │  │
│         │               │  │ Terraform   │  │   Ansible   │  │       AWS CLI         │  │  │
│         │               │  │ (IaC)       │  │ (Config)    │  │ (Gestion AWS)         │  │  │
│         │               │  └─────────────┘  └─────────────┘  └───────────────────────┘  │  │
│         │               └─────────────────────────────────────────────────────────────────┘  │
│         │                                                                                     │
│         ▼                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐  │
│  │                                AWS (us-east-1)                                        │  │
│  │                                                                                     │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐               │  │
│  │  │  EXERCICE 1:     │    │  EXERCICE 2:     │    │  EXERCICE 3:     │               │  │
│  │  │  2 VMs NGINX     │    │  OpenSearch      │    │  1 VM HAProxy    │               │  │
│  │  │  (t2.micro)      │    │  (t3.medium)     │    │  (t2.micro)      │               │  │
│  │  │                 │    │                 │    │                 │               │  │
│  │  │  ┌───────────┐  │    │  ┌───────────┐  │    │  ┌───────────┐  │               │  │
│  │  │  │  NGINX    │  │    │  │OpenSearch│  │    │  │ HAProxy  │──┼──────────▶  │  │
│  │  │  │ (Site Web)│  │    │  │ (Logs)    │  │    │  │(Load Bal.)│  │  │ Utilisateurs │
│  │  │  └───────────┘  │    │  └───────────┘  │    │  └───────────┘  │  │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### 📊 Légende du Schéma

| Élément | Rôle | Analogie | Outils |
|---------|------|----------|-------|
| **Fedora 44 (KVM)** | Machine hôte qui fait tourner des VMs locales | Atelier où vous construisez des maquettes | KVM, QEMU, libvirt |
| **vm-devops** | VM locale où vous exécutez Terraform/Ansible | Bureau dédié à votre projet | Ubuntu 26.04 |
| **AWS (us-east-1)** | Cloud où vous déploiez vos infrastructures | Terrain où vous construisez votre maison | AWS CLI |
| **Terraform** | Crée des infrastructures (VMs, réseaux, etc.) | Plan de construction pour une maison | Terraform |
| **Ansible** | Configure les serveurs (installe NGINX, etc.) | Manuel d'instructions pour meubler votre maison | Ansible |
| **NGINX** | Serveur web qui affiche un site | Meubles de votre maison | NGINX |
| **OpenSearch** | Base de données pour stocker et rechercher des logs | Système de rangement intelligent | OpenSearch |
| **HAProxy** | Load Balancer qui répartit le trafic | Réceptionniste qui dirige les visiteurs | HAProxy |

---

### 🔄 Flux de Travail (Workflow)

```
┌─────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Début   │────▶│ Préparer        │────▶│ Exercice 1:      │────▶│ Exercice 2:      │
└─────────┘     │ l'environnement   │     │ Terraform +     │     │ OpenSearch       │
                └─────────────────┘     │ Ansible          │     └─────────────────┘
                                              └─────────────────┘              │
                                                                               ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Exercice 3:      │────▶│ Collecter les   │────▶│ Nettoyer AWS    │────▶│ Rendre les      │
│ HAProxy         │     │ preuves          │     │                 │     │ livrables       │
└─────────────────┘     └─────────────────┘     └─────────────────┘     └─────────────────┘
```

---

### 📌 Résumé des Ressources AWS

| Exercice | Ressource | Type | Coût estimé | Durée |
|----------|-----------|------|-------------|-------|
| 1 | 2 VMs NGINX | t2.micro | ~0.02€/h (x2) | 4-5h |
| 2 | 1 Cluster OpenSearch | t3.medium.search | ~0.10€/h | 3-4h |
| 3 | 1 VM HAProxy | t2.micro | ~0.02€/h | 2-3h |
| **Total** | - | - | **~0.14€/h** | **~12h → ~1.68€** |

✅ **Avec le Free Tier AWS (12 mois gratuits)** :
- Les **t2.micro** sont gratuites (750h/mois).
- OpenSearch n'est pas gratuit, mais le projet est conçu pour limiter les coûts (1 cluster pendant 3-4h max).
- **Total estimé : 10-15€ max** (si vous suivez les consignes).

---

## 🔥 EXERCICES PRATIQUES

### 📚 [Exercice 1 : Terraform + Ansible (NGINX)](docs/exercices/exercice-1.md)
**Durée** : 4-5h
**Objectif** : Déployer 2 serveurs web NGINX avec Terraform et les configurer avec Ansible.

---

### 🔍 [Exercice 2 : OpenSearch (ELK)](docs/exercices/exercice-2.md)
**Durée** : 3-4h
**Objectif** : Déployer un cluster OpenSearch pour centraliser et analyser les logs.

---

### 🌐 [Exercice 3 : HAProxy (Load Balancer)](docs/exercices/exercice-3.md)
**Durée** : 2-3h
**Objectif** : Déployer un Load Balancer HAProxy devant les serveurs NGINX.

---

## 📦 LIVRABLES À RENDRE

Tous les modèles de livrables sont disponibles dans [docs/livrables/](docs/livrables/) :
- 📝 [journal-session.md](docs/livrables/journal-session.md) - Modèle pour votre journal de session
- ✅ [decisions.md](docs/livrables/decisions.md) - Modèle pour documenter vos décisions techniques
- 🎯 [preuves-exercice-1.md](docs/livrables/preuves-exercice-1.md) - Modèle pour les preuves de l'Exercice 1
- 📸 [captures-exercice-2.md](docs/livrables/captures-exercice-2.md) - Modèle pour les captures de l'Exercice 2
- 🎯 [preuves-exercice-3.md](docs/livrables/preuves-exercice-3.md) - Modèle pour les preuves de l'Exercice 3

---

## 🧹 NETTOYAGE FINAL

Un script est disponible pour supprimer toutes les ressources AWS :
```bash
./scripts/cleanup-all.sh
```

⚠️ **Attention** : Ce script est **destructif et irréversible** !

---

## 📖 DOCUMENTATION COMPLÉMENTAIRE

- 📖 [Glossaire Technique](docs/09-glossaire.md) - 100+ termes expliqués
- 💻 [Récapitulatif des Commandes CLI](docs/10-commandes-cli.md) - Toutes les commandes essentielles

---

## 🙏 REMERCIEMENTS ET CONSEILS FINAUX

### 💡 Conseils pour réussir votre projet

📌 **Suivez l'ordre des exercices** : Exercice 1 → Exercice 2 → Exercice 3.
✅ **Vérifiez à chaque étape** : Utilisez les commandes de vérification fournies.
📝 **Notez tout dans votre journal de bord** : Ça vous fera gagner du temps pour les livrables.
🔍 **Ne restez pas bloqué** : Si une commande échoue, consultez la section Dépannage ou demandez de l'aide.
💰 **Surveillez vos coûts AWS** : Utilisez `aws ec2 describe-instances` pour voir vos VMs en cours.
🧹 **Nettoyez toujours à la fin** : `terraform destroy` pour tous les exercices.

---

### 🎯 Ce que vous saurez faire après ce projet

✅ Créer une infrastructure as code avec Terraform.
✅ Configurer des serveurs automatiquement avec Ansible.
✅ Déployer une base de données NoSQL (OpenSearch).
✅ Mettre en place un load balancer avec HAProxy.
✅ Gérer un projet DevOps de A à Z (déploiement, configuration, documentation, nettoyage).

---

### 🚀 Prochaines étapes (après le projet)

- Approfondissez Terraform : Modules, workspaces, autres providers (Azure, GCP).
- Approfondissez Ansible : Rôles, templates Jinja2, collections.
- Découvrez Docker et Kubernetes pour la conteneurisation et l'orchestration.
- Explorez le monitoring avec Prometheus + Grafana.
- Automatisez vos déploiements avec Jenkins ou GitHub Actions (CI/CD).

---

✅ **Vous avez maintenant TOUT ce qu'il faut pour réussir votre Projet 5 !**

🚀 **Bonne chance, et amusez-vous bien en apprenant !**

---

**Guide créé spécialement pour Mathias SEGUIN-CADICHE**
**Dernière mise à jour** : 02/08/2026
**Version** : 1.0
**Compatibilité** : Pack P5_OC_4091_PACK_COMPLET_V4_3_KVM + Fedora 44 Cosmic
