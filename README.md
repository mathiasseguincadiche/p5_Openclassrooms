# 🚀 P5 OpenClassrooms — Terraform, Ansible, ELK et HAProxy

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt est un **wiki pédagogique du projet P5**. Il suit les documents
OpenClassrooms fournis et distingue clairement les ressources, les cours et les
**trois exercices officiels**.

> **Choix de réalisation validé : parcours 100 % AWS.** Les trois exercices sont
> implémentés sur AWS : EC2 pour Terraform et Ansible, Amazon OpenSearch pour le
> monitoring, puis EC2 avec HAProxy et deux backends pour la disponibilité.
> Les variantes locales restent citées uniquement pour expliquer les choix
> proposés par OpenClassrooms ; elles ne constituent pas une seconde
> implémentation dans ce dépôt.

![Vue d'ensemble des trois exercices](docs/schemas/vue-ensemble.svg)

## 🧭 Parcours conseillé

1. [Lire le cadre officiel](docs/00-cadre-officiel.md).
2. [Suivre le parcours débutant](docs/01-parcours-debutant.md).
3. [Consulter la correspondance consigne → fichier → preuve](docs/02-correspondance-consignes-depot.md).
4. Réaliser un seul exercice à la fois.
5. [Préparer les trois livrables](docs/livrables/README.md).

## 🎯 Les trois exercices

| Exercice | Objectif | Implémentation principale | Preuve attendue |
| --- | --- | --- | --- |
| 1 — Terraform et Ansible | Créer une infrastructure puis déployer une application Angular avec NGINX | **AWS : VPC + EC2**, puis Ansible dans [`terraform/exercice-1/`](terraform/exercice-1/) et [`ansible/`](ansible/) | Fichiers Terraform, inventaire, playbook et application accessible |
| 2 — OpenSearch | Importer des logs NGINX et construire trois visualisations | **AWS : Amazon OpenSearch** dans [`terraform/exercice-2/`](terraform/exercice-2/) | Dashboard complet et captures des trois graphiques |
| 3 — HAProxy | Répartir la charge entre deux backends et tester la reprise après panne | **AWS : trois EC2** dans [`terraform/exercice-3/`](terraform/exercice-3/) | `haproxy.cfg`, alternance, panne et réintégration |

## 🚦 Démarrage sans risque

```bash
./scripts/commands/setup.sh --check-only
./scripts/commands/validate.sh
```

Ces commandes n’installent rien et ne créent aucune ressource. Les commandes
`terraform plan`, `apply` et `destroy` restent manuelles afin que le débutant
puisse comprendre chaque étape et relire les coûts avant validation.

## 🗂️ Arborescence

```text
p5_Openclassrooms/
├── ansible/                 # Exercice 1 : inventaire, playbook, application et NGINX
├── docs/
│   ├── exercices/           # Une fiche pour chacun des trois exercices
│   ├── livrables/           # Gabarits de preuves à compléter
│   ├── ressources/          # Cours et ressources préparatoires
│   ├── schemas/             # Quatre schémas SVG, sans Mermaid
│   └── suivi/               # Journal et décisions techniques
├── scripts/
│   ├── commands/            # Vérification, livrables et nettoyage
│   └── tools/               # Générateur HAProxy facultatif
└── terraform/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## ✅ Périmètre conservé

- Terraform, Ansible, NGINX et l’application Angular pour l’exercice 1.
- Amazon OpenSearch sur AWS et les trois visualisations imposées pour
  l’exercice 2.
- HAProxy, deux instances `nginxdemos/hello`, les health checks et le test de
  panne pour l’exercice 3.
- Les preuves, le suivi des coûts et la destruction des ressources.

## 🧹 Éléments retirés

Les cinq anciens exercices génériques, les templates Kubernetes, les guides
Prometheus, Grafana, Vault et les automatisations volumineuses ne répondaient
pas directement au P5. Ils ont été retirés pour que le dépôt reste lisible par
un débutant.

Aucun diagramme Mermaid n’est utilisé. Les schémas sont des SVG lisibles dans
GitHub et dans les documents exportés.

## ⚠️ Limites connues

- Le dépôt implémente **exclusivement le parcours AWS retenu pour la réalisation**.
  Les modes locaux proposés par OpenClassrooms sont seulement rappelés comme
  alternatives officielles ; aucun parcours Docker local parallèle n’est maintenu.
- `ansible/files/angular-app/` contient une page de démonstration. Elle doit être
  remplacée par le véritable résultat de `ng build` avant la remise.
- Les PDF emploient parfois GitLab et parfois GitHub, et se contredisent sur le
  type d’instance EC2 et le troisième livrable. Le détail de chaque exercice et
  la consigne visible sur la plateforme au moment de la remise restent
  prioritaires.

## 🔐 Sécurité et coûts

Ne versionnez jamais une clé privée, un fichier `terraform.tfvars`, un état
Terraform, un inventaire réel ou une capture contenant des identifiants. Les
instances EC2 et Amazon OpenSearch peuvent être facturés. Après les preuves,
utilisez [`scripts/commands/destroy-aws.sh`](scripts/commands/destroy-aws.sh),
puis vérifiez la console AWS.

Licence : [MIT](LICENSE).
