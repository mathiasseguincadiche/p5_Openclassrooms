# 🚀 P5 OpenClassrooms - Projet DevOps

**Bienvenue dans le dépôt du projet P5 OpenClassrooms !**
Ce dépôt est conçu pour vous accompagner dans votre apprentissage des **outils DevOps** et des **bonnes pratiques** en infrastructure et automatisation. Que vous soyez débutant ou que vous souhaitiez approfondir vos connaissances, vous trouverez ici des **guides pédagogiques**, des **exercices pratiques**, et des **templates prêts à l'emploi** pour vous lancer.

---

## 📌 À propos du projet

Ce projet a pour objectif de vous faire découvrir et maîtriser les outils et méthodologies DevOps modernes à travers des **exercices concrets** et des **fiches explicatives**. Vous y trouverez :

- 📚 **Des guides pédagogiques** pour comprendre les concepts.
- 🎯 **Des exercices pratiques** avec des étapes détaillées et des commandes commentées.
- 📁 **Des templates de configuration** pour démarrer rapidement.
- 🏗️ **Des schémas d'architecture** pour visualiser les infrastructures.

---

## 🗂️ Structure du dépôt

```bash
p5_Openclassrooms/
├── .github/                  # Configuration GitHub (CI/CD, templates)
│   ├── workflows/            # Workflows GitHub Actions (CI/CD)
│   └── ISSUE_TEMPLATE/       # Templates pour les issues
│
├── docs/                     # 📚 Documentation pédagogique
│   ├── README.md             # Table des matières de la documentation
│   ├── architecture/        # 🏗️ Schémas et infrastructure
│   │   ├── infrastructure.md # Schéma global de l'infrastructure
│   │   └── tools.md          # Présentation des outils DevOps utilisés
│   │
│   ├── guides/               # 📖 Guides généraux
│   │   ├── project-overview.md # Présentation complète du projet
│   │   ├── devops-tools.md   # Détail des outils (Docker, GitHub Actions, etc.)
│   │   └── best-practices.md # Bonnes pratiques (Git, CI/CD, etc.)
│   │
│   ├── exercises/            # 🎯 Exercices pratiques (1 fiche par exercice)
│   │   ├── exercise-1/       # Déploiement avec Docker
│   │   ├── exercise-2/       # CI/CD avec GitHub Actions
│   │   ├── exercise-3/       # Configuration avec Ansible
│   │   ├── exercise-4/       # Infrastructure as Code avec Terraform
│   │   └── exercise-5/       # Orchestration avec Kubernetes
│   │
│   └── cheatsheets/          # 📋 Aides-mémoire
│       ├── docker.md         # Commandes Docker utiles
│       ├── git.md            # Commandes Git utiles
│       └── linux.md          # Commandes Linux utiles
│
├── TEMPLATES/                # 📁 Templates de configuration
│   ├── docker/               # Templates Docker
│   │   ├── Dockerfile.nodejs # Dockerfile pour Node.js
│   │   ├── Dockerfile.python # Dockerfile pour Python
│   │   ├── docker-compose.yml # Docker Compose pour multi-conteneurs
│   │   └── README.md         # Guide d'utilisation
│   │
│   ├── github-actions/       # Templates GitHub Actions
│   │   ├── ci-nodejs.yml     # Workflow CI pour Node.js
│   │   ├── cd-aws.yml        # Workflow CD pour AWS
│   │   └── README.md         # Explications des workflows
│   │
│   ├── ansible/              # Templates Ansible
│   │   ├── playbook.yml      # Playbook Ansible de base
│   │   ├── inventory.ini     # Fichier d'inventaire
│   │   └── README.md         # Guide Ansible
│   │
│   ├── terraform/            # Templates Terraform
│   │   ├── main.tf           # Configuration Terraform
│   │   ├── variables.tf      # Variables Terraform
│   │   └── README.md         # Guide Terraform
│   │
│   ├── kubernetes/           # Templates Kubernetes
│   │   ├── deployment.yaml   # Déploiement Kubernetes
│   │   ├── service.yaml      # Service Kubernetes
│   │   └── README.md         # Guide Kubernetes
│   │
│   └── scripts/              # Scripts utiles
│       ├── setup.sh          # Script de configuration
│       └── README.md         # Explications des scripts
│
├── src/                      # 📦 Code source (si applicable)
├── tests/                    # 🧪 Tests
│   ├── unit/                 # Tests unitaires
│   └── integration/          # Tests d'intégration
│
├── .gitignore                # Fichiers à ignorer
├── LICENSE                   # Licence (MIT)
└── README.md                 # Ce fichier
```

