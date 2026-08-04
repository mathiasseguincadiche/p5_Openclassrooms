# 🚀 P5 OpenClassrooms - Projet DevOps

[![CI - Qualité du dépôt](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

**Bienvenue dans le dépôt du projet P5 OpenClassrooms !**

Ce projet présente une infrastructure AWS reproductible avec Terraform, sa
configuration avec Ansible, l'automatisation des déploiements et la préparation
des livrables pédagogiques associés.

---

## 🧭 Navigation rapide

| Destination | Contenu |
| --- | --- |
| [📚 Documentation](./docs/README.md) | Guides, architecture, exercices et aides-mémoire |
| [🏗️ Terraform](./terraform/README.md) | Infrastructure AWS des trois exercices du projet |
| [🎭 Ansible](./ansible/README.md) | Déploiement de l'interface web avec NGINX |
| [⚙️ Automatisation](./scripts/README.md) | Commandes, phases, contrôles et outils |
| [📁 Templates](./TEMPLATES/README.md) | Exemples réutilisables par technologie |
| [📦 Livrables](./docs/livrables/README.md) | Index des preuves et rapports attendus |
| [✅ Validation](./docs/reports/validation.md) | Périmètre des vérifications reproductibles |

---

## 📌 À propos du projet

Le dépôt réunit deux parcours complémentaires :

- trois exercices d'infrastructure correspondant aux livrables P5 ;
- cinq exercices pédagogiques consacrés aux outils DevOps fondamentaux.

### 🏗️ Parcours d'infrastructure P5

| Étape | Infrastructure | Automatisation | Livrable |
| --- | --- | --- | --- |
| 1 | [Deux EC2 et NGINX](./terraform/exercice-1/) | [Terraform + Ansible](./scripts/phases/phase-1-terraform-ansible.sh) | [Infrastructure web](./docs/livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| 2 | [Amazon OpenSearch](./terraform/exercice-2/) | [OpenSearch et dashboard](./scripts/phases/phase-2-opensearch-kibana.sh) | [Dashboard](./docs/livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| 3 | [HAProxy et deux backends](./terraform/exercice-3/) | [Load balancing](./scripts/phases/phase-3-haproxy.sh) | [HAProxy](./docs/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |

👉 Le parcours pédagogique complet est disponible dans
[la liste des exercices](./docs/exercises/README.md).

---

## 🚀 Pour commencer

### 1️⃣ Cloner et contrôler le dépôt

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
./scripts/commands/setup.sh --check-only
```

Le contrôle `--check-only` ne crée aucune ressource AWS.

### 2️⃣ Préparer les variables locales

Chaque module possède un fichier d'exemple :

```bash
cp terraform/exercice-1/terraform.tfvars.example terraform/exercice-1/terraform.tfvars
cp terraform/exercice-2/terraform.tfvars.example terraform/exercice-2/terraform.tfvars
cp terraform/exercice-3/terraform.tfvars.example terraform/exercice-3/terraform.tfvars
```

Les fichiers `terraform.tfvars`, les states et les secrets restent ignorés par
Git.

### 3️⃣ Exécuter le contrôle pré-déploiement

```bash
./scripts/commands/pre-deployment-check.sh
```

### 4️⃣ Ouvrir le runbook

```bash
./scripts/runbook.sh
```

Chaque `terraform plan` doit être relu avant un déploiement facturable.

---

## 🗂️ Structure du dépôt

```text
p5_Openclassrooms/
├── .github/                  # Workflows CI et modèles GitHub
├── ansible/                  # Playbook, inventaire exemple et interface web
├── docs/                     # Documentation, livrables et rapports
├── scripts/                  # Commandes, phases, outils et bibliothèques Bash
├── terraform/                # Modules AWS des trois exercices P5
├── TEMPLATES/                # Exemples réutilisables par technologie
├── .gitignore                # États, secrets et artefacts locaux ignorés
├── .markdownlint-cli2.jsonc  # Règles Markdown
├── .yamllint.yml             # Règles YAML
├── LICENSE                   # Licence MIT
└── README.md                 # Point d'entrée du dépôt
```

Chaque dossier fonctionnel possède son propre `README.md`. Le README racine
reste volontairement synthétique et oriente vers la documentation spécialisée.

---

## ⚙️ Commandes principales

| Commande | Effet |
| --- | --- |
| `./scripts/commands/setup.sh --check-only` | Vérifie l'environnement sans déployer |
| `./scripts/commands/validate.sh` | Exécute les contrôles locaux disponibles |
| `./scripts/commands/pre-deployment-check.sh` | Vérifie SSH, AWS et les fichiers requis |
| `./scripts/runbook.sh` | Lance le parcours interactif |
| `./scripts/commands/deploy.sh --from 1 --to 3` | Exécute une plage de phases |
| `./scripts/tools/health-checks.sh --auto` | Contrôle la santé du projet |
| `./scripts/commands/clean-local.sh` | Supprime les artefacts locaux reproductibles |
| `./scripts/commands/destroy-aws.sh` | Détruit les ressources AWS après confirmation |

---

## 🛠️ Prérequis

| Outil | Version recommandée | Utilisation |
| --- | --- | --- |
| Git | 2.x | Versionnement |
| Docker | 28.x | Validation et templates locaux |
| AWS CLI | 2.x | Accès authentifié à AWS |
| Ansible Core | 2.18+ | Configuration des serveurs |
| Terraform | 1.15.8 | Provisionnement de l'infrastructure |
| Python | 3.12+ | Outils de validation |
| Node.js | 24.x | Templates et outils Markdown |

---

## ⚠️ Sécurité et coûts

- Ne commitez jamais de clé privée, de `terraform.tfvars` réel ou de state.
- Injectez `HAPROXY_STATS_PASSWORD` par variable d'environnement.
- Vérifiez l'identité AWS active avec `aws sts get-caller-identity`.
- Relisez le plan et les coûts avant chaque `terraform apply`.
- Détruisez les ressources devenues inutiles, particulièrement OpenSearch.
- Complétez les livrables uniquement avec des preuves issues d'un déploiement
  réel.

---

## 🤝 Contribuer

1. Créez une branche dédiée.
2. Appliquez une modification ciblée.
3. Exécutez `./scripts/commands/validate.sh`.
4. Ouvrez une pull request vers `main`.

Les signalements peuvent être ouverts depuis les
[issues GitHub](https://github.com/mathiasseguincadiche/p5_Openclassrooms/issues).

---

## 📜 Licence

Ce projet est distribué sous licence MIT. Consultez [LICENSE](./LICENSE).

---

**Bonne exploration et bon apprentissage !** 🎉
