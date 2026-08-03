# 📚 Documentation Pédagogique - P5 OpenClassrooms

**Bienvenue dans la section documentation !**
Ici, vous trouverez tous les **guides**, **exercices**, et **ressources** pour maîtriser les outils DevOps et les bonnes pratiques.

---

## 🗂️ Structure de la Documentation

```bash
docs/
├── README.md                 # Ce fichier (table des matières)
├── architecture/            # 🏗️ Schémas et infrastructure
│   ├── infrastructure.md    # Schéma global de l'infrastructure du projet
│   └── tools.md             # Présentation détaillée des outils DevOps utilisés
│
├── guides/                  # 📖 Guides généraux
│   ├── project-overview.md   # **Présentation complète du projet** (à lire en premier !)
│   ├── devops-tools.md      # Détail des outils (Docker, GitHub Actions, Ansible, etc.)
│   └── best-practices.md    # Bonnes pratiques (Git, CI/CD, sécurité, etc.)
│
├── exercises/               # 🎯 Exercices pratiques (1 fiche par exercice)
│   ├── exercise-1/          # **Exercice 1 : Déploiement avec Docker**
│   │   └── README.md        # Étapes, commandes commentées, résultats attendus
│   │
│   ├── exercise-2/          # **Exercice 2 : CI/CD avec GitHub Actions**
│   │   └── README.md
│   │
│   ├── exercise-3/          # **Exercice 3 : Configuration avec Ansible**
│   │   └── README.md
│   │
│   ├── exercise-4/          # **Exercice 4 : Infrastructure as Code avec Terraform**
│   │   └── README.md
│   │
│   └── exercise-5/          # **Exercice 5 : Orchestration avec Kubernetes**
│       └── README.md
│
└── cheatsheets/             # 📋 Aides-mémoire
    ├── docker.md            # Commandes Docker essentielles
    ├── git.md               # Commandes Git essentielles
    └── linux.md             # Commandes Linux essentielles
```

---

## 📌 Par où commencer ?

### 1️⃣ **Lisez la présentation du projet**
👉 **[Présentation du Projet](./guides/project-overview.md)**
- Comprenez les **objectifs** du projet P5.
- Découvrez l'**infrastructure** et les **outils** utilisés.
- Visualisez les **schémas d'architecture**.

### 2️⃣ **Explorez les guides**
- **[Outils DevOps](./guides/devops-tools.md)** : Détail de chaque outil (Docker, GitHub Actions, Ansible, Terraform, Kubernetes).
- **[Bonnes pratiques](./guides/best-practices.md)** : Conseils pour bien démarrer (Git, CI/CD, sécurité).

### 3️⃣ **Faites les exercices**
Chaque exercice est **autonome** et conçu pour vous faire pratiquer un outil ou un concept spécifique.

| Exercice | Titre | Outils | Niveau |
|----------|-------|--------|--------|
| [1](./exercises/exercise-1/README.md) | Déploiement avec Docker | Docker, Docker Compose | Débutant |
| [2](./exercises/exercise-2/README.md) | CI/CD avec GitHub Actions | GitHub Actions, Docker | Débutant/Intermédiaire |
| [3](./exercises/exercise-3/README.md) | Configuration avec Ansible | Ansible, SSH | Intermédiaire |
| [4](./exercises/exercise-4/README.md) | Infrastructure as Code avec Terraform | Terraform, AWS/Azure | Intermédiaire |
| [5](./exercises/exercise-5/README.md) | Orchestration avec Kubernetes | Kubernetes, Docker | Avancé |

### 4️⃣ **Consultez les aides-mémoire**
- **[Docker](./cheatsheets/docker.md)** : Commandes utiles pour Docker et Docker Compose.
- **[Git](./cheatsheets/git.md)** : Commandes Git essentielles (commit, branch, merge, etc.).
- **[Linux](./cheatsheets/linux.md)** : Commandes Linux de base (fichiers, processus, permissions).

---

## 🏗️ Architecture du Projet

Pour comprendre l'infrastructure globale du projet, consultez :
- **[Schéma d'infrastructure](./architecture/infrastructure.md)** : Diagrammes Mermaid et explications.
- **[Outils utilisés](./architecture/tools.md)** : Pourquoi et comment chaque outil est utilisé.

---

## 💡 Conseils pour les Débutants

1. **Prenez votre temps** : Les exercices sont conçus pour être suivis **pas à pas**. Ne vous précipitez pas.
2. **Lisez les explications** : Chaque commande est **commentée** pour que vous compreniez ce qu'elle fait.
3. **Testez en local** : Utilisez des environnements de test (Docker, machines virtuelles) pour éviter de casser votre système.
4. **Utilisez les templates** : Les fichiers dans [`/TEMPLATES/`](../TEMPLATES/) sont prêts à l'emploi. Copiez-les et adaptez-les.
5. **Posez des questions** : Si quelque chose n'est pas clair, ouvrez une **issue** dans le dépôt.

---

## 📞 Besoin d'aide ?

- **Erreur dans un exercice** ? Consultez la section **Résolution des problèmes** dans chaque fiche.
- **Question sur un outil** ? Lisez le guide correspondant dans [`guides/`](./guides/).
- **Bug ou suggestion** ? Ouvrez une **issue** dans le dépôt principal.

---

**Bonne lecture et bon apprentissage !** 🎉