---

## 🚀 Pour commencer

### 1️⃣ Lire la présentation du projet
Consultez le guide **[Présentation du Projet](./docs/guides/project-overview.md)** pour comprendre les objectifs, l'infrastructure, et les outils utilisés.

### 2️⃣ Explorer les exercices
Chaque exercice est documenté dans `docs/exercises/` avec :
- Une **description claire** des objectifs.
- Des **étapes détaillées** à suivre.
- Des **commandes commentées** pour comprendre chaque action.
- Les **résultats attendus** et des astuces pour déboguer.

👉 **[Liste des exercices](./docs/exercises/)**

### 3️⃣ Utiliser les templates
Les templates dans `TEMPLATES/` sont prêts à l'emploi. Copiez-les dans votre projet et adaptez-les selon vos besoins.

👉 **[Liste des templates](./TEMPLATES/)**

### 4️⃣ Contribuer
Vous pouvez :
- **Ouvrir une issue** pour poser une question ou signaler un problème.
- **Proposer une pull request** pour améliorer la documentation ou ajouter un exercice.

---

## 🛠️ Prérequis

Pour suivre les exercices, assurez-vous d'avoir installé :

| Outil          | Version recommandée | Lien d'installation                          |
|----------------|---------------------|---------------------------------------------|
| Git            | 2.x                 | [git-scm.com](https://git-scm.com/)         |
| Docker         | 24.x                | [docker.com](https://www.docker.com/)       |
| Node.js        | 18.x                | [nodejs.org](https://nodejs.org/)           |
| Python         | 3.10+               | [python.org](https://www.python.org/)       |
| Ansible        | 8.x                 | [ansible.com](https://www.ansible.com/)     |
| Terraform      | 1.5.x               | [terraform.io](https://www.terraform.io/)   |
| kubectl        | 1.28.x              | [kubernetes.io](https://kubernetes.io/)    |

---

## 📚 Documentation

| Section               | Description                                                                 |
|-----------------------|-----------------------------------------------------------------------------|
| [📖 Guides](./docs/guides/) | Présentation du projet, outils DevOps, bonnes pratiques.                 |
| [🏗️ Architecture](./docs/architecture/) | Schémas et explications de l'infrastructure.                            |
| [🎯 Exercices](./docs/exercises/) | Fiches détaillées pour chaque exercice.                                   |
| [📋 Cheatsheets](./docs/cheatsheets/) | Aides-mémoire pour les commandes utiles.                                  |
| [📁 Templates](./TEMPLATES/) | Fichiers de configuration prêts à l'emploi.                              |

---

## 🤝 Contribuer

Les contributions sont les bienvenues ! Voici comment contribuer :

1. **Forker** le dépôt.
2. **Créer une branche** pour votre fonctionnalité (`git checkout -b feature/ma-fonctionnalité`).
3. **Commiter** vos changements (`git commit -m "Ajout de ma fonctionnalité"`).
4. **Pusher** vers la branche (`git push origin feature/ma-fonctionnalité`).
5. **Ouvrir une pull request**.

---

## 📜 Licence

Ce projet est sous licence **MIT**. Consultez le fichier [LICENSE](./LICENSE) pour plus de détails.

---

## 📞 Contact

Pour toute question ou suggestion, n'hésitez pas à :
- Ouvrir une **issue** dans ce dépôt.
- Me contacter directement via [GitHub](https://github.com/mathiasseguincadiche).

---

**Bonne exploration et bon apprentissage !** 🎉
