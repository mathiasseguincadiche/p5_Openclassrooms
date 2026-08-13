# Architecture technique et flux du projet P5

Ce document décrit **l'architecture réelle du P5**. Il part de ce qui est évalué
— l'infrastructure et les flux AWS — puis explique seulement ensuite le rôle du
poste de contrôle local.

## 1. Vue d'ensemble

```text
                           OPÉRATEUR
                              │
                              ▼
                   scripts/commands/p5.sh
                              │
                              ▼
                         COMPTE AWS
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
   EXERCICE 1            EXERCICE 2            EXERCICE 3
   VPC + EC2              OpenSearch             HAProxy
        │                     ▲                     ▲
        ▼                     │                     │
 Ansible → NGINX              │                     │
        │                     │                     │
     Angular                  │                     │
        │                     │                     │
        └── access.log ───────┘                     │
        │                                           │
        └──── VPC + subnets + key pair ─────────────┘
                              │
                              ▼
                   preuves + validation
                              │
                              ▼
                  nettoyage complet AWS
```

Le dépôt contient le **plan de contrôle**. AWS contient l'infrastructure évaluée.
Les preuves relient les deux.

## 2. Les trois couches du projet

### Couche 1 — Orchestration et contrôle

Le dépôt `p5_Openclassrooms` fournit :

- `scripts/commands/p5.sh` ;
- les scripts spécialisés ;
- la configuration locale du lab ;
- les modules Terraform ;
- les playbooks Ansible ;
- l'application Angular ;
- les validateurs ;
- les journaux et preuves runtime.

Cette couche décrit, pilote et vérifie le lab.

### Couche 2 — Infrastructure AWS évaluée

La réalisation retenue utilise AWS pour les trois exercices.

```text
AWS — us-east-1
│
├── Exercice 1
│   ├── VPC 10.0.0.0/16
│   ├── 2 sous-réseaux publics
│   ├── Internet Gateway
│   ├── table de routage
│   ├── Security Group
│   ├── paire de clés EC2
│   └── EC2 Ubuntu → NGINX → Angular
│
├── Exercice 2
│   └── Amazon OpenSearch Service
│       └── index nginx-access-* + Dashboards
│
└── Exercice 3
    ├── réutilise le réseau de l'exercice 1
    ├── EC2 HAProxy
    └── 2 EC2 backends → Docker → nginxdemos/hello
```

### Couche 3 — Preuves et soutenance

Le projet produit deux familles d'artefacts :

```text
logs/<UTC>/
└── journaux d'exécution

proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Un fichier de code versionné est une **implémentation**. Une sortie issue d'un lab
AWS réel est une **preuve d'exécution**. Ces deux notions ne doivent pas être
confondues.

## 3. Architecture de l'exercice 1

L'exercice 1 établit le socle réseau et la cible applicative.

```text
Internet
   │
   ▼
Internet Gateway
   │
   ▼
VPC 10.0.0.0/16
   │
   ├── subnet public 1
   └── subnet public 2
           │
           ▼
       EC2 Ubuntu
           │
           ▼
         NGINX
           │
           ▼
         Angular
```

Terraform crée l'infrastructure. Ansible configure l'EC2 et déploie
l'application.

Les outputs Terraform fournissent notamment :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_private_ip
web_public_dns
web_url
```

`web_public_ip` alimente l'inventaire Ansible et `web_url` sert aux contrôles HTTP.

## 4. Flux Terraform → Ansible → application

```text
sources Angular
      ↓
build
      ↓
artefact versionné pour Ansible
      ↓
Terraform plan
      ↓
Terraform apply si delta
      ↓
output web_public_ip
      ↓
inventaire Ansible
      ↓
playbook deploy.yml
      ↓
NGINX + Angular
      ↓
contrôle HTTP
      ↓
second passage Ansible
      ↓
changed=0 / unreachable=0 / failed=0
```

Le second passage Ansible est une preuve d'idempotence, pas une simple répétition.

## 5. Flux de logs vers l'exercice 2

L'application réellement servie produit des logs NGINX.

```text
requêtes HTTP
      ↓
NGINX
      ↓
/var/log/nginx/access.log
      ↓
collecte locale
      ↓
conversion des données
      ↓
Bulk API
      ↓
Amazon OpenSearch
      ↓
index / agrégations
      ↓
OpenSearch Dashboards
```

Le dépôt fournit également un échantillon reproductible. Il sert aux validations
et permet de tester les traitements sans prétendre qu'il remplace les logs réels.

## 6. Architecture de l'exercice 2

L'exercice 2 crée un domaine Amazon OpenSearch configuré avec :

- HTTPS obligatoire ;
- TLS 1.2 minimum ;
- chiffrement au repos ;
- chiffrement inter-nœuds ;
- accès limité à l'IPv4 publique `/32` de l'opérateur ;
- volume `gp3` ;
- budget et garde-fous contrôlés avant création.

Flux logique :

```text
logs
  ↓
index template
  ↓
Bulk API
  ↓
nginx-access-*
  ↓
agrégations
  ↓
visualisations Dashboards
```

Les visualisations finales restent une action humaine afin de démontrer la
compréhension du jeu de données.

## 7. Architecture de l'exercice 3

L'exercice 3 ne recrée pas un nouveau réseau. Il recherche le VPC, les subnets et
la paire de clés de l'exercice 1 grâce aux tags du projet.

```text
                       Internet
                          │
                          ▼
                      EC2 HAProxy
                       roundrobin
                     /            \
                    /              \
             backend 1          backend 2
                │                   │
              Docker              Docker
                │                   │
       nginxdemos/hello   nginxdemos/hello
```

