# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**. Le dépôt présente un lab reproductible pour provisionner AWS avec Terraform, déployer une application Angular avec Ansible et NGINX, analyser des logs dans Amazon OpenSearch et démontrer la haute disponibilité avec HAProxy.

> **Attention aux coûts AWS :** relire chaque plan Terraform, activer le budget du lab et détruire les ressources après la démonstration.

## Compétences démontrées

| Domaine | Mise en œuvre |
| --- | --- |
| Infrastructure as Code | Trois modules Terraform avec garde-fous de compte, réseau et chiffrement |
| Configuration automatisée | Build Angular reproductible, déploiement Ansible et NGINX |
| Observabilité | Transformation, import et analyse de logs NGINX dans OpenSearch |
| Haute disponibilité | Répartition `roundrobin`, panne contrôlée et réintégration HAProxy |
| Qualité et sécurité | CI, non-régression, contrôle de secrets et nettoyage AWS vérifiable |

## Parcours du projet

| Étape | Objectif | Documentation détaillée |
| --- | --- | --- |
| Préparation | Valider la VM et sécuriser le compte AWS | [Environnement](docs/00-preparation-environnement.md) · [Compte AWS](docs/00b-preparation-compte-aws.md) |
| Exercice 1 | Déployer Angular sur EC2 avec Terraform, Ansible et NGINX | [Guide complet](docs/exercices/01-terraform-ansible.md) |
| Exercice 2 | Importer et visualiser les logs NGINX dans OpenSearch | [Guide complet](docs/exercices/02-elk-opensearch.md) |
| Exercice 3 | Tester la répartition, la panne et la reprise HAProxy | [Guide complet](docs/exercices/03-haproxy.md) |
| Finalisation | Produire les preuves, détruire AWS et vérifier le nettoyage | [Livrables](docs/livrables/README.md) · [Preuves](proofs/README.md) |

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

## Documentation approfondie

- [Index complet de la documentation](docs/README.md)
- [Correspondance entre consignes, fichiers et preuves](docs/02-correspondance-consignes-depot.md)
- [Scripts et commandes](scripts/README.md)
- [Infrastructure Terraform](terraform/README.md)
- [Application Angular](application/README.md) et [déploiement Ansible](ansible/README.md)
- [Schémas d’architecture](docs/schemas/README.md)
- [Politique de sécurité](SECURITY.md)

## Validation

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_secrets.py
```

La validation complète avec OpenSearch local est activable avec :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

## État de finalisation

Le code, les configurations et les contrôles automatisés sont versionnés. Les trois documents de `docs/livrables/` restent volontairement des gabarits tant que les sorties et captures du véritable environnement AWS n’y ont pas été insérées.

La remise finale exige les verdicts suivants :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
