# Étape 0B — Préparer et valider le compte AWS

La VM de lab ne suffit pas. Avant le premier `terraform plan`, le compte AWS
doit être sécurisé, authentifié, dimensionné et protégé contre les erreurs de
compte ou de coût.

Cette étape complète
[l'installation de la VM](00-preparation-environnement.md). Elle ne crée aucune
infrastructure des exercices.

## Résultat attendu

Le contrôle final doit produire :

```text
Verdict : GO AWS — compte, région, capacité et coûts contrôlés.
```

Un verdict `STOP AWS` interdit de poursuivre vers `terraform apply`.

## 1. Sécuriser le compte root

Dans la console AWS :

1. activer plusieurs moyens MFA pour le compte root lorsque cela est possible ;
2. vérifier qu'aucune clé d'accès root n'existe ;
3. vérifier l'adresse électronique et le numéro de récupération ;
4. réserver le compte root aux seules opérations qui l'exigent.

Le dépôt ne peut pas confirmer ces points depuis une session quotidienne. Ils
sont donc déclarés manuellement dans le fichier local de readiness.

## 2. Préparer l'identité quotidienne

Le parcours recommandé utilise des identifiants temporaires avec IAM Identity
Center ou un rôle IAM.

Pour IAM Identity Center :

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
```

Pour un rôle déjà fourni par une organisation, configurez le profil afin qu'il
assume ce rôle. Les clés d'accès longues durées restent un mode de dernier
recours et sont refusées par défaut par le contrôle.

La politique de référence du projet se trouve dans
[`aws/iam/p5-lab-policy.json`](../aws/iam/p5-lab-policy.json). Son rattachement
à un rôle ou à un jeu d'autorisations est volontaire et administratif.

## 3. Créer la configuration locale

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Renseignez notamment :

- le profil et la région AWS ;
- l'identifiant du compte autorisé ;
- l'adresse IPv4 publique actuelle en `/32` ;
- l'adresse de notification du budget ;
- les confirmations de sécurité vérifiées dans la console.

Le fichier réel est ignoré par Git. Il ne doit contenir aucune clé AWS.

## 4. Préparer les variables Terraform

Copiez les trois exemples :

```bash
cp terraform/exercice-1/terraform.tfvars.example \
  terraform/exercice-1/terraform.tfvars
cp terraform/exercice-2/terraform.tfvars.example \
  terraform/exercice-2/terraform.tfvars
cp terraform/exercice-3/terraform.tfvars.example \
  terraform/exercice-3/terraform.tfvars
```

Les trois fichiers doivent utiliser exactement le même :

- `aws_region` ;
- `expected_aws_account_id` ;
- `your_ip_cidr`.

Terraform refuse désormais le compte d'exemple et l'adresse IP de
documentation.

## 5. Créer le budget du lab

Commencez par un aperçu :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Puis créez volontairement le budget :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Le script crée un budget mensuel et trois alertes :

- 50 % des dépenses réelles ;
- 80 % des dépenses réelles ;
- 100 % des dépenses prévues.

Il ne modifie pas un budget existant et ne crée aucune ressource EC2 ou
OpenSearch.

## 6. Exécuter le contrôle AWS

Avant l'exercice 1 :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

Avant l'exercice 2 :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Avant l'exercice 3 :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

Le contrôle vérifie sans mutation :

- le profil, le compte et l'identité non root ;
- la présence d'une source de session temporaire ;
- la région du profil ;
- l'adresse publique `/32` actuelle ;
- au moins deux zones de disponibilité ;
- la disponibilité du type EC2 et de l'AMI Ubuntu ;
- le quota régional des instances EC2 Standard ;
- la combinaison de version et de type OpenSearch ;
- la présence du budget ;
- la cohérence des trois fichiers `terraform.tfvars` ;
- les collisions ou dépendances attendues selon l'étape.

Le quota visé est configurable. La valeur proposée est de huit vCPU afin de
permettre une EC2 pour l'exercice 1 et trois EC2 pour l'exercice 3 si les deux
environnements coexistent.

## 7. Garde-fous Terraform

Chaque module utilise :

- `allowed_account_ids` pour bloquer un mauvais compte ;
- des tags communs `Project`, `ManagedBy`, `Purpose` et `Exercise` ;
- des validations qui refusent l'identifiant de compte d'exemple ;
- une validation stricte de l'adresse d'administration en `/32`.

Les identifiants AWS ne sont jamais écrits dans les fichiers Terraform.

## 8. Contrôler le nettoyage

Après les preuves :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Le second script recherche les ressources P5 restantes : EC2, EBS, interfaces,
adresses, groupes de sécurité, sous-réseaux, routage, passerelles, VPC, clé EC2
et domaine OpenSearch.

Le budget reste volontairement actif pour signaler une éventuelle ressource
oubliée.

## Limites honnêtes

Le dépôt ne peut pas garantir depuis une simple session CLI :

- l'état réel du MFA root ;
- l'absence de clés root sans autorisation d'administration adaptée ;
- la validité du moyen de paiement ;
- l'approbation immédiate d'une augmentation de quota ;
- la réception effective d'un courriel de budget.

Ces points sont documentés et bloquants tant qu'ils ne sont pas confirmés, mais
ils restent sous le contrôle du propriétaire du compte AWS.
