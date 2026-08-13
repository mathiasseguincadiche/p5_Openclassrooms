# Environnement du projet P5

Ce dossier définit uniquement les **prérequis et paramètres propres au P5**.

La construction, la configuration et la maintenance du poste Windows/WSL2 appartiennent au dépôt amont :

- [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom)

Le P5 consomme cette plateforme ; il ne la duplique pas.

## Contrat attendu par le P5

Le poste de contrôle doit fournir :

- WSL2 fonctionnel ;
- une distribution **Ubuntu 26.04** nommée `Ubuntu` ;
- un checkout P5 dans le filesystem Linux, par exemple `~/labs/p5_Openclassrooms` ;
- les outils compatibles avec [`versions.env`](versions.env) ;
- Docker disponible pour les validations locales ;
- un accès réseau permettant de joindre AWS et les ressources du lab.

Le checkout opérationnel ne doit pas être placé sous `/mnt/c` ou `/mnt/d`.

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Puis dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Si le contrôle du socle détecte un écart strictement nécessaire au P5 :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap est convergent : un composant déjà conforme n'est pas réinstallé inutilement.

## `versions.env` — contrat logiciel

[`versions.env`](versions.env) fixe les versions ou minima nécessaires à la reproductibilité du projet : Ubuntu, Terraform, Ansible, Node.js, AWS CLI et outils utilisés par les scripts et la CI.

La workstation peut fournir davantage d'outils ; ils ne deviennent pas pour autant des dépendances ou des exercices du P5.

## `aws-readiness.env` — configuration locale du lab

Le modèle versionné est :

```text
environment/aws-readiness.env.example
```

Le fichier réel :

```text
environment/aws-readiness.env
```

est créé ou réconcilié par le parcours de préparation et reste ignoré par Git.

Il centralise notamment :

- profil et région AWS ;
- compte AWS attendu ;
- IPv4 publique d'administration en `/32` ;
- clé SSH du lab ;
- types d'instances ;
- paramètres Amazon OpenSearch ;
- budget et e-mail d'alerte ;
- confirmations de sécurité requises.

Il ne doit contenir aucune clé d'accès AWS longue durée.

## Synchronisation Terraform

La configuration locale alimente les trois `terraform.tfvars` :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Les vrais `terraform.tfvars` restent locaux et ignorés par Git.

## Frontière de responsabilité

```text
Windows_11_Pro_Custom
└── construit et maintient le poste Windows + WSL2

p5_Openclassrooms
├── vérifie le contrat Ubuntu/WSL2 nécessaire au projet
├── fixe ses versions logicielles
├── prépare les paramètres AWS du lab
├── génère les tfvars
└── exécute les trois exercices P5
```

Pour construire, réparer ou sauvegarder la workstation, consulter directement `Windows_11_Pro_Custom`.

## À ne jamais versionner

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- preuves runtime brutes.

## Références P5

- [Contrat WSL2 minimal](wsl2/README.md)
- [Installation et environnement de contrôle](../docs/00-preparation-environnement.md)
- [Préparation du compte AWS](../docs/00b-preparation-compte-aws.md)
- [Runbook A à Z](../docs/RUNBOOK_EXECUTION_GUIDEE.md)
