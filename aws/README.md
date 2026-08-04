# Garde-fous AWS du P5

Ce dossier contient les éléments de préparation du compte AWS. Ils complètent
la VM de lab sans créer automatiquement les infrastructures des exercices.

```text
aws/
├── README.md
├── budgets/
│   └── p5-monthly-budget.json.example
└── iam/
    └── p5-lab-policy.json
```

## Principes

- le compte root reste réservé aux opérations qui l'exigent ;
- le profil `p5-lab` utilise de préférence IAM Identity Center ou un rôle ;
- aucune clé d'accès n'est enregistrée dans le dépôt ;
- le compte AWS attendu est verrouillé dans Terraform ;
- les ressources reçoivent des tags communs ;
- un budget mensuel doit exister avant le premier déploiement ;
- la vérification AWS est non destructive ;
- la création du budget exige explicitement l'option `--apply`.

## Ordre d'utilisation

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env

./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/check-aws-readiness.sh --stage initial
```

Après les exercices et `destroy-aws.sh` :

```bash
./scripts/commands/check-aws-cleanup.sh
```

## Politique IAM

[`iam/p5-lab-policy.json`](iam/p5-lab-policy.json) est une politique de lab
limitée aux services utilisés par le projet : EC2/VPC, OpenSearch, Service
Quotas, AWS Budgets et les lectures d'identité nécessaires.

Elle constitue un socle pédagogique. Son rattachement à un rôle ou à un jeu
d'autorisations IAM Identity Center reste une opération d'administration
explicite. Le dépôt ne crée pas d'identité IAM et ne manipule aucun secret.

## Budget

Le fichier
[`budgets/p5-monthly-budget.json.example`](budgets/p5-monthly-budget.json.example)
illustre le budget créé par le script. Le montant, le nom et l'adresse de
notification proviennent du fichier local `environment/aws-readiness.env`.
