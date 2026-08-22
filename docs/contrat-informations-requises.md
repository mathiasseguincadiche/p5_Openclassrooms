# Contrat des informations requises

## Objectif

Le P5 doit savoir distinguer trois catégories :

1. information **détectable automatiquement** ;
2. information **fournie par l'opérateur** ;
3. information **autoritaire issue de Terraform/AWS**.

Une valeur ne doit jamais être inventée simplement pour permettre à l'orchestrateur de continuer.

## Principe

```text
peut être détecté ?
  ├── oui → détecter et valider
  └── non → expliquer le besoin et demander

provient de Terraform/AWS ?
  └── absent/invalide → état INCONNU + arrêt
```

## Fichier local principal

```text
environment/aws-readiness.env
```

Il est créé à partir de :

```text
environment/aws-readiness.env.example
```

Il est ignoré par Git et ne doit contenir aucune clé secrète AWS.

## Paramètres AWS

### `AWS_PROFILE`

Rôle : profil AWS utilisé par le lab.

Référence du modèle :

```text
p5-lab
```

Vérification :

```bash
aws sts get-caller-identity --profile p5-lab
```

### `AWS_REGION`

Rôle : région AWS utilisée par les trois modules Terraform.

Référence :

```text
us-east-1
```

La région doit rester cohérente avec les ressources, quotas et AMI.

### `P5_AWS_AUTH_MODE`

Rôle : stratégie d'authentification temporaire.

Référence :

```text
auto
```

Le projet privilégie les sessions temporaires plutôt que les clés statiques longue durée.

Sous WSL2, le contrat d'authentification console est :

```text
console            → aws login --remote, recommandé
console-remote     → alias explicite du flux cross-device
console-localhost  → callback localhost same-device, mode avancé
auto               → réutilise/renouvelle puis choisit le flux adapté
sso                → IAM Identity Center
existing           → profil temporaire existant
```

Le flux cross-device est privilégié sous WSL2 car il ne dépend pas de l'existence d'un listener OAuth sur `127.0.0.1` côté Linux. Le code d'autorisation affiché par AWS est à usage unique et ne doit jamais être stocké dans la configuration, la documentation ou les preuves.

Si le profil source est encore associé à root, le moteur doit avertir l'opérateur avant `aws login`. Le remplacement n'est validé que si AWS propose explicitement une identité IAM/rôle non-root attendue.

### `P5_AWS_LOGIN_PROFILE`

Rôle : profil source géré par `aws login`.

Référence :

```text
p5-signin
```

Le profil final `p5-lab` consomme ensuite les credentials temporaires de ce profil via `credential_process`.

## Identité et compte

### `P5_EXPECTED_ACCOUNT_ID`

Cette valeur doit provenir de :

```bash
aws sts get-caller-identity
```

Elle est ensuite injectée dans :

```text
expected_aws_account_id
```

pour les trois modules Terraform.

Le provider utilise `allowed_account_ids` afin de refuser un autre compte.

## Réseau d'administration

### `P5_PUBLIC_IP_CIDR`

Format obligatoire :

```text
IPv4/32
```

Exemple :

```text
198.51.100.42/32
```

Utilisation :

- SSH exercices 1 et 3 ;
- accès OpenSearch.

Si la détection automatique échoue, le moteur doit expliquer le format et demander l'IPv4 réelle.

## EC2

### `P5_AMI_ID`

Peut rester vide.

Si vide, Terraform sélectionne l'AMI Ubuntu 24.04 LTS selon les filtres du module.

Une valeur explicite ne doit être fournie que si l'opérateur comprend qu'une AMI est régionale et architecture-dépendante.

### `P5_EC2_INSTANCE_TYPE`

Référence :

```text
t3.micro
```

Cette valeur est configurable afin de tenir compte du quota et des variations des consignes.

### `P5_KEY_NAME`

Nom de la paire de clés EC2 :

```text
p5-key
```

