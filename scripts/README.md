# ⚙️ Automatisation du projet P5

Ce dossier centralise les commandes publiques, les phases de déploiement, les
outils autonomes et les bibliothèques partagées. Tous les scripts calculent la
racine du dépôt depuis leur propre emplacement et peuvent donc être appelés
depuis n'importe quel dossier.

---

## 🗂️ Organisation

```text
scripts/
├── README.md
├── run-all.sh                # Orchestrateur non interactif
├── runbook.sh                # Menu interactif
├── commands/                 # Points d'entrée utilisateur
│   ├── setup.sh
│   ├── validate.sh
│   ├── deploy.sh
│   ├── pre-deployment-check.sh
│   ├── clean-local.sh
│   └── destroy-aws.sh
├── phases/                   # Étapes ordonnées du projet P5
│   ├── phase-0-preparation.sh
│   ├── phase-1-terraform-ansible.sh
│   ├── phase-2-opensearch-kibana.sh
│   ├── phase-3-haproxy.sh
│   ├── phase-4-livrables.sh
│   └── phase-5-nettoyage.sh
├── tools/                    # Outils exécutables indépendamment
│   ├── capture-screenshots.sh
│   ├── generer-haproxy-config.sh
│   ├── health-checks.sh
│   └── kibana-api.sh
└── lib/                      # Fonctions Bash partagées
    ├── checks.sh
    ├── colors.sh
    ├── logging.sh
    └── prompts.sh
```

---

## 🚀 Parcours recommandé

### 1️⃣ Contrôler l'environnement

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/validate.sh
```

### 2️⃣ Vérifier la configuration avant AWS

```bash
./scripts/commands/pre-deployment-check.sh
```

### 3️⃣ Choisir le mode d'exécution

```bash
# Runbook interactif
./scripts/runbook.sh

# Orchestration complète ou partielle
./scripts/commands/deploy.sh --from 1 --to 3
```

Le déploiement complet n'exécute pas automatiquement le nettoyage final.

### 4️⃣ Nettoyer après utilisation

```bash
# Artefacts locaux seulement
./scripts/commands/clean-local.sh

# Ressources AWS, avec confirmations
./scripts/commands/destroy-aws.sh
```

---

## 🧩 Phases

| Phase | Script | Responsabilité |
| --- | --- | --- |
| 0 | `phase-0-preparation.sh` | Vérifier les prérequis locaux |
| 1 | `phase-1-terraform-ansible.sh` | Déployer EC2, NGINX et l'interface web |
| 2 | `phase-2-opensearch-kibana.sh` | Déployer OpenSearch et préparer le dashboard |
| 3 | `phase-3-haproxy.sh` | Déployer HAProxy et ses backends |
| 4 | `phase-4-livrables.sh` | Préparer les artefacts de remise |
| 5 | `phase-5-nettoyage.sh` | Détruire les ressources après confirmation |

Chaque phase peut être lancée directement depuis `scripts/phases/`, mais le
runbook est recommandé pour conserver l'ordre et les confirmations.

---

## 🛠️ Outils

### Dashboard OpenSearch

```bash
./scripts/tools/kibana-api.sh \
  --url https://votre-domaine/_dashboards \
  --auto --wait
```

### Captures des livrables

```bash
./scripts/tools/capture-screenshots.sh \
  --url https://votre-domaine/_dashboards \
  --headless --auto
```

Les captures doivent être vérifiées visuellement avant d'être ajoutées à un
livrable.

### Contrôle de santé

```bash
./scripts/tools/health-checks.sh --auto
./scripts/tools/health-checks.sh --phase 2 --wait --auto
```

### Configuration HAProxy

```bash
HAPROXY_STATS_PASSWORD='mot-de-passe-temporaire' \
  ./scripts/tools/generer-haproxy-config.sh 10.0.1.10 10.0.2.10
```

Le secret n'est jamais stocké dans le dépôt.

---

## ✅ Validation

`commands/validate.sh` exécute les contrôles disponibles sur la machine :

- syntaxe Bash et ShellCheck ;
- formatage et validation Terraform ;
- YAML et Markdown ;
- syntaxe du playbook Ansible.

La CI GitHub complète ces contrôles avec Hadolint, Docker Compose, NGINX et les
liens Markdown internes.

---

## ⚠️ Règles de sécurité

- Exécutez les commandes depuis un compte utilisateur normal.
- Relisez chaque `terraform plan` avant application.
- Ne placez aucun secret dans les arguments, les fichiers suivis ou les logs.
- Utilisez `destroy-aws.sh` uniquement après avoir contrôlé le compte AWS actif.
- Ne confondez pas `clean-local.sh`, qui préserve les states, et
  `destroy-aws.sh`, qui supprime l'infrastructure.
