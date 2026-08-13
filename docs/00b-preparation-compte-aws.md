# 00B — Préparer et sécuriser le compte AWS

## Objectif

Cette étape prépare le compte AWS **avant la création de ressources facturables**.

Le but n'est pas seulement de rendre `terraform apply` possible. Il faut aussi s'assurer que :

- le bon compte est utilisé ;
- l'authentification est adaptée à un lab ;
- le compte root n'est pas utilisé pour l'exploitation normale ;
- l'accès SSH est limité au poste courant ;
- les quotas sont suffisants ;
- un budget existe ;
- les valeurs utilisées par les trois modules Terraform sont cohérentes.

## Source locale de configuration

Le modèle versionné est :

```text
environment/aws-readiness.env.example
```

Le fichier réel créé localement est :

```text
environment/aws-readiness.env
```

Ce dernier est **ignoré par Git**.

Il ne doit contenir aucune clé secrète AWS. Il contient uniquement les paramètres nécessaires au lab : profil, région, compte attendu, IP `/32`, types d'instances, chemins SSH, configuration OpenSearch et budget.

## Méthode recommandée

Ne pas copier manuellement le modèle puis remplacer des valeurs au hasard. Utiliser :

```bash
bash scripts/commands/p5.sh prepare
```

Le moteur appelle le configurateur, détecte ce qui peut l'être, demande ce qui ne peut pas être prouvé automatiquement, puis synchronise les `terraform.tfvars`.

## 1. Authentification AWS

Le modèle utilise :

```text
P5_AWS_AUTH_MODE=auto
```

Le mode `auto` cherche d'abord une session valide puis peut proposer une authentification temporaire adaptée au contexte disponible.

Le projet privilégie les identifiants temporaires. La configuration contient :

```text
P5_REQUIRE_TEMPORARY_CREDENTIALS=yes
```

### Pourquoi

Une clé d'accès statique longue durée augmente le risque en cas de fuite. Pour un lab, une session temporaire est préférable et plus simple à révoquer naturellement.

### Contrôle d'identité

La commande fondamentale est :

```bash
aws sts get-caller-identity
```

Elle retourne notamment :

- l'identifiant du compte AWS ;
- l'ARN de l'identité utilisée ;
- l'identifiant utilisateur/session.

Le configurateur utilise cette information pour fixer le compte attendu. Ne pas inventer manuellement un numéro de compte dans le seul but de faire passer Terraform.

## 2. Verrouillage du compte attendu

Les trois providers Terraform utilisent :

```hcl
allowed_account_ids = [var.expected_aws_account_id]
```

La valeur provient de la configuration P5 et est répliquée dans les `terraform.tfvars` locaux.

### Pourquoi ce garde-fou est important

Sans verrouillage, un profil AWS différent pourrait envoyer le même Terraform vers un autre compte. Avec `allowed_account_ids`, Terraform refuse le provider si l'identité courante ne correspond pas au compte attendu.

Le résultat recherché est donc :

```text
identité AWS réelle
        =
P5_EXPECTED_ACCOUNT_ID
        =
expected_aws_account_id Terraform
```

## 3. Choisir la région

Le modèle utilise par défaut :

```text
AWS_REGION=us-east-1
```

La région n'est pas un détail cosmétique :

- les AMI sont régionales ;
- les quotas sont souvent régionaux ;
- les ressources Terraform sont créées dans cette région ;
- les coûts et disponibilités de services peuvent varier.

Le profil et Terraform doivent utiliser la même région.

Vérifier :

```bash
aws configure get region --profile p5-lab
```

et la configuration effective P5 :

```bash
grep '^AWS_REGION=' environment/aws-readiness.env
```

## 4. Restreindre SSH à l'IPv4 publique du poste

La configuration attend :

```text
P5_PUBLIC_IP_CIDR=<IPv4>/32
```

Exemple documentaire :

```text
198.51.100.42/32
```

Le `/32` signifie qu'une seule IPv4 est autorisée.

### Pourquoi ne pas utiliser `0.0.0.0/0` pour SSH

`0.0.0.0/0` exposerait le port 22 à Internet entier. Le P5 n'en a pas besoin.

Les Security Groups des exercices 1 et 3 utilisent la valeur `your_ip_cidr` pour SSH.

Si l'IP publique change, relancer :

```bash
bash scripts/commands/p5.sh prepare
```

puis laisser la synchronisation des `tfvars` mettre à jour la configuration attendue.

## 5. Clé SSH du lab

Valeurs de référence du modèle :

```text
P5_KEY_NAME=p5-key
P5_SSH_KEY_PATH=~/.ssh/p5-key
P5_SSH_PUBLIC_KEY_PATH=~/.ssh/p5-key.pub
```

Terraform utilise **la clé publique** pour créer la paire de clés EC2. SSH et Ansible utilisent la clé privée locale correspondante.

Vérifier les permissions :

```bash
ls -l ~/.ssh/p5-key ~/.ssh/p5-key.pub
```

Une clé privée ne doit jamais être ajoutée au dépôt.

## 6. Types d'instances

Le modèle contient notamment :

```text
P5_EC2_INSTANCE_TYPE=t3.micro
P5_OPENSEARCH_INSTANCE_TYPE=t3.small.search
```