Les backends n'acceptent le trafic HTTP que depuis le Security Group HAProxy.

Les health checks utilisent :

```text
GET /
inter 3s
fall 3
rise 2
```

Le scénario de validation provoque une panne contrôlée d'un backend, vérifie la
continuité du service, restaure le backend puis confirme sa réintégration.

## 8. Dépendances entre exercices

Les dépendances doivent être comprises avant le nettoyage.

```text
Exercice 1
├── access.log ─────────────► Exercice 2
└── VPC + subnets + key ───► Exercice 3
```

La dépendance infrastructurelle forte est :

```text
Exercice 1 ──► Exercice 3
```

L'exercice 1 ne doit donc pas être détruit tant que l'exercice 3 existe.

Ordre de fermeture :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit global AWS
```

## 9. Plan de contrôle et sources de vérité

Le P5 évite de dupliquer les informations entre scripts.

| Sujet | Source de vérité |
| --- | --- |
| versions du lab | `environment/versions.env` |
| paramètres AWS locaux | `environment/aws-readiness.env` |
| orchestration | `scripts/commands/p5.sh` |
| infrastructure Ex.1 | `terraform/exercice-1/` |
| infrastructure Ex.2 | `terraform/exercice-2/` |
| infrastructure Ex.3 | `terraform/exercice-3/` |
| déploiement | `ansible/playbooks/deploy.yml` |
| application | `application/angular/` |
| artefact Ansible | `ansible/files/angular-app/` |
| preuves runtime | `proofs/runtime/` |
| logs runtime | `logs/` |

Les vrais `terraform.tfvars` sont générés à partir de la configuration locale et
restent ignorés par Git.

## 10. Convergence Terraform

La logique de convergence est :

```text
terraform init
      ↓
terraform plan -detailed-exitcode
      ↓
      ├── 0 : aucun delta → aucun apply
      ├── 2 : delta → afficher → confirmer → apply
      └── autre : erreur → STOP
      ↓
post-plan
      ↓
preuve d'absence de delta
```

Le projet ne doit pas appliquer un plan vide.

Cette logique permet la reprise après interruption sans repartir de zéro.

## 11. Convergence au-delà de Terraform

Le même principe est utilisé pour :

- la toolchain P5 ;
- la configuration AWS locale ;
- le budget ;
- la synchronisation des `tfvars` ;
- l'artefact Angular ;
- l'inventaire Ansible ;
- certaines données OpenSearch ;
- les validations et diagnostics.

Le projet cherche à **corriger un écart**, pas à réinstaller aveuglément tout le
lab à chaque exécution.

## 12. Frontières de sécurité

### Compte AWS

Les providers utilisent `allowed_account_ids` pour éviter un déploiement sur un
mauvais compte.

### Accès réseau

L'accès SSH est limité à l'IPv4 publique `/32` de l'opérateur.

`P5_PUBLIC_IP_CIDR` n'est jamais une adresse privée WSL2.

### EC2

Les instances imposent notamment :

- IMDSv2 ;
- volumes racine chiffrés ;
- règles réseau adaptées au rôle de l'instance.

### OpenSearch

Le domaine exige HTTPS et chiffrement.

### Destruction

Le nettoyage final exige une confirmation forte :

```text
DETRUIRE
```

## 13. Flux de preuves

```text
code versionné
     ↓
CI / validations locales
     ↓
exécution AWS réelle
     ↓
logs / outputs / captures
     ↓
proofs/runtime
     ↓
relecture
     ↓
livrables de soutenance
```

La CI ne doit jamais fabriquer une preuve en prétendant qu'elle vient d'une
exécution AWS réelle.

## 14. Rôle du poste de contrôle local

Le poste local n'est qu'une couche d'exécution :

```text
Windows 11 Pro
└── WSL2
    └── Ubuntu
        ├── Bash
        ├── Terraform
        ├── Ansible
        ├── AWS CLI
        ├── Docker
        └── Node.js
                │
                ▼
             p5.sh
                │
                ▼
               AWS
```

La workstation est gérée en amont par
`mathiasseguincadiche/Windows_11_Pro_Custom`.

P5 ne doit pas devenir un second dépôt de configuration Windows/WSL2. Il consomme
la plateforme et ne corrige que les écarts spécifiques au contrat P5.

Pour les détails d'installation :
[Préparation de l'environnement de contrôle](00-preparation-environnement.md).

## 15. Réseau local versus réseau AWS

Deux réseaux indépendants existent :

```text
réseau local Windows/WSL2
          ≠
VPC AWS 10.0.0.0/16
```

Le choix d'un mode réseau WSL2 n'altère pas les CIDR, routes ou Security Groups du
lab AWS.

L'IPv4 `/32` configurée dans P5 représente l'adresse publique vue depuis AWS.

## 16. Sauvegarde et état

La sauvegarde de Windows/WSL2 appartient au dépôt workstation.

P5 doit protéger de son côté :

- le code via Git ;
- les états Terraform locaux tant que les ressources AWS existent ;
- les preuves runtime ;
- les journaux ;
- les livrables.

**Supprimer un `terraform.tfstate` alors que les ressources existent peut casser
la capacité de Terraform à les gérer ou les détruire.**

## 17. Références

- [Cadre officiel](00-cadre-officiel.md)
- [Parcours pédagogique](01-parcours-debutant.md)
- [Correspondance consignes → implémentation → preuve](02-correspondance-consignes-depot.md)
- [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
- [Convergence](convergence-et-reexecution.md)
- [Validation et nettoyage](validation-preuves-nettoyage.md)
- [Préparation de l'environnement](00-preparation-environnement.md)
