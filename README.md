# 🚀 P5 OpenClassrooms — Infrastructure as Code et automatisation

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt regroupe les trois exercices du projet P5 : provisionnement AWS
avec Terraform, configuration avec Ansible, observabilité OpenSearch et
répartition de charge avec HAProxy. Les scripts accompagnent chaque étape
sans masquer les actions susceptibles de créer des coûts.

## 🧭 Navigation rapide

- [Documentation générale](docs/README.md)
- [Scripts et commandes](scripts/README.md)
- [Infrastructure Terraform](terraform/README.md)
- [Déploiement Ansible](ansible/README.md)
- [Livrables](docs/livrables/README.md)
- [Rapport de validation](docs/reports/validation.md)
- [Templates réutilisables](TEMPLATES/README.md)

## 🏗️ Parcours du projet

| Exercice | Infrastructure | Automatisation | Livrable |
| --- | --- | --- | --- |
| 1 — Terraform, Ansible et NGINX | [`terraform/exercice-1`](terraform/exercice-1/) | [`phase-1-terraform-ansible.sh`](scripts/phases/phase-1-terraform-ansible.sh) | [Preuves Exercice 1](docs/livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md) |
| 2 — OpenSearch et Dashboards | [`terraform/exercice-2`](terraform/exercice-2/) | [`phase-2-opensearch-kibana.sh`](scripts/phases/phase-2-opensearch-kibana.sh) | [Preuves Exercice 2](docs/livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md) |
| 3 — HAProxy et nginxdemos/hello | [`terraform/exercice-3`](terraform/exercice-3/) | [`phase-3-haproxy.sh`](scripts/phases/phase-3-haproxy.sh) | [Preuves Exercice 3](docs/livrables/SEGUIN-CADICHE_Mathias_3_haproxy_nginxdemos_02082026.md) |

## 🚀 Démarrage sécurisé

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/pre-deployment-check.sh
./scripts/runbook.sh
```

Le premier contrôle vérifie la machine et le dépôt. Le second vérifie les
prérequis AWS sans créer de ressource. Le runbook conserve une confirmation
explicite avant chaque déploiement ou destruction.

## 🗂️ Arborescence

```text
p5_Openclassrooms/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/ci.yml
├── ansible/
│   ├── files/web-app/
│   ├── inventories/hosts_aws.example
│   └── playbooks/deploy.yml
├── docs/
│   ├── architecture/
│   ├── cheatsheets/
│   ├── exercises/
│   ├── guides/
│   ├── livrables/
│   └── reports/validation.md
├── scripts/
│   ├── commands/
│   ├── phases/
│   ├── tools/
│   ├── lib/
│   ├── run-all.sh
│   └── runbook.sh
├── terraform/
│   ├── exercice-1/
│   ├── exercice-2/
│   └── exercice-3/
├── TEMPLATES/
├── LICENSE
└── README.md
```

## 🛠️ Commandes principales

| Action | Commande |
| --- | --- |
| Préparer et contrôler l'environnement | `./scripts/commands/setup.sh --check-only` |
| Valider le dépôt | `./scripts/commands/validate.sh` |
| Ouvrir le runbook interactif | `./scripts/runbook.sh` |
| Exécuter une plage de phases | `./scripts/run-all.sh --from 1 --to 3 --validate` |
| Nettoyer les artefacts locaux | `./scripts/commands/clean-local.sh` |
| Détruire les ressources AWS | `./scripts/commands/destroy-aws.sh` |

## 📚 Documentation

Les guides pédagogiques et aides-mémoire sont indexés dans
[`docs/README.md`](docs/README.md). Les exemples génériques sont séparés du
projet dans [`TEMPLATES/`](TEMPLATES/README.md), afin de ne pas les confondre
avec les fichiers réellement utilisés pour les livrables.

## ⚠️ AWS, coûts et secrets

- Exécutez toujours `terraform plan` avant `terraform apply`.
- OpenSearch peut générer des coûts importants hors offre gratuite.
- Ne versionnez jamais les états Terraform, variables locales, inventaires
  réels, clés SSH ou mots de passe.
- Les zones « preuve à insérer » doivent être remplacées uniquement par des
  captures et sorties produites pendant un déploiement réel.
- La destruction AWS est volontairement séparée du nettoyage local.

## 🤝 Contribution et licence

Les améliorations passent par une branche et une pull request afin que la CI
valide Bash, Terraform, YAML, Ansible, Docker, NGINX et Markdown. Le projet
est distribué sous licence [MIT](LICENSE).
