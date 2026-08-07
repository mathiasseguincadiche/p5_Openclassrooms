# Environnement de lab — Étapes 0A et 0B

Ce dossier définit le **socle local reproductible** et la **source de configuration
AWS** du projet P5.

```text
environment/
├── README.md
├── apt-packages.txt
├── versions.env
└── aws-readiness.env.example
```

Le fichier réel `environment/aws-readiness.env` est local, ignoré par Git et ne
doit contenir aucune clé d'accès AWS.

## 1. `versions.env` — versions de référence

Ce fichier fixe les versions attendues par le lab et les contrôles :

- Ubuntu Server 26.04 ;
- Node.js 22.22.0 ;
- Ansible Core 2.20.1 ;
- Terraform 1.15.8 ;
- versions des images Docker utilisées par les tests locaux.

Le bootstrap et les validations lisent ce fichier. Pour modifier une version de
référence, il faut donc vérifier le script d'installation, la CI et les tests
associés dans la même évolution.

## 2. Étape 0A — installer et contrôler la VM

Installation :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script installe le socle sans créer de ressource AWS ni configurer de secret.
Terraform est installé depuis l'archive HashiCorp officielle avec vérification
SHA-256. Ansible Core est installé avec `pipx`, Node.js avec NVM et Docker depuis
le dépôt Docker officiel.

Après reconnexion :

```bash
./scripts/commands/setup.sh --check-only
```

Ce contrôle valide la VM et la présence des composants critiques du dépôt.

Guide canonique :
[`docs/00-preparation-environnement.md`](../docs/00-preparation-environnement.md).

## 3. `aws-readiness.env` — source unique des paramètres AWS

Créer la configuration locale :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Ce fichier centralise notamment :

| Catégorie | Variables principales |
| --- | --- |
| Session | `AWS_PROFILE`, `AWS_REGION` |
| Compte | `P5_EXPECTED_ACCOUNT_ID` |
| Réseau d'administration | `P5_PUBLIC_IP_CIDR` |
| EC2 | AMI optionnelle, type d'instance, clé SSH |
| OpenSearch | moteur, type de nœud, domaine, stockage |
| Quotas | vCPU Standard requis |
| Coûts | budget, limite et e-mail de notification |
| Sécurité | confirmations MFA, clés root, IAM et facturation |

Les confirmations `..._CONFIRMED=yes` ne doivent être renseignées qu'après
vérification réelle dans la console AWS.

## 4. Génération des `terraform.tfvars`

Les trois `terraform.tfvars` sont des **sorties générées**, pas des sources de
configuration indépendantes.

Aperçu sans écriture :

```bash
bash scripts/commands/sync-terraform-tfvars.sh
```

Écriture réelle en mode `600` :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Contrôle de cohérence :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Toute modification de région, compte, IP, type d'instance ou paramètres
OpenSearch doit être faite dans `aws-readiness.env`, puis propagée avec ce
script.

## 5. Étape 0B — garde-fous AWS

Prévisualiser la création du budget :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Créer explicitement le budget :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Puis vérifier le compte :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le premier contrôle est centré sur le compte, l'identité, les quotas, les coûts
et les dépendances AWS. Le second ajoute la cohérence locale du dépôt, des
versions, de la clé SSH et des variables Terraform.

Verdicts recherchés :

```text
GO AWS
GO TERRAFORM
```

Guide canonique :
[`docs/00b-preparation-compte-aws.md`](../docs/00b-preparation-compte-aws.md).

## 6. Ce qui ne doit jamais être versionné

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- preuves runtime brutes.

Ces exclusions sont protégées par `.gitignore`, `audit_secrets.py` et la CI.

## 7. Quand mettre à jour ce dossier

Modifier `environment/` lorsqu'une évolution concerne :

- la version officielle d'un outil du lab ;
- une variable de configuration réellement utilisée ;
- une nouvelle vérification AWS transversale ;
- un nouveau garde-fou nécessaire avant Terraform.

Éviter d'ajouter ici des variables propres à une seule commande si elles ne
participent pas au contrat global du lab.

## Références

- [Architecture et flux](../docs/architecture-et-flux.md)
- [Parcours complet](../docs/01-parcours-debutant.md)
- [Garde-fous AWS](../aws/README.md)
- [Troubleshooting](../docs/troubleshooting.md)
