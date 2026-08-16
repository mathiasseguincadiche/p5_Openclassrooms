# Environnement du projet P5

Ce dossier définit uniquement les **prérequis et paramètres propres au P5**.

La construction, la configuration, la virtualisation KVM/libvirt, le réseau de la VM, son stockage, son cycle de vie et sa sauvegarde appartiennent au dépôt amont :

- [`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom)

Le P5 consomme la VM DevOps fournie par cette plateforme ; il ne duplique pas sa gestion.

## Contrat attendu par le P5

L'environnement d'exécution attendu est la VM **`ubuntu-devops`** :

- Ubuntu Server **26.04 LTS** ;
- exécution en CLI, sans dépendance à un environnement graphique ;
- VM hébergée par KVM/libvirt côté poste Ubuntu ;
- checkout P5 dans le filesystem Linux de la VM, par exemple `~/labs/p5_Openclassrooms` ;
- accès Internet et DNS fonctionnels ;
- accès à AWS et aux ressources du lab ;
- droits `sudo` pour la convergence des dépendances strictement nécessaires au P5.

Le dépôt P5 ne doit pas appeler `virsh`, `virt-install`, `qemu-img` ou modifier la configuration KVM/libvirt. Ces responsabilités restent dans `Ubuntu-desktops-custom`.

## Accès à la VM

Depuis le HOST Ubuntu, la VM est administrée par le dépôt `Ubuntu-desktops-custom`. Une fois son adresse connue, la connexion habituelle est :

```bash
ssh <utilisateur>@<ip-ubuntu-devops>
```

Toutes les commandes P5 suivantes sont ensuite exécutées **dans la VM** :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Si le contrôle détecte un écart strictement nécessaire au P5 :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap est convergent : il inspecte d'abord puis installe ou réaligne uniquement les dépendances propres au P5. Il ne provisionne jamais la VM et ne modifie jamais l'hyperviseur.

## `versions.env` — contrat logiciel P5

[`versions.env`](versions.env) fixe les versions ou minima nécessaires à la reproductibilité du projet : Ubuntu, Terraform, Ansible, Node.js, AWS CLI et les images de validation utilisées par le dépôt.

La VM `ubuntu-devops` peut fournir davantage d'outils ; ils ne deviennent pas pour autant des dépendances ni des exercices du P5.

Cette séparation est volontaire :

- `Ubuntu-desktops-custom` définit et maintient la **plateforme VM DevOps** ;
- `p5_Openclassrooms` définit et maintient le **runtime nécessaire au P5 dans cette VM**.

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
Ubuntu-desktops-custom
├── configure le HOST Ubuntu
├── possède KVM/libvirt
├── crée et maintient la VM ubuntu-devops
├── possède son réseau, son stockage et son cycle de vie
└── fournit une VM Ubuntu Server 26.04 exploitable

p5_Openclassrooms
├── s'exécute entièrement dans ubuntu-devops
├── vérifie le contrat Ubuntu Server 26.04 nécessaire au projet
├── converge ses dépendances P5 uniquement
├── prépare les paramètres AWS du lab
├── génère les tfvars
└── exécute les trois exercices P5
```

Pour construire, réparer, démarrer, arrêter ou sauvegarder la VM, consulter directement `Ubuntu-desktops-custom`.

## À ne jamais versionner

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- preuves runtime brutes.

## Références P5

- [Contrat VM DevOps minimal](vm-devops/README.md)
- [Installation et environnement de contrôle](../docs/00-preparation-environnement.md)
- [Préparation du compte AWS](../docs/00b-preparation-compte-aws.md)
- [Runbook A à Z](../docs/RUNBOOK_EXECUTION_GUIDEE.md)
