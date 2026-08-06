# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**. Il présente un lab reproductible sur AWS pour provisionner une infrastructure, déployer une application Angular, exploiter des logs NGINX dans OpenSearch et démontrer la disponibilité d’un service derrière HAProxy.

Le dépôt sépare volontairement la **présentation synthétique** ici et les **procédures détaillées** dans la [documentation complète](docs/README.md).

> **Attention aux coûts AWS :** lire chaque plan Terraform, activer le budget du lab et détruire les ressources après la démonstration.

## Compétences démontrées

| Domaine | Réalisation |
| --- | --- |
| Infrastructure as Code | Provisionnement AWS avec Terraform |
| Configuration automatisée | Déploiement Angular avec Ansible et NGINX |
| Observabilité | Conversion et analyse des logs dans Amazon OpenSearch |
| Haute disponibilité | Round-robin, panne et reprise avec HAProxy |
| Qualité et sécurité | CI, validations, garde-fous AWS et nettoyage contrôlé |

## Parcours évalué

| Étape | Objectif | Guide détaillé |
| --- | --- | --- |
| Préparation | Construire le poste DevOps et valider le compte AWS | [VM et outils](docs/00-preparation-environnement.md) · [Compte AWS](docs/00b-preparation-compte-aws.md) |
| Exercice 1 | Déployer l’application Angular sur EC2 | [Terraform, Ansible et NGINX](docs/exercices/01-terraform-ansible.md) |
| Exercice 2 | Importer et visualiser les logs NGINX | [Amazon OpenSearch](docs/exercices/02-elk-opensearch.md) |
| Exercice 3 | Tester le round-robin et le failover | [HAProxy et disponibilité](docs/exercices/03-haproxy.md) |
| Finalisation | Produire les preuves et supprimer les ressources | [Livrables](docs/livrables/README.md) · [Preuves](proofs/README.md) |

```text
Poste DevOps → Terraform → AWS → Ansible/NGINX → Angular
                         ├→ logs → OpenSearch
                         └→ HAProxy → 2 backends
```

## Démarrage

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
./scripts/commands/bootstrap-ubuntu-server.sh
```

Après reconnexion :

```bash
./scripts/commands/setup.sh --check-only
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
./scripts/commands/sync-terraform-tfvars.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le déploiement ne doit commencer qu’après le verdict **`GO TERRAFORM`**.

## Documentation

- [Index de la documentation](docs/README.md)
- [Cadre officiel et périmètre](docs/00-cadre-officiel.md)
- [Parcours guidé](docs/01-parcours-debutant.md)
- [Correspondance entre consignes, fichiers et preuves](docs/02-correspondance-consignes-depot.md)
- [Audit structurel](docs/03-audit-structurel.md)
- [Contrat de non-régression](docs/04-audit-non-regression.md)
- [Décisions techniques](docs/suivi/decisions-techniques.md)
- [Scripts et commandes](scripts/README.md)
- [Infrastructure Terraform](terraform/README.md)
- [Déploiement Ansible](ansible/README.md)
- [Application Angular](application/README.md)
- [Schémas d’architecture](docs/schemas/README.md) : [vue d’ensemble](docs/schemas/vue-ensemble.svg), [préparation](docs/schemas/etape-0.svg), [exercice 1](docs/schemas/exercice-1.svg), [exercice 2](docs/schemas/exercice-2.svg), [exercice 3](docs/schemas/exercice-3.svg), [finalisation](docs/schemas/finalisation/finalisation.svg)

## Validation locale

```bash
./scripts/commands/validate.sh
```

Les tests d’intégration complets avec OpenSearch local sont activables avec :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

## État des preuves

Les fichiers de `docs/livrables/` sont des gabarits contrôlés par le dépôt. Ils ne deviennent des livrables définitifs qu’après insertion des sorties et captures produites sur le véritable environnement AWS.

La finalisation est validée uniquement après les verdicts :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
