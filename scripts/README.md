# 🤖 Scripts d'automatisation du projet P5

Ce dossier sépare les points d'entrée, les phases de déploiement, les outils
autonomes et les bibliothèques partagées. Les scripts calculent leurs chemins
depuis la racine du dépôt et peuvent être lancés depuis n'importe quel dossier.

## 🗂️ Organisation

```text
scripts/
├── commands/   # Points d'entrée : préparation, validation et nettoyage
├── phases/     # Phases 0 à 5 du parcours P5
├── tools/      # Commandes autonomes pour Kibana, HAProxy et les captures
├── lib/        # Fonctions partagées : contrôles, couleurs, logs et prompts
├── run-all.sh  # Orchestrateur non interactif
└── runbook.sh  # Menu interactif pédagogique
```

## 🚀 Points d'entrée

| Besoin | Commande |
| --- | --- |
| Vérifier la machine sans déployer | `./scripts/commands/setup.sh --check-only` |
| Contrôler les prérequis AWS | `./scripts/commands/pre-deployment-check.sh` |
| Valider les fichiers du dépôt | `./scripts/commands/validate.sh` |
| Utiliser le menu interactif | `./scripts/runbook.sh` |
| Exécuter plusieurs phases | `./scripts/run-all.sh --from 1 --to 4 --validate` |
| Supprimer les caches locaux | `./scripts/commands/clean-local.sh` |
| Détruire les ressources AWS | `./scripts/commands/destroy-aws.sh` |

## 🧩 Phases

1. `phase-0-preparation.sh` vérifie l'environnement.
2. `phase-1-terraform-ansible.sh` déploie et configure les serveurs web.
3. `phase-2-opensearch-kibana.sh` déploie OpenSearch et le dashboard.
4. `phase-3-haproxy.sh` déploie HAProxy et les backends.
5. `phase-4-livrables.sh` prépare les fichiers de remise.
6. `phase-5-nettoyage.sh` détruit les ressources après confirmation stricte.

## ⚠️ Sécurité

`clean-local.sh` ne touche jamais à AWS. À l'inverse,
`destroy-aws.sh` et la phase 5 sont destructifs : ils affichent les ressources
concernées et demandent une confirmation avant `terraform destroy`.