Ces valeurs sont des choix d'implémentation du lab, pas une raison de contourner les quotas du compte.

Les consignes OpenClassrooms ont présenté des valeurs EC2 différentes selon les sections. Le dépôt garde donc le type d'instance **configurable**.

Avant toute création, vérifier :

- que le type est disponible dans la région ;
- que le quota permet le nombre de vCPU requis ;
- que le coût estimé est acceptable.

## 7. Quota EC2

Le projet peut utiliser simultanément :

- une EC2 pour l'exercice 1 ;
- une EC2 HAProxy ;
- deux EC2 backend pour l'exercice 3.

Le modèle prévoit donc :

```text
P5_REQUIRED_STANDARD_VCPUS=8
```

Le contrôle AWS Ready vérifie que le compte ne sera pas bloqué par un quota manifestement insuffisant.

Un quota suffisant **n'autorise pas** automatiquement le déploiement : le plan et le budget doivent encore être lus.

## 8. Amazon OpenSearch

Valeurs de référence :

```text
P5_OPENSEARCH_INSTANCE_TYPE=t3.small.search
P5_OPENSEARCH_ENGINE=OpenSearch_2.19
P5_OPENSEARCH_DOMAIN=p5-opensearch
P5_OPENSEARCH_VOLUME_SIZE_GB=10
```

Le module Terraform active :

- chiffrement au repos ;
- chiffrement node-to-node ;
- HTTPS ;
- TLS 1.2 minimum ;
- restriction par IP publique `/32`.

OpenSearch peut être l'une des ressources les plus coûteuses du lab. Ne pas le laisser tourner inutilement après les captures finales.

## 9. Budget AWS

Le modèle contient :

```text
P5_BUDGET_NAME=p5-lab-monthly
P5_BUDGET_LIMIT_USD=20
P5_BUDGET_EMAIL=<adresse réelle>
```

Le budget est un **garde-fou d'alerte**, pas une limite technique qui coupe automatiquement les ressources.

Le moteur vérifie son existence :

```bash
bash scripts/commands/setup-aws-guardrails.sh --check
```

S'il manque ou diffère, `p5.sh prepare` peut proposer de le converger.

### Important

Une alerte budgétaire n'arrive pas nécessairement immédiatement. Le moyen fiable d'arrêter les coûts du P5 reste la destruction des ressources puis l'audit de nettoyage.

## 10. Confirmations humaines de sécurité

Certaines informations ne peuvent pas être certifiées proprement par le script. Le modèle prévoit notamment :

```text
P5_ROOT_MFA_CONFIRMED=no
P5_ROOT_ACCESS_KEYS_ABSENT_CONFIRMED=no
P5_IAM_POLICY_ATTACHED_CONFIRMED=no
P5_BILLING_CONTACTS_CONFIRMED=no
```

Le configurateur explique la vérification puis demande une confirmation explicite.

Ne pas remplacer `no` par `yes` sans avoir réellement effectué la vérification.

## 11. Politique IAM du lab

Le dépôt fournit :

```text
aws/iam/p5-lab-policy.json
```

Cette politique documente les permissions nécessaires au lab. Elle doit être relue avant attachement à une identité.

Le principe reste le moindre privilège : donner les capacités nécessaires aux trois exercices sans utiliser le compte root.

## 12. Synchronisation des `tfvars`

La source de configuration locale est synchronisée vers :

```text
terraform/exercice-1/terraform.tfvars
terraform/exercice-2/terraform.tfvars
terraform/exercice-3/terraform.tfvars
```

Commande de contrôle :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Commande de convergence utilisée par le moteur lorsque nécessaire :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Les vrais `terraform.tfvars` sont locaux et doivent rester hors Git.

## 13. Précontrôle avant création

La commande normale reste :

```bash
bash scripts/commands/p5.sh status
```

Pour la première création, le moteur utilise également les contrôles de pré-déploiement.

Le but est d'obtenir un environnement où le compte, les variables et les garde-fous sont cohérents avant le premier `terraform apply`.

Un des verdicts structurants du parcours est :

```text
GO TERRAFORM
```

Il signifie que les contrôles nécessaires à Terraform sont satisfaits ; il ne signifie pas qu'il faut appliquer sans lire le plan.

## Checklist avant premier déploiement

- [ ] identité AWS non-root comprise ;
- [ ] compte AWS retourné par STS = compte attendu ;
- [ ] région comprise ;
- [ ] IP publique actuelle enregistrée en `/32` ;
- [ ] clé SSH privée protégée et clé publique disponible ;
- [ ] quota EC2 suffisant ;
- [ ] type OpenSearch acceptable ;
- [ ] budget configuré et adresse d'alerte correcte ;
- [ ] politique IAM relue/attachée selon le besoin ;
- [ ] MFA root et absence de clés root vérifiés ;
- [ ] `terraform.tfvars` synchronisés ;
- [ ] aucun secret suivi par Git.

## Commandes à retenir

```bash
aws sts get-caller-identity
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/sync-terraform-tfvars.sh --check
bash scripts/commands/setup-aws-guardrails.sh --check
python3 scripts/tools/audit_secrets.py
```

Une fois cette étape terminée, poursuivre avec le [parcours pédagogique](01-parcours-debutant.md) ou le [runbook d'exécution guidée](RUNBOOK_EXECUTION_GUIDEE.md).
