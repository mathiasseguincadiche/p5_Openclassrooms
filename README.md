# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt est le **wiki technique et l’implémentation du projet P5**. Il conserve
les trois exercices officiels, mais commence par une étape indispensable : la
préparation de la VM de lab qui pilote toute la réalisation.

> **Parcours retenu : 100 % AWS pour les trois exercices.** La VM Ubuntu Server
> sert de poste DevOps en ligne de commande. Elle exécute Terraform, Ansible,
> AWS CLI et les outils de construction ; les infrastructures évaluées sont
> créées sur AWS.

![Chaîne complète du projet P5](docs/schemas/vue-ensemble.svg)

## Parcours du projet

| Étape | Objectif | Résultat |
| --- | --- | --- |
| 0 — Lab | Installer Ubuntu Server 26.04 et le socle DevOps | VM reproductible et contrôlée |
| 1 — Terraform et Ansible | Créer EC2 puis déployer l’application Angular avec NGINX | Application accessible sur AWS |
| 2 — OpenSearch | Importer les logs NGINX et créer trois visualisations | Dashboard et quatre captures |
| 3 — HAProxy | Répartir la charge entre deux backends et tester la reprise | Disponibilité démontrée |
| Finalisation | Préparer les preuves puis détruire les ressources | Livrables propres, aucun coût oublié |

## Commencer ici

1. [Installer et préparer la VM Ubuntu Server](docs/00-preparation-environnement.md).
2. [Lire le cadre officiel](docs/00-cadre-officiel.md).
3. [Suivre le parcours guidé](docs/01-parcours-debutant.md).
4. [Contrôler la correspondance consigne → fichier → preuve](docs/02-correspondance-consignes-depot.md).
5. [Consulter l’audit de non-régression](docs/04-audit-non-regression.md).

Après installation du système :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
# Reconnexion nécessaire pour le groupe docker
./scripts/commands/setup.sh --check-only
./scripts/commands/pre-deployment-check.sh
```

Aucune de ces vérifications ne lance `terraform apply`.

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
├── docs/
│   ├── exercices/            # trois exercices, pas davantage
│   ├── livrables/
│   ├── ressources/
│   ├── schemas/              # schémas légers adaptés au Markdown
│   └── suivi/
├── scripts/
│   ├── commands/             # bootstrap, contrôles, build et nettoyage
│   └── tools/
└── terraform/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## Éléments protégés contre les régressions

La CI vérifie notamment :

- l’existence de l’étape 0, du bootstrap et du contrôle pré-déploiement ;
- la présence de la chaîne applicative Angular → Ansible → NGINX ;
- exactement trois exercices officiels ;
- l’absence de Mermaid et de contenus génériques hors périmètre ;
- Bash, ShellCheck, YAML, Terraform, Ansible, NGINX, Markdown et liens ;
- la présence et la validité des schémas pédagogiques.

La suppression de milliers de lignes génériques n’est pas considérée comme une
perte lorsqu’elles concernaient Kubernetes, Prometheus, Grafana, Vault ou de
faux exercices. En revanche, les capacités utiles qui avaient disparu pendant
la simplification sont réintégrées et testées.

## Sécurité et coûts

Ne versionnez jamais de clé privée, `terraform.tfvars`, état Terraform,
inventaire réel ou identifiant AWS. Relisez chaque plan avant application. À la
fin, exécutez :

```bash
./scripts/commands/destroy-aws.sh
```

Puis vérifiez manuellement EC2, OpenSearch, les volumes et les adresses dans la
console AWS.

Licence : [MIT](LICENSE).
