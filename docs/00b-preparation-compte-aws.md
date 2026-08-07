# Étape 0B — Préparer et valider le compte AWS

Cette étape transforme un compte AWS disponible en environnement **autorisé,
contrôlé et prêt pour Terraform**.

Elle complète [l’étape 0A — préparation de la VM](00-preparation-environnement.md)
et doit être terminée avant le premier déploiement.

## Résultat attendu

Deux validations sont recherchées :

```text
Verdict : GO AWS — compte, région, capacité et coûts contrôlés.
Verdict : GO TERRAFORM — relisez le plan et les coûts avant apply.
```

Un `STOP AWS`, un `KO` ou l’absence de `GO TERRAFORM` interdit de poursuivre
vers `terraform apply`.

![Préparation et porte de validation](schemas/etape-0.svg)

## Principe de configuration

Le projet possède une **source locale unique** pour les paramètres liés au
compte :

```text
environment/aws-readiness.env
        │
        ▼
sync-terraform-tfvars.sh
        │
        ├─ terraform/exercice-1/terraform.tfvars
        ├─ terraform/exercice-2/terraform.tfvars
        └─ terraform/exercice-3/terraform.tfvars
```

Les trois `terraform.tfvars` ne doivent pas être maintenus manuellement comme
trois configurations indépendantes.

## 1. Sécuriser le compte root

Dans la console AWS :

1. activer plusieurs moyens MFA pour le compte root lorsque cela est possible ;
2. vérifier qu’aucune clé d’accès root n’existe ;
3. vérifier l’adresse électronique et le numéro de récupération ;
4. vérifier les contacts de facturation ;
5. réserver le compte root aux seules opérations qui l’exigent.

Ces points ne peuvent pas être certifiés de façon fiable depuis une session CLI
quotidienne. Ils sont donc confirmés explicitement dans le fichier local de
readiness.

## 2. Préparer l’identité quotidienne

Le parcours recommandé utilise des identifiants temporaires avec IAM Identity
Center ou un rôle IAM.

### IAM Identity Center

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

### Rôle IAM existant

Un rôle fourni par une organisation peut également être utilisé si le profil
`p5-lab` l’assume correctement.

Les clés d’accès longues durées sont refusées par défaut lorsque
`P5_REQUIRE_TEMPORARY_CREDENTIALS=yes`.

La politique pédagogique de référence est :
[`aws/iam/p5-lab-policy.json`](../aws/iam/p5-lab-policy.json).

Son rattachement à une identité reste une opération d’administration explicite.
Le dépôt ne crée aucune identité IAM et ne stocke aucun secret.

## 3. Créer la configuration locale

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Le fichier réel est ignoré par Git.

### Variables principales

| Variable | Rôle | Valeur de référence |
| --- | --- | --- |
| `AWS_PROFILE` | profil AWS CLI | `p5-lab` |
| `AWS_REGION` | région commune | `us-east-1` |
| `P5_EXPECTED_ACCOUNT_ID` | seul compte autorisé | à renseigner |
| `P5_PUBLIC_IP_CIDR` | poste d’administration | IPv4 réelle `/32` |
| `P5_EC2_INSTANCE_TYPE` | EC2 exercices 1 et 3 | `t3.micro` |
| `P5_AMI_ID` | surcharge AMI optionnelle | vide = Ubuntu 24.04 auto |
| `P5_KEY_NAME` | paire de clés EC2 | `p5-key` |
| `P5_SSH_PUBLIC_KEY_PATH` | clé publique locale | `~/.ssh/p5-key.pub` |
| `P5_OPENSEARCH_ENGINE` | moteur | `OpenSearch_2.19` |
| `P5_OPENSEARCH_INSTANCE_TYPE` | nœud OpenSearch | `t3.small.search` |
| `P5_OPENSEARCH_VOLUME_SIZE_GB` | EBS OpenSearch | `10` |
| `P5_REQUIRED_STANDARD_VCPUS` | quota EC2 minimal visé | `8` |
| `P5_BUDGET_LIMIT_USD` | seuil mensuel du lab | `20` |

Les montants, quotas et tailles sont des références de lab, **pas une promesse
de gratuité**.

## 4. Synchroniser les variables Terraform

Prévisualiser les trois fichiers générés :

```bash
bash scripts/commands/sync-terraform-tfvars.sh
```

Écrire les fichiers locaux :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Vérifier leur synchronisation :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Le script :

- refuse le compte d’exemple `000000000000` ;
- refuse l’IP de documentation `203.0.113.10/32` ;
- génère les trois fichiers depuis la même source ;
- écrit les fichiers en mode `600` ;
- utilise `null` pour l’AMI si `P5_AMI_ID` est vide.

