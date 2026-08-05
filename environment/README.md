# Environnement de lab — Étapes 0A et 0B

Ce dossier centralise le **poste de contrôle** du P5 et sa configuration AWS
locale. La VM utilise Ubuntu Server 26.04 LTS « Resolute Raccoon » et reste
administrée en ligne de commande.

```text
environment/
├── README.md
├── apt-packages.txt             # paquets système utiles au lab
├── versions.env                 # versions exactes de référence
└── aws-readiness.env.example    # paramètres AWS et Terraform sans secret
```

Le fichier réel `aws-readiness.env` est local et ignoré par Git.

## Étape 0A — Socle de la VM

L’installation est effectuée par :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Terraform est installé depuis l’archive officielle avec vérification SHA-256,
sans dépendre de la disponibilité d’un dépôt APT pour Ubuntu 26.04. Ansible Core
est installé avec `pipx` dans la version exacte déclarée dans `versions.env`.

Le contrôle local est effectué par :

```bash
./scripts/commands/setup.sh --check-only
```

Le socle comprend OpenSSH, Git, Terraform, Ansible Core, AWS CLI v2, Node.js,
npm, Docker, ShellCheck, yamllint et les outils de diagnostic.

## Étape 0B — AWS Ready

Préparez le fichier local :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Générez ensuite les trois fichiers Terraform depuis cette source unique :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Puis exécutez :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le contrôle pré-déploiement refuse le verdict `GO TERRAFORM` si un
`terraform.tfvars` diverge de `aws-readiness.env`. Il vérifie également le compte
autorisé, l’identité, la région, l’adresse `/32`, les quotas, EC2, OpenSearch et
le budget. Il ne crée aucune infrastructure des exercices.

Le bootstrap ne lance ni `aws configure`, ni `terraform apply`, ni création de
clé SSH. La création du budget exige explicitement `--apply`. Les secrets et les
décisions d’accès restent sous le contrôle de l’utilisateur.

Procédures complètes :

- [préparation de la VM](../docs/00-preparation-environnement.md) ;
- [préparation du compte AWS](../docs/00b-preparation-compte-aws.md).
