# 01 — Parcours conseillé

## Étape 0A — Installer et valider le lab

La VM n’est pas un prérequis implicite : elle fait partie du projet.

1. Installer Ubuntu Server 26.04 LTS sans interface graphique.
1. Activer OpenSSH pendant l’installation.
1. Cloner le dépôt dans `~/labs/p5_Openclassrooms`.
1. Installer le socle DevOps :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

1. Se reconnecter pour activer le groupe `docker`.
1. Configurer Git et la clé `~/.ssh/p5-key`.
1. Valider la VM :

```bash
./scripts/commands/setup.sh --check-only
```

Guide complet : [préparation de la VM](00-preparation-environnement.md).

## Étape 0B — Sécuriser et valider AWS

1. Sécuriser le compte root et confirmer MFA, récupération et absence de clés.
1. Configurer le profil `p5-lab` avec IAM Identity Center ou un rôle.
1. Copier la configuration locale :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

1. Copier et compléter les trois fichiers `terraform.tfvars`.
1. Prévisualiser puis créer le budget mensuel :

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply
```

1. Obtenir le verdict `GO AWS` :

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

Guide complet : [préparation du compte AWS](00b-preparation-compte-aws.md).

## Étape 1 — Construire puis déployer l’application

1. Copier le starter dans `application/angular/`.
1. Construire l’artefact :

```bash
./scripts/commands/prepare-angular-artifact.sh
```

1. Exécuter `terraform init`, puis `terraform plan`.
1. Lire le plan avant `terraform apply`.
1. Reporter l’adresse EC2 dans l’inventaire Ansible.
1. Vérifier la connexion avec le module `ping`.
1. Exécuter `deploy.yml` et vérifier l’application sur le port 80.
1. Conserver les sorties et captures utiles.

Fiche : [Exercice 1](exercices/01-terraform-ansible.md).

## Étape 2 — Amazon OpenSearch

1. Relancer le contrôle adapté :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

1. Déployer le domaine à partir de `terraform/exercice-2/`.
1. Importer l’échantillon NGINX.
1. Créer le motif d’index et vérifier les champs dans Discover.
1. Construire manuellement les trois visualisations imposées.
1. Capturer le dashboard complet et les trois graphiques.
1. Détruire OpenSearch après les preuves.

Fiche : [Exercice 2](exercices/02-elk-opensearch.md).

## Étape 3 — HAProxy

1. Conserver l’infrastructure réseau de l’exercice 1.
1. Vérifier les dépendances AWS :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

1. Déployer deux backends EC2 et une EC2 HAProxy.
1. Configurer `roundrobin` et les health checks.
1. Vérifier l’alternance des backends.
1. Arrêter un backend et contrôler la continuité du service.
1. Le redémarrer et vérifier sa réintégration.
1. Conserver `haproxy.cfg` et les preuves avant, pendant et après la panne.

Fiche : [Exercice 3](exercices/03-haproxy.md).

## Finalisation — Livrables et nettoyage

```bash
./scripts/commands/prepare-livrables.sh
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

La destruction s’effectue dans l’ordre 3 → 2 → 1. Le dernier script doit
produire `NETTOYAGE AWS COMPLET`. Ne jamais supprimer les états Terraform avant
la destruction et la vérification des ressources restantes.
