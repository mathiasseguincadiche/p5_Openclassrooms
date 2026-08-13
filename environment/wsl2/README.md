# Contrat WSL2 du P5

Le P5 **n'installe pas et ne maintient pas WSL2**. La plateforme Windows/WSL2 est fournie par :

- [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom)

Ce document décrit uniquement la frontière d'intégration nécessaire au projet P5.

## Source de vérité

`Windows_11_Pro_Custom` reste la source de vérité pour Windows 11, WSL2 et la distribution Ubuntu.

`p5_Openclassrooms` reste la source de vérité pour :

- les contraintes logicielles propres au P5 ;
- la configuration AWS du lab ;
- Terraform, Ansible, Angular, OpenSearch et HAProxy ;
- les preuves, diagnostics et livrables ;
- le nettoyage AWS.

Le P5 ne recopie pas la configuration interne de la workstation.

## Distribution requise

La distribution utilisée par le projet est nommée :

```text
Ubuntu
```

Le contrat P5 exige :

```text
VERSION_ID=26.04
VERSION_CODENAME=resolute
```

Ouverture depuis Windows :

```powershell
wsl -d Ubuntu
```

## Checkout opérationnel

Le dépôt doit rester dans le filesystem Linux WSL2, par exemple :

```text
/home/<user>/labs/p5_Openclassrooms
```

Commande habituelle :

```bash
cd ~/labs/p5_Openclassrooms
```

Les chemins `/mnt/c/...` et `/mnt/d/...` ne doivent pas servir de racine de travail pour le P5.

## Qualification côté P5

Une fois dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le premier contrôle vérifie le runtime Ubuntu/WSL2 requis par le projet sans modification.

Si un composant requis par le P5 est absent ou incompatible, le parcours de préparation peut aligner uniquement les outils nécessaires :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

## Réseau

Le P5 ne dépend d'aucune adresse privée WSL codée en dur.

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration vue par AWS, obligatoirement en `/32` pour les accès restreints du lab.

## Hors périmètre de ce contrat

Le dimensionnement WSL2, le stockage de la distribution, les politiques de sauvegarde et les autres choix de workstation ne sont pas documentés ici. Ils appartiennent au dépôt `Windows_11_Pro_Custom`.

Cette séparation évite deux sources de vérité concurrentes.
