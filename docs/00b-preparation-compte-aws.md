# Étape 0B — Préparer et valider le compte AWS

Cette étape transforme un compte AWS existant en environnement **autorisé,
contrôlé et prêt pour Terraform**.

Le parcours normal est piloté par :

```bash
bash scripts/commands/p5.sh all
```

La connexion AWS, la détection du compte, l'IPv4, la clé SSH, les `tfvars`, le
budget et les contrôles sont alors enchaînés automatiquement autant que possible.

## Résultat attendu

```text
AWS PRÊT
        ↓
GO AWS
        ↓
GO TERRAFORM
```

Un `KO`, un `STOP AWS` ou l'absence de `GO TERRAFORM` bloque le déploiement.

![Préparation et porte de validation](schemas/etape-0.svg)

## Ce que l'utilisateur fait réellement

Sur une VM déjà préparée :

```bash
cd ~/p5_Openclassrooms
git pull
bash scripts/commands/p5.sh all
```

Si aucune session AWS n'est active, le script propose par défaut :

```text
Connexion AWS — navigateur externe
```

La VM lance `aws login --remote`, affiche les instructions AWS et vous demande
d'ouvrir l'URL d'autorisation dans votre navigateur habituel.

Vous saisissez vos identifiants **directement chez AWS**. Le projet ne demande
jamais votre mot de passe, votre secret AWS ou une clé d'accès.

Après l'autorisation, le script reprend automatiquement.

## 1. Préparation unique du compte AWS

Avant le premier lab, quelques actions administratives restent volontairement
humaines.

### Compte root

Dans la console AWS :

1. activer le MFA root ;
2. vérifier qu'aucune clé d'accès root n'existe ;
3. vérifier les moyens de récupération ;
4. vérifier les contacts de facturation ;
5. ne pas utiliser root pour le projet quotidien.

### Identité quotidienne

Le projet attend une identité IAM, un rôle ou IAM Identity Center.

Pour la connexion console moderne avec `aws login`, l'identité doit avoir la
politique AWS gérée :

```text
SignInLocalDevelopmentAccess
```

Elle autorise le flux OAuth utilisé par AWS CLI pour remettre des credentials
temporaires.

L'identité doit également posséder les permissions nécessaires au projet. La
politique de référence est :

[`aws/iam/p5-lab-policy.json`](../aws/iam/p5-lab-policy.json).

Ces politiques sont distinctes :

```text
SignInLocalDevelopmentAccess
        ↓
autorise la connexion CLI temporaire

p5-lab-policy.json
        ↓
autorise EC2/VPC/OpenSearch/Budgets/quotas du P5
```

Le dépôt ne crée pas automatiquement un utilisateur IAM à partir du compte root.

## 2. Authentification automatisée

Le script spécialisé est :

```bash
bash scripts/commands/aws-auth.sh
```

Le mode `auto` est utilisé par défaut.

### Cas A — session encore valide

Le script vérifie :

```bash
aws sts get-caller-identity --profile p5-lab
```

Si l'identité est correcte, non root et temporaire, aucune action n'est demandée.

### Cas B — session console expirée

Le script relance automatiquement :

```bash
aws login --remote --profile p5-signin
```

Puis il reconstruit l'accès de `p5-lab`.

### Cas C — IAM Identity Center

Mode disponible :

```bash
bash scripts/commands/aws-auth.sh --mode sso
```

Le script utilise `aws configure sso` si nécessaire puis `aws sso login`.

### Cas D — profil temporaire existant

```bash
bash scripts/commands/aws-auth.sh --mode existing
```

Le profil source doit fournir des credentials temporaires avec une expiration.
Les clés longues durées ne sont pas le chemin normal du projet.

## 3. Pourquoi deux profils avec `aws login` ?

Le profil `p5-signin` porte la session créée par AWS CLI :

```text
[profile p5-signin]
login_session = ...
region = us-east-1
```

Le projet prépare ensuite :

```text
[profile p5-lab]
credential_process = aws configure export-credentials --profile p5-signin --format process
region = us-east-1
```

Ce mécanisme fournit à Terraform des credentials temporaires dans le format
standard `credential_process`.

Ainsi :

```text
connexion console AWS
        ↓
AWS CLI session temporaire
        ↓
p5-signin
        ↓
credential_process
        ↓
p5-lab
        ↓
AWS CLI + Terraform
```

## 4. Configuration locale automatique

`configure-lab.sh` crée ou complète :

```text
environment/aws-readiness.env
```

Ce fichier est ignoré par Git et ne contient aucune clé AWS.

Il mémorise notamment :

