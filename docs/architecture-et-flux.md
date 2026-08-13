# Architecture et flux du P5

## Objectif

Ce document décrit **l'architecture réellement implémentée dans le dépôt** : composants, responsabilités, réseaux, flux de données et dépendances entre exercices.

Le schéma synthétique est :

![Architecture P5](schemas/vue-ensemble.svg)

## 1. Frontière du projet

```text
HORS PÉRIMÈTRE ÉVALUÉ
Windows 11 + WSL2 + Ubuntu 26.04
            │
            │ outils de contrôle
            ▼
════════════════════════════════════
PÉRIMÈTRE P5 AWS
Terraform / Ansible / OpenSearch / HAProxy
════════════════════════════════════
```

Le poste de contrôle exécute les commandes, mais les exercices sont réalisés sur AWS.

## 2. Plan de contrôle

Le plan de contrôle du dépôt est :

```text
scripts/commands/p5.sh
        │
        ├── scripts/lib/p5-runtime.sh
        │      ├── logs
        │      ├── preuves par étape
        │      ├── confirmations
        │      └── validation de valeurs
        │
        ├── scripts/commands/*.sh
        ├── terraform/exercice-*/
        └── ansible/playbooks/deploy.yml
```

`p5.sh` orchestre ; il ne remplace ni Terraform ni Ansible.

## 3. Exercice 1 — architecture détaillée

### Infrastructure AWS

```text
AWS Region
└── VPC 10.0.0.0/16
    ├── Public subnet 1
    ├── Public subnet 2
    ├── Internet Gateway
    ├── Public route table
    ├── Security Group web
    │   ├── TCP/22 depuis your_ip_cidr /32
    │   └── TCP/80 depuis Internet
    ├── EC2 Key Pair
    └── EC2 p5-web
        ├── Ubuntu 24.04 LTS
        ├── IMDSv2 obligatoire
        └── root volume gp3 chiffré
```

Terraform gère ces ressources dans `terraform/exercice-1`.

### Flux de déploiement

```text
application/angular
      │ npm build
      ▼
ansible/files/angular-app
      │
      │ Ansible copy
      ▼
EC2 /var/www/p5
      │
      ▼
NGINX :80
      │
      ▼
Navigateur / curl
```

La CI reconstruit Angular et compare le résultat avec `ansible/files/angular-app`. Cela empêche de déployer un artefact différent des sources versionnées.

### Flux SSH

```text
poste WSL2
   │
   │ TCP/22 autorisé uniquement depuis IPv4 /32
   ▼
EC2 p5-web
   │
   ├── Ansible ping
   └── ansible-playbook deploy.yml
```

L'inventaire réel est généré localement à partir des outputs Terraform.

### Flux HTTP

```text
Internet
   │ TCP/80
   ▼
Security Group web
   ▼
NGINX
   ▼
Angular SPA
```

NGINX utilise un fallback SPA afin qu'une route comme `/parcours-p5` retourne l'application au lieu d'une erreur 404.

### Flux de logs

```text
requêtes HTTP
    ↓
NGINX
    ↓
/var/log/nginx/access.log
    ↓ collecte SSH
proofs/runtime/exercice-2/nginx-access-real.log
```

Ce fichier devient une source possible de l'exercice 2.

## 4. Exercice 2 — architecture détaillée

### Infrastructure

```text
Amazon OpenSearch Domain
├── moteur OpenSearch 2.19 par défaut du lab
├── EBS gp3
├── chiffrement au repos
├── chiffrement node-to-node
├── HTTPS obligatoire
├── TLS >= 1.2
└── policy SourceIp = poste /32
```

Le module est `terraform/exercice-2`.

### Pipeline de données

Deux sources sont admises :

```text
sample versionné
terraform/exercice-2/samples/nginx-access.log.sample

             OU / ET

log réel exercice 1
proofs/runtime/exercice-2/nginx-access-real.log
```

Puis :

```text
logs NGINX
   │
   ▼
scripts/tools/convert-nginx-logs.py
   │
   ▼
documents structurés
   │
   ▼
scripts/commands/import-opensearch-data.sh
   │ Bulk API
   ▼
index nginx-access-*
   │
   ▼
scripts/commands/verify-opensearch-data.sh
   │
   ├── mapping
   ├── nombre de documents
   └── agrégations
```

### Flux humain OpenSearch Dashboards

```text
OpenSearch
    ↓
OpenSearch Dashboards
    ↓
Discover
    ↓
3 visualisations
    ↓
dashboard complet
    ↓
4 captures de preuve
```

Cette partie n'est pas validée automatiquement à la place de l'étudiant.

## 5. Exercice 3 — architecture détaillée

### Réutilisation de l'exercice 1

