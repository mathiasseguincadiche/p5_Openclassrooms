# Garde-fous AWS du P5

Ce dossier contient uniquement les éléments AWS communs au projet :

```text
aws/
├── README.md
├── budgets/
│   └── p5-monthly-budget.json.example
└── iam/
    └── p5-lab-policy.json
```

Les infrastructures des trois exercices restent sous `terraform/`.

La procédure complète est décrite dans [`docs/00b-preparation-compte-aws.md`](../docs/00b-preparation-compte-aws.md).

## Objectif

Les garde-fous réduisent les risques de :

- travailler dans le mauvais compte AWS ;
- utiliser une identité inadaptée ;
- exposer SSH ou OpenSearch plus largement que nécessaire ;
- laisser des ressources facturables après la démonstration.

## Identité

Le parcours P5 utilise une identité non root et privilégie une session temporaire partagée entre AWS CLI et Terraform.

Le dépôt ne versionne aucun credential AWS.

La politique [`iam/p5-lab-policy.json`](iam/p5-lab-policy.json) couvre les services réellement utilisés par le projet : EC2/VPC, Amazon OpenSearch Service, Service Quotas, AWS Budgets et lectures d'identité nécessaires aux contrôles.

Cette politique utilise les actions OpenSearch actuelles (`es:CreateDomain`, `es:DescribeDomain`, `es:ListInstanceTypeDetails`, etc.) tout en conservant les alias historiques utiles à la compatibilité. Si une ancienne version de `P5LabPolicy` a déjà été créée dans IAM, elle doit être mise à jour depuis le JSON versionné avant l'exercice 2. Modifier le fichier Git ne modifie pas automatiquement la politique déjà créée dans le compte AWS.

## Configuration locale

La source locale de configuration est :

```text
environment/aws-readiness.env
```

Elle est dérivée du modèle versionné `environment/aws-readiness.env.example` et reste ignorée par Git.

Elle centralise notamment :

- profil et région ;
- compte AWS attendu ;
- IPv4 publique d'administration en `/32` ;
- clé SSH ;
- paramètres EC2 et OpenSearch ;
- budget ;
- confirmations de sécurité.

Les trois `terraform.tfvars` sont générés depuis cette source unique.

## Budget

`budgets/p5-monthly-budget.json.example` documente le garde-fou budgétaire du lab.

Le budget est un filet de sécurité ; il ne signifie jamais que les ressources sont gratuites.

## AWS Ready

Les contrôles de préparation vérifient notamment :

- profil, région et compte ;
- identité non root ;
- IPv4 publique actuelle en `/32` ;
- clé SSH ;
- zones de disponibilité ;
- types d'instances et AMI ;
- quota régional EC2 ;
- paramètres OpenSearch ;
- présence du budget ;
- cohérence des `terraform.tfvars`.

Le précontrôle est **dépendant de l'étape**. Le stage `initial` ne bloque pas l'exercice 1 à cause d'une capacité nécessaire uniquement plus tard. Avec les valeurs de référence, une `t3.micro` suffit à l'exercice 1, tandis que l'exercice 3 peut porter le besoin simultané global à 8 vCPU. Un quota inférieur à 8 est donc signalé à l'avance au stage initial, puis devient bloquant lorsqu'il empêche réellement l'étape demandée.

De même, une permission OpenSearch manquante est signalée comme préparation à faire avant l'exercice 2 ; elle ne doit pas empêcher l'exercice 1 lorsqu'aucune ressource OpenSearch n'est encore créée.

Un contrôle **KO pour l'étape courante** doit être résolu avant le déploiement correspondant. Un avertissement peut signaler une exigence d'une étape future sans bloquer le travail actuellement réalisable.

## Amazon OpenSearch

L'exercice 2 utilise **Amazon OpenSearch Service** créé par Terraform.

Le conteneur OpenSearch de la CI sert uniquement à vérifier localement le mapping, l'import Bulk et les agrégations. Il ne remplace pas la réalisation AWS de l'exercice.

Le domaine AWS applique les garde-fous documentés par le projet, notamment HTTPS, chiffrement et restriction d'accès à l'IPv4 publique `/32` du lab.

Le précontrôle distingue désormais :

- un type/version réellement indisponible ;
- une permission IAM manquante telle que `es:ListInstanceTypeDetails` ;
- un état de domaine non vérifiable faute de `es:DescribeDomain`.

Il ne transforme plus silencieusement un `AccessDenied` en « ressource absente ».

## Garde-fou de compte Terraform

Chaque provider AWS utilise :

```text
allowed_account_ids = [expected_aws_account_id]
```

Le compte préparé reste donc un contrat explicite de l'infrastructure.

## Nettoyage

La fermeture du lab suit l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Le verdict final attendu est :

```text
NETTOYAGE AWS COMPLET
```

## Références

- [Préparation du compte AWS](../docs/00b-preparation-compte-aws.md)
- [Runbook A à Z](../docs/RUNBOOK_EXECUTION_GUIDEE.md)
- [Sécurité](../SECURITY.md)
- [Validation, preuves et nettoyage](../docs/validation-preuves-nettoyage.md)