### `P5_SSH_KEY_PATH`

Chemin local de la clé privée :

```text
~/.ssh/p5-key
```

### `P5_SSH_PUBLIC_KEY_PATH`

Clé publique injectée dans Terraform :

```text
~/.ssh/p5-key.pub
```

La clé privée est une donnée locale sensible et ne doit jamais être versionnée.

## OpenSearch

### `P5_OPENSEARCH_INSTANCE_TYPE`

Référence :

```text
t3.small.search
```

### `P5_OPENSEARCH_ENGINE`

Référence :

```text
OpenSearch_2.19
```

### `P5_OPENSEARCH_DOMAIN`

Référence :

```text
p5-opensearch
```

### `P5_OPENSEARCH_VOLUME_SIZE_GB`

Référence :

```text
10
```

Ces valeurs sont synchronisées vers les variables Terraform de l'exercice 2.

## Quota

### `P5_REQUIRED_STANDARD_VCPUS`

Référence :

```text
8
```

Elle représente le besoin potentiel lorsque l'EC2 de l'exercice 1 et les trois EC2 de l'exercice 3 coexistent avec des types `t3.micro`.

Ce contrôle réduit les échecs tardifs liés aux quotas.

## Budget

### `P5_BUDGET_NAME`

```text
p5-lab-monthly
```

### `P5_BUDGET_LIMIT_USD`

```text
20
```

### `P5_BUDGET_EMAIL`

Doit devenir une adresse réelle et valide.

Le budget ne bloque pas automatiquement la consommation. Il sert d'alerte.

## Confirmations de sécurité

Le modèle contient plusieurs valeurs `no` qui ne doivent passer à `yes` qu'après vérification réelle :

```text
P5_ROOT_MFA_CONFIRMED
P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED
P5_IAM_POLICY_ATTACHED_CONFIRMED
P5_BILLING_CONTACTS_CONFIRMED
```

Ces éléments ne sont pas déduits de façon fiable par l'orchestrateur. La confirmation humaine est donc conservée.

## Synchronisation vers Terraform

La commande :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

compare la configuration locale aux trois `terraform.tfvars`.

La convergence utilise :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Les vrais `tfvars` :

```text
terraform/exercice-1/terraform.tfvars
terraform/exercice-2/terraform.tfvars
terraform/exercice-3/terraform.tfvars
```

restent hors Git.

## Informations autoritaires produites par Terraform

Certaines valeurs ne doivent jamais être demandées à l'utilisateur si Terraform est censé les produire.

### Exercice 1

```text
web_public_ip
web_url
```

### Exercice 2

```text
opensearch_endpoint
opensearch_dashboards_endpoint
```

### Exercice 3

```text
haproxy_url
hello_1_public_ip
```

Le runtime utilise une fonction de lecture/validation des outputs. Si l'output est absent ou invalide, il produit un état **INCONNU** et indique comment réparer la source.

## Pourquoi cette règle est importante

Mauvais comportement :

```text
output Terraform absent
→ prendre une IP vue dans la console
→ continuer silencieusement
```

Bon comportement :

```text
output Terraform absent
→ arrêter
→ vérifier state/module
→ réparer Terraform
→ relire l'output
```

C'est ce qui garantit que les preuves et les actions suivantes ciblent les ressources réellement gérées par le projet.

## Données interdites dans ce contrat

Ne jamais stocker dans `aws-readiness.env` ou dans la documentation :

- AWS secret access key ;
- session token ;
- code d'autorisation `aws login --remote` ;
- clé SSH privée ;
- token GitHub ;
- bearer token ;
- state Terraform ;
- credentials exportés.

## Commande normale

L'opérateur n'a pas besoin d'éditer manuellement toutes ces valeurs. Le parcours recommandé est :

```bash
bash scripts/commands/p5.sh prepare
```

Le configurateur doit expliquer ce qu'il demande, valider le format et réutiliser ce qui est déjà conforme.
