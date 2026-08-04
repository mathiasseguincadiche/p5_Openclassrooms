# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt est le **wiki technique et l’implémentation du projet P5**. Il conserve
les trois exercices officiels et commence par deux fondations obligatoires : la
VM de lab, puis la validation complète du compte AWS.

> **Parcours retenu : 100 % AWS pour les trois exercices.** La VM Ubuntu Server
> sert de poste DevOps en ligne de commande. Elle exécute Terraform, Ansible,
> AWS CLI et les outils de construction ; les infrastructures évaluées sont
> créées sur AWS.

![Chaîne complète du projet P5](docs/schemas/vue-ensemble.svg)

## Parcours du projet

| Étape | Objectif | Résultat |
| --- | --- | --- |
| 0A — Lab | Installer Ubuntu Server 26.04 et le socle DevOps | VM reproductible et contrôlée |
| 0B — AWS Ready | Sécuriser et valider le compte, la région, les quotas et le budget | Verdict `GO AWS` avant Terraform |
| 1 — Terraform et Ansible | Créer EC2 puis déployer l’application Angular avec NGINX | Application accessible sur AWS |
| 2 — OpenSearch | Importer les logs NGINX et créer trois visualisations | Dashboard et quatre captures |
| 3 — HAProxy | Répartir la charge entre deux backends et tester la reprise | Disponibilité démontrée |
| Finalisation | Préparer les preuves, détruire et auditer AWS | Livrables propres, aucun coût oublié |

## Commencer ici

1. [Installer et préparer la VM Ubuntu Server](docs/00-preparation-environnement.md).
2. [Sécuriser et valider le compte AWS](docs/00b-preparation-compte-aws.md).
3. [Lire le cadre officiel](docs/00-cadre-officiel.md).
4. [Suivre le parcours guidé](docs/01-parcours-debutant.md).
5. [Contrôler la correspondance consigne → fichier → preuve](docs/02-correspondance-consignes-depot.md).
6. [Consulter l’audit de non-régression](docs/04-audit-non-regression.md).

Après installation du système :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
# Reconnexion nécessaire pour le groupe docker
./scripts/commands/setup.sh --check-only

cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le contrôle pré-déploiement n’exécute aucun `terraform apply`. La seule mutation
de l’étape 0B est la création volontaire du budget avec `--apply`.

## Une seule application, une chaîne complète

Le projet fait fonctionner une application Angular unique :

```text
application/angular/        sources du starter
          │ npm ci + npm run build
          ▼
ansible/files/angular-app/  artefact navigateur normalisé
          │ ansible-playbook
          ▼
EC2 /var/www/p5             fichiers déployés
          │ NGINX :80
          ▼
Application web             logs exploités dans OpenSearch
```

La procédure est documentée dans [`application/`](application/). Le script
[`prepare-angular-artifact.sh`](scripts/commands/prepare-angular-artifact.sh)
construit le starter et prépare exactement l’artefact copié par Ansible.

## Arborescence utile

```text
p5_Openclassrooms/
├── application/
│   └── angular/              # sources du starter Angular
├── ansible/
│   ├── files/angular-app/    # build à déployer
│   ├── files/nginx-angular.conf
│   ├── inventories/
│   └── playbooks/deploy.yml
├── aws/
│   ├── budgets/              # exemple et création du budget du lab
│   └── iam/                  # politique IAM de référence
├── environment/
│   ├── aws-readiness.env.example
│   └── versions.env
├── docs/
│   ├── exercices/            # trois exercices, pas davantage
│   ├── livrables/
│   ├── ressources/
│   ├── schemas/              # schémas légers adaptés au Markdown
│   └── suivi/
├── scripts/
│   ├── commands/             # bootstrap, AWS Ready, build et nettoyage
│   └── tools/
└── terraform/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## Contrôle AWS Ready

Le script
[`check-aws-readiness.sh`](scripts/commands/check-aws-readiness.sh) vérifie sans
mutation :

- l’identité quotidienne non root et le compte autorisé ;
- la session temporaire ou le rôle utilisé par le profil ;
- la région, l’adresse publique `/32` et les zones disponibles ;
- l’AMI Ubuntu et les types EC2/OpenSearch ;
- le quota régional EC2 Standard ;
- le budget mensuel et la cohérence des trois `terraform.tfvars` ;
- les collisions ou dépendances attendues selon l’exercice.

Chaque module Terraform utilise `allowed_account_ids`, des tags communs et des
validations qui refusent les valeurs d’exemple.

## Éléments protégés contre les régressions

La CI vérifie notamment :

- l’existence des étapes 0A et 0B et de leurs scripts ;
- les garde-fous Terraform du compte AWS et des adresses `/32` ;
- la politique IAM et les exemples JSON ;
- la présence de la chaîne applicative Angular → Ansible → NGINX ;
- exactement trois exercices officiels ;
- l’absence de Mermaid et de contenus génériques hors périmètre ;
- Bash, ShellCheck, JSON, YAML, Terraform, Ansible, NGINX, Markdown et liens ;
- la présence et la validité des schémas pédagogiques.

La suppression de milliers de lignes génériques n’est pas considérée comme une
perte lorsqu’elles concernaient Kubernetes, Prometheus, Grafana, Vault ou de
faux exercices. En revanche, les capacités utiles qui avaient disparu pendant
la simplification sont réintégrées et testées.

## Sécurité et coûts

Ne versionnez jamais de clé privée, `terraform.tfvars`, état Terraform,
inventaire réel, fichier `environment/aws-readiness.env` ou identifiant secret.
Relisez chaque plan avant application.

À la fin, exécutez :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Le second contrôle recherche les ressources P5 restantes dans AWS. Le budget
reste actif afin de signaler une ressource oubliée après la démonstration.

Licence : [MIT](LICENSE).
