# Contrat VM DevOps du P5

Le P5 **ne crée pas et ne maintient pas la VM** dans laquelle il s'exécute.

La plateforme de référence est fournie par :

- [`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom)

Ce document décrit uniquement la frontière d'intégration nécessaire au projet P5.

## Source de vérité

`Ubuntu-desktops-custom` reste la source de vérité pour :

- le HOST Ubuntu ;
- KVM/libvirt ;
- le réseau virtuel ;
- les volumes/disques de VM ;
- cloud-init et l'identité initiale de la VM ;
- le démarrage, l'arrêt, la réparation et la sauvegarde de `ubuntu-devops`.

`p5_Openclassrooms` reste la source de vérité pour :

- les contraintes logicielles propres au P5 ;
- la préparation de son runtime dans la VM ;
- la configuration AWS du lab ;
- Terraform, Ansible, Angular, OpenSearch et HAProxy ;
- les preuves, diagnostics et livrables ;
- le nettoyage AWS.

Le P5 ne recopie aucune logique KVM/libvirt du dépôt Ubuntu.

## VM requise

Le contrat cible la VM :

```text
nom logique : ubuntu-devops
OS          : Ubuntu Server 26.04 LTS
usage       : CLI DevOps
```

Le contrôle P5 vérifie précisément :

```text
VERSION_ID=26.04
VERSION_CODENAME=resolute
```

La VM doit disposer d'un accès Internet/DNS et permettre les connexions vers AWS.

## Checkout opérationnel

Le dépôt doit rester dans le filesystem Linux de la VM, par exemple :

```text
/home/<user>/labs/p5_Openclassrooms
```

Commande habituelle dans `ubuntu-devops` :

```bash
cd ~/labs/p5_Openclassrooms
```

Le P5 refuse les environnements Windows/WSL2 comme runtime de référence de cette architecture.

## Qualification côté P5

Une fois connecté dans la VM :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le premier contrôle vérifie le runtime Ubuntu Server requis par le P5 sans modification.

Si un composant strictement requis par le projet est absent ou incompatible, la préparation P5 peut converger ses propres dépendances :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Cette convergence peut concerner Terraform, Ansible, Node.js, AWS CLI, Docker ou des outils de validation du dépôt. Elle reste limitée au guest Ubuntu et n'administre jamais l'hyperviseur.

## Ce que P5 ne doit jamais faire

Le dépôt P5 ne doit pas :

- appeler `virsh`, `virt-install` ou `qemu-img` pour gérer `ubuntu-devops` ;
- créer ou modifier un réseau libvirt ;
- gérer les pools de stockage KVM ;
- modifier les ressources CPU/RAM/disque de la VM ;
- gérer le backup/restore de la VM ;
- installer sa toolchain sur le HOST pour contourner un problème du guest.

## Réseau AWS

Le P5 ne dépend d'aucune adresse privée KVM codée en dur.

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration vue par AWS, obligatoirement en `/32` pour les accès restreints du lab.

L'adresse privée de `ubuntu-devops` sert uniquement à l'accès HOST → VM et reste une responsabilité de la plateforme Ubuntu.

## Principe

```text
Plateforme Ubuntu/KVM
        ↓ fournit
VM ubuntu-devops
        ↓ héberge
runtime préparé par P5
        ↓ exécute
labs AWS P5
```

Cette séparation évite deux sources de vérité concurrentes tout en laissant au P5 la maîtrise de sa préparation d'environnement.