Le module `terraform/exercice-3` ne recrée pas un VPC indépendant. Il cherche les ressources de l'exercice 1 à partir de tags :

```text
Project  = p5-openclassrooms
Exercise = 1
Name/Type appropriés
```

Il récupère :

- le VPC ;
- les deux subnets publics.

La clé EC2 est réutilisée par son nom configuré.

### Topologie

```text
Internet
   │ TCP/80
   ▼
Security Group HAProxy
   ▼
EC2 p5-haproxy
   │
   │ HTTP privé
   ├───────────────┐
   ▼               ▼
EC2 hello-1     EC2 hello-2
Docker           Docker
nginxdemos/hello nginxdemos/hello
```

Les backends ont des IP publiques pour l'administration SSH du lab, mais leur port HTTP est autorisé depuis le **Security Group HAProxy**, pas depuis Internet entier.

### Configuration HAProxy

Le backend utilise :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

Interprétation :

- `roundrobin` alterne la distribution ;
- `httpchk GET /` teste l'URL racine ;
- `expect status 200` attend un HTTP 200 ;
- `fall 3` exige trois échecs consécutifs avant de déclarer le serveur DOWN ;
- `rise 2` exige deux succès consécutifs avant de le remettre UP.

### Flux de test de panne

```text
État initial
HAProxy → hello-1 + hello-2

Arrêt contrôlé de nginx-hello sur hello-1
           ↓
health checks échouent
           ↓
HAProxy retire hello-1
           ↓
trafic → hello-2 uniquement
           ↓
restauration hello-1
           ↓
health checks réussissent
           ↓
HAProxy réintègre hello-1
```

Le script de failover utilise un mécanisme de restauration pour éviter de laisser volontairement le backend arrêté après le test.

## 6. Flux des informations de configuration

La source locale principale est :

```text
environment/aws-readiness.env
```

Elle alimente :

```text
aws-readiness.env
       │
       ├── profil / région AWS
       ├── compte attendu
       ├── IP /32
       ├── types d'instances
       ├── clé SSH
       ├── OpenSearch
       └── budget
              │
              ▼
sync-terraform-tfvars.sh
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
      ex1    ex2    ex3
 terraform.tfvars locaux
```

Les `tfvars` réels ne sont pas versionnés.

## 7. Flux Terraform

Pour chaque exercice :

```text
terraform init
      ↓
terraform plan -detailed-exitcode -out=tfplan
      ↓
terraform show tfplan
      ↓
0 = aucun delta ──► pas d'apply
2 = delta        ──► confirmation ──► apply
      ↓
post-plan
      ↓
aucun delta attendu
```

C'est la base de la convergence P5.

## 8. Flux des preuves

Chaque étape orchestrée produit une trace :

```text
commande
   ↓
log d'étape
   ↓
redaction des secrets
   ↓
preuve copiée sous proofs/runtime/steps/<RUN_ID>
   ↓
SHA-256 + statut + durée dans manifest.tsv
   ↓
résumé du run
```

Ces fichiers sont des **preuves techniques brutes**. Les livrables doivent sélectionner et expliquer les éléments pertinents.

## 9. Dépendances et ordre d'exécution

L'ordre recommandé est :

```text
prepare
  ↓
ex1
  ├──► ex2
  └──► ex3
        ↓
diagnostics
  ↓
finalize
```

`ex2` pourrait techniquement exploiter le sample sans les logs réels de l'exercice 1, mais le parcours complet exécute `ex1` d'abord afin de disposer d'une preuve plus représentative.

`ex3` a une dépendance infrastructurelle forte vers `ex1`.

## 10. Ordre de destruction

La dépendance réseau impose :

```text
terraform/exercice-3 destroy
          ↓
terraform/exercice-2 destroy
          ↓
terraform/exercice-1 destroy
          ↓
audit global AWS
```

Détruire l'exercice 1 en premier casserait les data sources et les dépendances de l'exercice 3.

## 11. Frontières de responsabilité

| Composant | Responsabilité | Ne doit pas devenir |
| --- | --- | --- |
| Windows/WSL2 | fournir le poste de contrôle | un exercice P5 |
| Terraform | gérer l'infrastructure AWS | un outil de copie de l'app Angular |
| Ansible | converger la configuration serveur | un outil de création du VPC |
| NGINX | servir Angular et produire les logs | le load-balancer de l'exercice 3 |
| OpenSearch | indexer et analyser les logs | une preuve visuelle automatique |
| HAProxy | répartir et superviser les backends | un substitut aux preuves de failover |
| GitHub Actions | tester le dépôt | une preuve que le compte AWS a été déployé |

Cette séparation constitue l'architecture de référence pour toute évolution du projet.
