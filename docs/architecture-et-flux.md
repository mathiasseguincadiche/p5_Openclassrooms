# Architecture technique et flux du projet P5

Ce document décrit l'architecture réelle du P5 et la frontière entre la
workstation locale et l'infrastructure AWS évaluée.

## Vue d'ensemble

Le poste de contrôle est fourni par le dépôt
`mathiasseguincadiche/Windows_11_Pro_Custom`.

```text
Windows_11_Pro_Custom
└── Windows 11 Pro
    └── WSL2
        └── Ubuntu — D:\WSL\Ubuntu-DevOps
            ├── systemd
            ├── Docker Engine
            ├── Terraform
            ├── Ansible Core
            ├── AWS CLI
            ├── kubectl / Helm
            └── outils DevOps
                    │
                    ▼
p5_Openclassrooms
├── Angular
├── Terraform
├── Ansible
├── scripts de validation
├── configuration AWS locale
└── preuves / logs
        │
        ▼
AWS — us-east-1
│
├── Exercice 1
│   ├── VPC 10.0.0.0/16
│   ├── 2 sous-réseaux publics
│   ├── Internet Gateway + table de routage
│   ├── paire de clés EC2
│   └── EC2 Ubuntu → Ansible → NGINX → Angular
│
├── Exercice 2
│   └── Amazon OpenSearch Service
│       └── nginx-access-* → Dashboards
│
└── Exercice 3
    ├── réutilise le réseau de l'exercice 1
    ├── EC2 HAProxy
    └── 2 EC2 backends → Docker → nginxdemos/hello
```

## Responsabilités de la workstation

`Windows_11_Pro_Custom` possède :

- installation et mise à jour WSL2 ;
- distribution `Ubuntu` ;
- stockage sous `D:\WSL\Ubuntu-DevOps` ;
- `.wslconfig` ;
- `/etc/wsl.conf` ;
- profils `standard`, `lab-heavy`, `nat-fallback` ;
- Docker, Terraform, Ansible, AWS CLI et outils DevOps généraux ;
- backup/restauration Windows et WSL2.

Le P5 ne recopie aucune de ces configurations.

## Profils WSL2

La source de vérité amont définit :

```text
standard
└── 8 threads / 20 Go / 8 Go swap / mirrored

lab-heavy
└── 12 threads / 28 Go / 12 Go swap / mirrored

nat-fallback
└── 8 threads / 20 Go / 8 Go swap / NAT
```

Le choix du profil local n'a pas d'effet sur le plan d'adressage du VPC AWS.

## Réseau local versus réseau AWS

Deux notions doivent rester séparées :

```text
réseau WSL2 local
≠
réseau AWS du lab
```

Le mode `mirrored` est le profil quotidien de la workstation. `nat-fallback` est
un secours local.

Le VPC AWS reste :

```text
10.0.0.0/16
```

avec deux sous-réseaux publics et une Internet Gateway.

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique `/32` depuis laquelle l'opérateur
administre les ressources AWS. Ce n'est jamais une adresse WSL2.

## Flux exercice 1

```text
sources Angular
      ↓
build local dans Ubuntu WSL2
      ↓
Terraform
      ↓
AWS EC2
      ↓
Ansible
      ↓
NGINX
      ↓
Angular
      ↓
access.log réel
```

Le log NGINX réel peut ensuite alimenter l'exercice 2.

## Flux exercice 2

```text
échantillon reproductible
          +
access.log réel
          ↓
conversion NDJSON
          ↓
Amazon OpenSearch
          ↓
agrégations
          ↓
Dashboards
```

La création du dashboard et les captures restent des preuves humaines.

## Flux exercice 3

```text
VPC + subnets Exercice 1
          ↓
Terraform Exercice 3
          ↓
HAProxy
      /         \
Backend 1    Backend 2
      ↓          ↓
 Docker       Docker
```

Le test de panne arrête réellement un backend, vérifie la continuité de service
puis confirme sa réintégration.

## Dépendance entre exercices

L'exercice 3 réutilise l'infrastructure réseau de l'exercice 1 :

```text
Exercice 1
└── VPC + subnets + clé EC2
        ↓
Exercice 3
```

L'exercice 1 ne doit donc pas être détruit avant la fin de l'exercice 3.

## Convergence

La workstation amont et le P5 ont des responsabilités différentes mais suivent
la même idée : ne pas refaire inutilement ce qui est déjà conforme.

Dans P5 :

```text
inspection
   ↓
delta ?
├── non → aucune mutation
└── oui → correction ciblée
   ↓
vérification
   ↓
preuve / log
```

Un outil DevOps déjà présent et compatible sur Ubuntu WSL2 est réutilisé.

## Sauvegarde

La sauvegarde de la plateforme n'appartient pas au P5. La V7 de
`Windows_11_Pro_Custom` couvre l'image Windows et l'export Ubuntu VHDX avec
SHA-256.

Le P5 protège de son côté :

- son code via Git ;
- ses états Terraform locaux tant que les ressources existent ;
- ses preuves et logs runtime ;
- ses livrables.

## Références

- [Préparation de l'environnement](00-preparation-environnement.md)
- [Contrat WSL2](../environment/wsl2/README.md)
- [Parcours d'exécution](01-parcours-debutant.md)
- [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
- [Convergence](convergence-et-reexecution.md)