| Variable | Rôle |
| --- | --- |
| `AWS_PROFILE` | profil final, normalement `p5-lab` |
| `AWS_REGION` | région commune |
| `P5_AWS_AUTH_MODE` | `auto`, `console`, `sso` ou `existing` |
| `P5_AWS_LOGIN_PROFILE` | profil source de connexion |
| `P5_EXPECTED_ACCOUNT_ID` | compte détecté |
| `P5_PUBLIC_IP_CIDR` | IPv4 actuelle en `/32` |
| `P5_SSH_PUBLIC_KEY_PATH` | clé publique du lab |
| `P5_OPENSEARCH_ENGINE` | moteur OpenSearch |
| `P5_BUDGET_LIMIT_USD` | budget mensuel du lab |

Les trois `terraform.tfvars` sont générés depuis cette source unique.

## 5. Détection automatique

Après l'authentification, `configure-lab.sh` :

1. lit l'identité STS ;
2. refuse `root` ;
3. vérifie que les credentials temporaires sont exportables ;
4. récupère l'identifiant de compte AWS ;
5. détecte l'IPv4 publique actuelle ;
6. construit automatiquement le `/32` ;
7. crée une clé SSH Ed25519 si elle manque ;
8. demande l'adresse de notification du budget si nécessaire ;
9. demande les confirmations humaines de sécurité ;
10. génère et vérifie les trois `terraform.tfvars`.

## 6. Budget

Le centre de commande prévisualise puis propose de créer le budget AWS :

```text
p5-lab-monthly
```

Valeur de référence :

```text
20 USD / mois
```

avec alertes aux seuils documentés par le projet.

Le budget ne crée aucune EC2 ni aucun domaine OpenSearch.

## 7. AWS Ready

Le contrôle non destructif vérifie notamment :

- profil et région ;
- identité active et non root ;
- compte exact ;
- credentials temporaires ;
- IPv4 actuelle `/32` ;
- disponibilité d'au moins deux AZ ;
- type EC2 ;
- AMI Ubuntu Canonical ;
- quota EC2 Standard ;
- disponibilité OpenSearch ;
- limites OpenSearch ;
- budget ;
- cohérence des `terraform.tfvars` ;
- collisions de ressources ;
- dépendances entre exercices.

Commandes spécialisées :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

## 8. OpenSearch / « Elasticsearch »

Le projet n'installe pas Elasticsearch dans la VM.

Le vrai exercice crée avec Terraform un service managé :

```text
Amazon OpenSearch Service
```

Le domaine de référence utilise :

- `OpenSearch_2.19` ;
- `t3.small.search` ;
- 10 Gio `gp3` ;
- HTTPS ;
- TLS 1.2 minimum ;
- chiffrement au repos ;
- chiffrement inter-nœuds ;
- accès limité à l'IPv4 `/32` du lab.

Docker sur la VM sert seulement à lancer un OpenSearch local éphémère dans les
tests de validation. Aucun service OpenSearch permanent n'est nécessaire sur
Ubuntu.

## 9. Précontrôle Terraform

Avant l'application des ressources :

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le verdict attendu est :

```text
Verdict : GO TERRAFORM — relisez le plan et les coûts avant apply.
```

Même en mode automatisé, le plan Terraform reste affiché avant `apply`.

## 10. Ce qui reste volontairement humain

L'automatisation ne doit pas simuler :

- la saisie de vos identifiants AWS ;
- la validation MFA ;
- la confirmation de la sécurité root ;
- la confirmation des contacts de facturation ;
- la lecture du plan Terraform ;
- les captures du dashboard OpenSearch ;
- la destruction finale `DETRUIRE`.

Ces étapes sont des garde-fous, pas des manques d'automatisation.

## 11. Reconnexion ultérieure

Lors d'une session suivante :

```bash
bash scripts/commands/p5.sh all
```

Si AWS est encore authentifié, le projet continue directement. Si la session a
expiré, `aws-auth.sh` la renouvelle et le parcours reprend.

## 12. Nettoyage

Après les trois exercices :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste actif pour détecter une éventuelle ressource oubliée.

## Limites honnêtes

Le dépôt ne peut pas garantir automatiquement :

- que le MFA root a réellement été configuré ;
- que la politique `SignInLocalDevelopmentAccess` a été attachée avant la
  première connexion ;
- que la politique P5 a été administrativement rattachée au bon utilisateur ou
  rôle ;
- qu'AWS acceptera immédiatement une demande d'augmentation de quota ;
- que le moyen de paiement ou les contacts de facturation sont corrects.

Une fois ces prérequis administratifs faits, l'exécution technique est prise en
charge par le centre de commande.

## Étape suivante

Une fois `GO TERRAFORM` obtenu :

[Exercice 1 — Terraform, Ansible et Angular](exercices/01-terraform-ansible.md).
