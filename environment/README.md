# Environnement du projet P5

Ce dossier contient les contrats et paramètres nécessaires à l'exécution du P5.

## Environnement d'exécution

Le P5 s'exécute dans la distribution WSL2 **`Ubuntu`** :

```text
OS              Ubuntu 26.04 LTS sous WSL2
codename        resolute
mode            CLI
virtualisation  WSL2
checkout        ~/labs/p5_Openclassrooms
```

La distribution WSL2 doit disposer d'un accès Internet/DNS, d'un accès sortant vers AWS et d'un utilisateur
non root avec `sudo`.

Le contrat complet est documenté dans [`wsl2/README.md`](wsl2/README.md).

La plateforme Windows/WSL2 est fournie par
[`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

## Préparation du runtime P5

Dans `Ubuntu` sous WSL2 :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-wsl2.sh --check-only
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

`prepare` vérifie la stack commune fournie par le dépôt Windows, puis converge les dépendances
propres au P5 : Ansible Core, Node.js et les outils de validation.

## `versions.env` — contrat logiciel

[`versions.env`](versions.env) définit les versions ou minima utilisés par le P5.

Références principales :

```text
Ubuntu              26.04 / resolute
Terraform           1.15.8
Ansible Core        2.20.1
Node.js             22.22.0
AWS CLI minimum     2.32.0
OpenSearch Docker   2.19.6
```

## `aws-readiness.env` — configuration locale AWS

Modèle versionné :

```text
environment/aws-readiness.env.example
```

Fichier runtime :

```text
environment/aws-readiness.env
```

Il centralise notamment :

- le profil et la région AWS ;
- le compte AWS attendu ;
- l'IPv4 publique d'administration en `/32` ;
- la clé SSH du lab ;
- les types d'instances ;
- les paramètres Amazon OpenSearch ;
- le budget et l'adresse d'alerte ;
- les confirmations de sécurité requises.

Le fichier runtime reste ignoré par Git et ne contient aucune clé d'accès AWS longue durée.

## Synchronisation Terraform

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Cette configuration alimente les trois `terraform.tfvars` locaux. Les fichiers réels restent
ignorés par Git.

## Responsabilités

| Domaine | Source de vérité |
| --- | --- |
| Windows 11 Pro, WSL2, `Ubuntu`, Docker, Terraform, AWS CLI | `Windows_11_Pro_Custom` |
| runtime P5 dans WSL2 | `p5_Openclassrooms` |
| paramètres AWS du lab | `environment/aws-readiness.env` |
| versions logicielles P5 | `environment/versions.env` |
| infrastructure AWS | `terraform/exercice-{1,2,3}/` |

## Fichiers à ne jamais versionner

- `environment/aws-readiness.env` ;
- vrais `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- preuves runtime brutes.

## Références

- [Contrat WSL2](wsl2/README.md)
- [Préparation de l'environnement](../docs/00-preparation-environnement.md)
- [Préparation du compte AWS](../docs/00b-preparation-compte-aws.md)
- [Runbook A à Z](../docs/RUNBOOK_EXECUTION_GUIDEE.md)
