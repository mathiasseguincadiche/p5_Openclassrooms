# Garde-fous AWS du P5

Ce dossier regroupe les éléments de **préparation et de sécurité du compte AWS**.
Il ne crée pas les infrastructures des exercices : celles-ci restent sous
`terraform/`.

```text
aws/
├── README.md
├── budgets/
│   └── p5-monthly-budget.json.example
└── iam/
    └── p5-lab-policy.json
```

La procédure complète est décrite dans
[`docs/00b-preparation-compte-aws.md`](../docs/00b-preparation-compte-aws.md).

## Objectifs des garde-fous

Avant le premier `terraform apply`, le dépôt cherche à réduire quatre risques :

1. créer dans le mauvais compte ;
2. utiliser une identité trop privilégiée ou des credentials inadaptés ;
3. exposer inutilement SSH ou OpenSearch ;
4. oublier une ressource payante après la démonstration.

## Identité recommandée

- compte root réservé aux opérations qui l'exigent ;
- MFA root vérifié manuellement ;
- aucune clé d'accès root ;
- profil quotidien `p5-lab` ;
- IAM Identity Center ou rôle avec session temporaire de préférence ;
- aucun credential enregistré dans le dépôt.

La politique [`iam/p5-lab-policy.json`](iam/p5-lab-policy.json) constitue un socle
pédagogique limité aux services nécessaires au P5 : EC2/VPC, OpenSearch,
Service Quotas, AWS Budgets et lectures d'identité.

Son rattachement à un rôle ou un permission set reste une action administrative
explicite. Le dépôt ne crée pas d'utilisateur IAM et ne stocke aucun secret.

## Configuration du compte

Créer d'abord la source de configuration locale :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Puis synchroniser Terraform :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Le compte AWS, la région et l'adresse `/32` doivent être cohérents dans les trois
modules Terraform.

## Budget

Le fichier
[`budgets/p5-monthly-budget.json.example`](budgets/p5-monthly-budget.json.example)
documente la structure utilisée par le script de garde-fou.

Aperçu sans création :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Création volontaire :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Le nom, la limite et l'adresse de notification proviennent de
`environment/aws-readiness.env`.

Le budget reste volontairement actif après la destruction du lab : il sert de
filet de sécurité contre une ressource oubliée.

## Contrôle AWS Ready

Avant l'exercice 1 :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

Avant OpenSearch :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Avant HAProxy :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

Le contrôle est non destructif. Il vérifie notamment :

- profil et région ;
- compte actif ;
- identité non root ;
- source de credentials temporaires lorsque le mode strict l'exige ;
- confirmations de sécurité manuelles ;
- IPv4 publique actuelle en `/32` ;
- zones de disponibilité ;
- disponibilité du type EC2 et de l'AMI Ubuntu ;
- quota régional EC2 Standard ;
- compatibilité OpenSearch ;
- présence du budget ;
- cohérence des `terraform.tfvars` ;
- collisions ou dépendances propres à l'étape.

Un `KO` interdit de continuer. Les avertissements doivent être compris avant la
création de ressources.

## Garde-fous Terraform complémentaires

Chaque provider AWS utilise :

```text
allowed_account_ids = [expected_aws_account_id]
```

et des tags communs :

```text
Project   = p5-openclassrooms
ManagedBy = Terraform
Purpose   = training-lab
Exercise  = 1 | 2 | 3
```

Les modules refusent également les valeurs d'exemple du compte et de l'adresse
IP d'administration.

Les instances EC2 imposent IMDSv2 et des volumes racine chiffrés. OpenSearch
impose HTTPS, TLS 1.2 minimum, chiffrement au repos et entre les nœuds.

## Nettoyage

La fermeture complète du lab est volontairement séparée des contrôles de
préparation :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

L'ordre de destruction est :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

L'audit final recherche les ressources P5 restantes dans le compte et la région
ciblés. Le verdict recherché est :

```text
NETTOYAGE AWS COMPLET
```

Ne pas utiliser cet audit comme validation d'un nettoyage partiel tant que des
ressources P5 doivent encore rester actives pour un exercice suivant.

## Données interdites

Ne jamais versionner :

- clés AWS ;
- jetons de session ;
- clés privées SSH ;
- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états Terraform ;
- sorties runtime contenant des identifiants ou endpoints non relus.

Contrôle local :

```bash
python3 scripts/tools/audit_secrets.py
```

## Références

- [Préparation AWS complète](../docs/00b-preparation-compte-aws.md)
- [Architecture du projet](../docs/architecture-et-flux.md)
- [Validation, preuves et nettoyage](../docs/validation-preuves-nettoyage.md)
- [Politique de sécurité](../SECURITY.md)
