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

## Connexion AWS recommandée

Le chemin normal depuis la VM est désormais :

```bash
bash scripts/commands/p5.sh all
```

Pendant `prepare`, le projet appelle automatiquement :

```text
configure-lab.sh
        ↓
aws-auth.sh
        ↓
AWS CLI
```

Si aucune session n'est disponible, `aws-auth.sh` propose par défaut une
connexion avec les identifiants de console AWS :

```bash
aws login --remote --profile p5-signin
```

La VM affiche une URL et les instructions d'autorisation. L'utilisateur ouvre
AWS dans son navigateur habituel et saisit ses identifiants directement chez
AWS. Le dépôt ne voit jamais le mot de passe et ne stocke aucune clé d'accès.

AWS CLI crée une session temporaire. Le projet prépare ensuite `p5-lab` avec un
`credential_process` qui exporte ces credentials :

```text
[profile p5-lab]
credential_process = aws configure export-credentials --profile p5-signin --format process
region = us-east-1
```

Ce pont est volontaire : AWS CLI et Terraform utilisent ainsi la même session
temporaire, y compris avec des outils qui ne savent pas lire directement une
session `aws login`.

## Prérequis de l'identité

Le projet refuse le compte root pour l'exécution quotidienne.

Pour le mode `aws login`, l'utilisateur ou rôle utilisé dans la console doit
avoir :

- la politique AWS gérée `SignInLocalDevelopmentAccess` ;
- les permissions nécessaires au P5, documentées par
  [`iam/p5-lab-policy.json`](iam/p5-lab-policy.json).

Le rattachement des politiques à l'identité reste une opération administrative
AWS. Le dépôt ne crée pas automatiquement un utilisateur IAM et n'utilise pas le
compte root pour fabriquer une identité plus privilégiée.

Autres modes disponibles :

```bash
bash scripts/commands/aws-auth.sh --mode sso
bash scripts/commands/aws-auth.sh --mode existing
```

Le premier utilise IAM Identity Center. Le second accepte un profil existant
uniquement s'il fournit des credentials temporaires avec expiration.

## Sécurité du compte root

Le compte root reste réservé aux opérations qui l'exigent. Avant le lab :

- MFA root activé et vérifié ;
- aucune clé d'accès root ;
- contacts de récupération/facturation vérifiés ;
- identité quotidienne non root prête.

Ces points restent des validations humaines explicites dans le parcours.

## Politique du lab

La politique [`iam/p5-lab-policy.json`](iam/p5-lab-policy.json) constitue un socle
pédagogique limité aux services nécessaires au P5 : EC2/VPC, OpenSearch,
Service Quotas, AWS Budgets et lectures d'identité.

Elle est distincte de `SignInLocalDevelopmentAccess` :

- `SignInLocalDevelopmentAccess` permet à `aws login` d'obtenir une session
  temporaire ;
- `p5-lab-policy.json` permet ensuite au projet de lire/créer/supprimer les
  ressources nécessaires au lab.

## Configuration locale

`configure-lab.sh` crée automatiquement, si nécessaire :

```text
environment/aws-readiness.env
```

Ce fichier reste local et ignoré par Git. Il contient des paramètres, jamais des
clés AWS :

- profil et région ;
- compte AWS détecté ;
- méthode d'authentification ;
- IPv4 publique `/32` ;
- clé SSH publique ;
- paramètres EC2/OpenSearch ;
- budget ;
- confirmations de sécurité.

Les trois `terraform.tfvars` sont ensuite générés depuis cette source unique.

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
- source de credentials temporaires ;
- confirmations de sécurité manuelles ;
- IPv4 publique actuelle en `/32` ;
- zones de disponibilité ;
- disponibilité du type EC2 et de l'AMI Ubuntu ;
- quota régional EC2 Standard ;
- compatibilité OpenSearch ;
- présence du budget ;
- cohérence des `terraform.tfvars` ;
- collisions ou dépendances propres à l'étape.

Un `KO` interdit de continuer.

## OpenSearch

Le vrai exercice utilise **Amazon OpenSearch Service**, créé par Terraform.
Aucun Elasticsearch/OpenSearch système n'a besoin d'être installé dans Ubuntu.

La VM contient Docker afin de pouvoir lancer, lors des validations locales, un
OpenSearch éphémère servant uniquement à tester le template, l'import Bulk et
les agrégations. Ce conteneur n'est pas l'infrastructure remise pour l'exercice.

Le domaine AWS est configuré avec les garde-fous du projet, notamment HTTPS/TLS,
chiffrement et limitation d'accès à l'IPv4 `/32` du lab.

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

Les instances EC2 imposent IMDSv2 et des volumes racine chiffrés. OpenSearch
impose HTTPS, TLS 1.2 minimum, chiffrement au repos et entre les nœuds.

## Nettoyage

La fermeture complète du lab reste séparée de la préparation :

```bash
bash scripts/commands/p5.sh cleanup
```

L'ordre de destruction est :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

L'audit final recherche les ressources P5 restantes. Le verdict recherché est :

```text
NETTOYAGE AWS COMPLET
```

## Données interdites

Ne jamais versionner :

- clés AWS ;
- jetons de session ;
- clés privées SSH ;
- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états Terraform ;
- sorties runtime contenant des identifiants ou endpoints non relus.

Les caches temporaires AWS restent gérés sous le répertoire utilisateur de la VM
par l'AWS CLI, jamais dans le dépôt.

Contrôle local :

```bash
python3 scripts/tools/audit_secrets.py
```

## Références

- [Préparation AWS complète](../docs/00b-preparation-compte-aws.md)
- [Architecture du projet](../docs/architecture-et-flux.md)
- [Validation, preuves et nettoyage](../docs/validation-preuves-nettoyage.md)
- [Politique de sécurité](../SECURITY.md)