Après tout changement de région, compte, adresse IP, clé ou taille de ressource,
relancez `--apply` puis `--check`.

## 5. Prévisualiser puis créer le budget

Aperçu non destructif :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Création explicite :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Le budget mensuel utilise les paramètres du fichier local et prévoit trois
alertes :

- 50 % des dépenses réelles ;
- 80 % des dépenses réelles ;
- 100 % des dépenses prévues.

Le script ne crée aucune instance EC2 ni aucun domaine OpenSearch.

## 6. Exécuter AWS Ready

### Avant l’exercice 1

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

### Avant l’exercice 2

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

### Avant l’exercice 3

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

## 7. Ce que vérifie AWS Ready

### Configuration et identité

- variables obligatoires ;
- compte AWS réel à 12 chiffres ;
- profil AWS CLI ;
- région du profil ;
- identité active ;
- identité non root ;
- source de session temporaire ou rôle lorsque le mode strict l’exige.

### Sécurité manuelle

- MFA root confirmé ;
- absence de clés d’accès root confirmée ;
- politique IAM du lab rattachée ;
- contacts de facturation vérifiés.

### Réseau du poste

- IPv4 publique actuelle ;
- correspondance exacte avec le `/32` configuré.

### Région et capacité

- au moins deux zones de disponibilité ;
- type EC2 proposé dans la région ;
- AMI Ubuntu Canonical disponible ;
- quota EC2 Standard suffisant.

### OpenSearch

- combinaison version/type d’instance disponible ;
- limites du type consultables.

### Coûts

- budget du lab présent.

### Cohérence Terraform

Pour chaque module :

- région identique ;
- compte attendu identique ;
- adresse `/32` identique.

### État préalable selon l’étape

Le contrôle adapte les collisions et dépendances :

- `initial` : aucun VPC, clé ou domaine P5 conflictuel ;
- `exercice-2` : domaine OpenSearch absent avant création ;
- `exercice-3` : VPC et clé de l’exercice 1 présents.

## 8. Lancer le précontrôle unifié

Après AWS Ready :

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le script vérifie en plus :

- Ubuntu et versions ;
- outils ;
- Docker ;
- paire SSH ;
- fichiers tfvars ;
- synchronisation avec `aws-readiness.env` ;
- application Angular et artefact Ansible ;
- composants propres à l’étape ;
- validation locale du dépôt.

Le verdict attendu est :

```text
Verdict : GO TERRAFORM — relisez le plan et les coûts avant apply.
```

## 9. Garde-fous Terraform

Chaque provider Terraform utilise :

- `allowed_account_ids` pour interdire un autre compte ;
- des tags communs pour identifier le projet ;
- des validations refusant les valeurs d’exemple ;
- une adresse d’administration strictement limitée à `/32`.

Les EC2 des exercices 1 et 3 imposent également :

- IMDSv2 ;
- volume racine chiffré ;
- suppression du volume à la terminaison.

OpenSearch impose :

- HTTPS ;
- TLS 1.2 minimum ;
- chiffrement au repos ;
- chiffrement entre nœuds ;
- politique d’accès limitée à l’IP `/32`.

## 10. Que faire si le contrôle bloque ?

Ne contournez pas le garde-fou. Utilisez :

- [Troubleshooting](troubleshooting.md) ;
- le diagnostic partageable :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Causes fréquentes :

- session SSO expirée ;
- changement d’IP publique ;
- tfvars désynchronisés ;
- budget absent ;
- quota insuffisant ;
- ressource P5 déjà présente ;
- exercice 1 détruit avant l’exercice 3.

## 11. Nettoyage final

Après les trois exercices et les preuves :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Le second script est un **audit global** du P5. Il recherche notamment EC2, EBS,
interfaces réseau, groupes de sécurité, sous-réseaux, routage, Internet Gateway,
VPC, paire de clés et OpenSearch.

Le verdict final attendu est :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste volontairement actif pour détecter un oubli.

## Limites honnêtes

Le dépôt ne peut pas garantir à lui seul :

- l’état réel du MFA root ;
- l’absence de clés root sans droits adaptés ;
- la validité du moyen de paiement ;
- l’approbation d’une augmentation de quota ;
- la réception d’un courriel de budget ;
- l’absence de ressources hors du périmètre inspecté par les scripts.

Ces points restent sous la responsabilité du propriétaire du compte et doivent
être vérifiés humainement.

## Étape suivante

Une fois `GO TERRAFORM` obtenu :

[Exercice 1 — Terraform, Ansible et Angular](exercices/01-terraform-ansible.md).
