# Contrat VM DevOps du P5

## Objet

Ce document définit l'environnement d'exécution attendu par le projet P5.

Le P5 s'exécute dans la VM **`ubuntu-devops`** fournie par le dépôt
[`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).

La plateforme de virtualisation et le runtime P5 ont des responsabilités distinctes.

## Responsabilités

### Plateforme Ubuntu

`Ubuntu-desktops-custom` est la source de vérité pour :

- le HOST Ubuntu ;
- KVM/libvirt ;
- le réseau virtuel ;
- les volumes et disques de VM ;
- cloud-init et l'identité initiale de la VM ;
- les ressources CPU, RAM et stockage de `ubuntu-devops` ;
- le démarrage, l'arrêt, la réparation, la sauvegarde et la restauration de la VM.

### Projet P5

`p5_Openclassrooms` est la source de vérité pour :

- les versions et capacités logicielles requises par le P5 ;
- la préparation du runtime P5 dans la VM ;
- la configuration AWS du lab ;
- Terraform, Ansible, Angular, OpenSearch et HAProxy ;
- les diagnostics, preuves et livrables ;
- le nettoyage des ressources AWS du projet.

## VM requise

Le contrat d'exécution est :

```text
nom logique        ubuntu-devops
système            Ubuntu Server 26.04 LTS
codename           resolute
mode               CLI
virtualisation     KVM/QEMU
```

La VM doit disposer :

- d'un accès Internet et DNS fonctionnel ;
- d'un accès sortant vers AWS ;
- d'un utilisateur non root disposant de `sudo` ;
- d'un filesystem Linux local pour le checkout du projet.

## Checkout opérationnel

Chemin recommandé :

```text
/home/<user>/labs/p5_Openclassrooms
```

Exemple :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

## Qualification du runtime

Dans `ubuntu-devops` :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le contrôle vérifie notamment :

- Ubuntu Server 26.04 / Resolute ;
- l'identité `ubuntu-devops` ;
- la virtualisation KVM/QEMU ;
- le filesystem du checkout ;
- Terraform ;
- Ansible Core ;
- AWS CLI ;
- Docker Engine et Compose ;
- Node.js/npm ;
- les outils nécessaires aux validations du dépôt.

Les versions de référence sont définies dans [`../versions.env`](../versions.env).

## Convergence du runtime P5

La commande de préparation de référence est :

```bash
bash scripts/commands/p5.sh prepare
```

Pour converger uniquement le runtime logiciel :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

La convergence est limitée aux dépendances nécessaires au P5 dans la VM.

## Réseau et AWS

L'adresse privée de `ubuntu-devops` sert à l'administration de la VM depuis le HOST.
Elle n'est pas utilisée comme valeur de sécurité AWS du projet.

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration vue par AWS et doit être fournie en `/32`.

## Invariants

Le P5 doit être exécuté depuis `ubuntu-devops` et ne gère pas :

- KVM/libvirt ;
- les réseaux ou pools de stockage de l'hyperviseur ;
- les ressources matérielles de la VM ;
- son cycle de vie ;
- sa sauvegarde ou sa restauration.

Le contrat de plateforme est vérifié en lecture seule par la CI d'intégration du P5.
