# Environnement du projet P5

Ce dossier contient les **contrats et paramètres locaux nécessaires à l'exécution du P5**. Il ne décrit pas toute la plateforme Windows : cette responsabilité appartient au dépôt `Windows_11_Pro_Custom`.

## Deux environnements Linux à distinguer

Le projet utilise plusieurs machines Ubuntu, avec des rôles différents.

| Contexte | Version | Responsabilité |
| --- | --- | --- |
| distribution WSL2 locale `Ubuntu` | Ubuntu 26.04 LTS `resolute` | plan de contrôle du P5 |
| EC2 des exercices 1 et 3 | Ubuntu 24.04 LTS `noble` par défaut | cibles AWS créées par Terraform |

Le présent dossier `environment/` décrit principalement **le plan de contrôle local et la configuration du lab**, pas le système d'exploitation des EC2.

## Environnement d'exécution local

Le P5 s'exécute dans la distribution WSL2 **`Ubuntu`** :

```text
OS              Ubuntu 26.04 LTS
codename        resolute
mode            CLI
virtualisation  WSL2
filesystem      EXT4
checkout        ~/labs/p5_Openclassrooms
```

La distribution doit disposer :

- d'un accès Internet/DNS ;
- d'un accès sortant vers AWS ;
- d'un utilisateur non root avec `sudo` ;
- de systemd ;
- d'un workspace sur le filesystem Linux EXT4 de la distribution.

Le contrat complet est documenté dans [`wsl2/README.md`](wsl2/README.md).

La plateforme Windows/WSL2 est fournie par [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

## Responsabilités de la plateforme et du P5

| Domaine | Propriétaire |
| --- | --- |
| Windows 11 Pro | `Windows_11_Pro_Custom` |
| WSL2, distribution `Ubuntu`, VHDX, réseau/DNS | `Windows_11_Pro_Custom` |
| Docker Engine, Terraform, AWS CLI communs | `Windows_11_Pro_Custom` |
| contrat d'exécution du P5 | `p5_Openclassrooms` |
| Node.js, Ansible Core et dépendances spécifiques | `p5_Openclassrooms` |
| configuration AWS du lab | `p5_Openclassrooms` |
| modules Terraform et states | `p5_Openclassrooms` |
| inventaires, logs et preuves | `p5_Openclassrooms` |

Le P5 peut **vérifier** les outils communs fournis par la plateforme. Il ne doit pas pour autant devenir propriétaire du cycle de vie de Windows ou WSL2.

## Préparer le runtime P5

Dans la distribution WSL2 `Ubuntu` :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-wsl2.sh --check-only
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

### Rôle des commandes

```text
bootstrap --check-only
→ vérifier le contrat du runtime sans chercher à converger le lab complet

inspect
→ observer l'état P5 existant

prepare
→ vérifier la stack commune et converger les besoins spécifiques du P5

status
→ revalider le lab avant le déploiement
```

## `versions.env` — contrat logiciel versionné

[`versions.env`](versions.env) définit les versions, chemins, racines de travail et invariants utilisés par le P5.

Références principales actuelles :

```text
Ubuntu WSL2         26.04 / resolute
Filesystem HOME     ext4
Terraform           1.15.8
Ansible Core        2.20.1
Node.js             22.22.0
AWS CLI minimum     2.32.0
OpenSearch Docker   2.19.6
```

Les scripts et workflows doivent lire ces valeurs depuis `versions.env` au lieu de maintenir une seconde copie manuelle du contrat.

## `aws-readiness.env.example` — modèle versionné

Le fichier :

```text
environment/aws-readiness.env.example
```

montre les paramètres attendus sans contenir les vraies valeurs du lab.

Il sert de **contrat documentaire**, pas de configuration runtime directe.

## `aws-readiness.env` — configuration locale réelle

Le fichier runtime est :

```text
environment/aws-readiness.env
```

Il centralise notamment :

- profil et région AWS ;
- compte AWS attendu ;
- IPv4 publique d'administration en `/32` ;
- clé SSH du lab ;
- types d'instances ;
- paramètres Amazon OpenSearch ;
- budget et adresse d'alerte ;
- confirmations de sécurité requises.

Ce fichier :

- est généré/préparé localement ;
- reste ignoré par Git ;
- ne doit pas contenir de clé AWS longue durée versionnée.

## De la configuration locale vers Terraform

Les vrais `terraform.tfvars` ne doivent pas dériver indépendamment les uns des autres.

Le flux est :

```text
environment/aws-readiness.env
        ↓
sync-terraform-tfvars.sh
        ↓
terraform/exercice-1/terraform.tfvars
terraform/exercice-2/terraform.tfvars
terraform/exercice-3/terraform.tfvars
```

Synchronisation :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Les fichiers réels sont locaux, avec des permissions restrictives, et restent ignorés par Git.

Les fichiers `terraform.tfvars.example` sont des **modèles documentaires**, pas des valeurs à utiliser aveuglément pour un déploiement réel.

## Workspace attendu

Le checkout actif doit vivre sous une racine Linux autorisée :

```text
~/projects
~/labs
~/repositories
```

`/mnt/c` et `/mnt/e` restent accessibles pour les échanges ponctuels avec Windows, mais sont **interdits comme racines de projet ou de workspace P5/DevOps**.

Le stockage physique du VHDX sous `E:\WSL\Ubuntu-DevOps` ne change pas cette règle : le projet reste dans le filesystem Linux EXT4 de la distribution, sous `~/projects`, `~/labs` ou `~/repositories`.

## Fichiers à ne jamais versionner

- `environment/aws-readiness.env` ;
- vrais `terraform.tfvars` ;
- `terraform.tfstate` et sauvegardes de state ;
- plans Terraform ;
- inventaire Ansible réel ;
- clés SSH privées ;
- credentials AWS ;
- preuves runtime brutes non destinées à la publication.

## Pourquoi ces contrats existent-ils ?

Sans contrat explicite, deux exécutions peuvent utiliser :

- des versions d'outils différentes ;
- des comptes ou régions AWS différents ;
- des chemins de workspace différents ;
- des variables Terraform divergentes.

Le dossier `environment/` réduit cette ambiguïté en séparant :

```text
ce qui est versionné et reproductible
        vs
ce qui est local et spécifique au lab réel
```

## Sources de vérité

| Sujet | Source |
| --- | --- |
| contrat WSL2 | `versions.env` + `wsl2/README.md` + scripts de bootstrap |
| versions logicielles | `versions.env` |
| modèle de configuration AWS | `aws-readiness.env.example` |
| configuration AWS réelle | `aws-readiness.env` local |
| infrastructure AWS | `../terraform/exercice-{1,2,3}/` |
| orchestration | `../scripts/commands/p5.sh` |
