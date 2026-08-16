# Architecture et flux du P5

## Objectif

Ce document décrit l'architecture de référence du P5 : environnement d'exécution,
responsabilités, composants AWS, flux de données, preuves et dépendances entre exercices.

Schéma synthétique :

![Architecture P5](schemas/vue-ensemble.svg)

## 1. Frontière du projet

```text
HOST Ubuntu
   │
   └── KVM/libvirt
        │
        └── VM ubuntu-devops / Ubuntu Server 26.04 CLI
                    │
                    ▼
              runtime P5
                    │
                    ▼
             exercices AWS
```

La plateforme HOST/KVM/VM est fournie par
[`mathiasseguincadiche/Ubuntu-desktops-custom`](https://github.com/mathiasseguincadiche/Ubuntu-desktops-custom).

Le P5 commence dans `ubuntu-devops`. Il prépare son runtime, pilote AWS et collecte les preuves
nécessaires aux trois exercices.

Contrat détaillé : [`../environment/vm-devops/README.md`](../environment/vm-devops/README.md).

## 2. Plan de contrôle

```text
VM ubuntu-devops
       │
       ▼
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

`p5.sh` est l'orchestrateur. Terraform conserve la propriété de l'infrastructure AWS et Ansible
celle de la configuration serveur.

## 3. Exercice 1 — Terraform + Ansible + Angular/NGINX

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

La CI reconstruit Angular et compare le build avec l'artefact servi par Ansible.

### Flux SSH

```text
VM ubuntu-devops
   │ TCP/22 autorisé depuis l'IPv4 publique /32
   ▼
EC2 p5-web
   ├── Ansible ping
   └── ansible-playbook deploy.yml
```

L'inventaire réel est généré dans la VM depuis les outputs Terraform.

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

NGINX applique le fallback SPA nécessaire aux routes Angular.

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

Le log réel peut être importé dans l'exercice 2.

## 4. Exercice 2 — Amazon OpenSearch

### Infrastructure

```text
Amazon OpenSearch Domain
├── OpenSearch 2.19
├── EBS gp3
├── chiffrement au repos
├── chiffrement node-to-node
├── HTTPS obligatoire
├── TLS >= 1.2
└── policy SourceIp = IPv4 publique d'administration /32
```

Le module est `terraform/exercice-2`.

### Pipeline de données

Sources admises :

```text
sample versionné
terraform/exercice-2/samples/nginx-access.log.sample

et, lorsqu'il est disponible,

log réel exercice 1
proofs/runtime/exercice-2/nginx-access-real.log
```

Pipeline :

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
   ├── mapping
   ├── nombre de documents
   └── agrégations
```

### Validation OpenSearch Dashboards

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

La création et la vérification visuelle du dashboard restent un checkpoint humain.

## 5. Exercice 3 — HAProxy et résilience

### Dépendance vers l'exercice 1

`terraform/exercice-3` réutilise le VPC et les subnets de l'exercice 1 à partir de leurs tags.

```text
Project  = p5-openclassrooms
Exercise = 1
```

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

Le port HTTP des backends est autorisé depuis le Security Group HAProxy.

### Configuration HAProxy

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

- `roundrobin` répartit les requêtes ;
- `fall 3` retire un backend après trois échecs consécutifs ;
- `rise 2` le réintègre après deux contrôles réussis.

### Flux de panne contrôlée

```text
HAProxy → hello-1 + hello-2
           ↓
arrêt contrôlé de hello-1
           ↓
health checks échouent
           ↓
HAProxy retire hello-1
           ↓
trafic → hello-2
           ↓
restauration hello-1
           ↓
health checks réussissent
           ↓
HAProxy réintègre hello-1
```

Le script de failover restaure le backend à la fin du test.

## 6. Flux de configuration

Source locale principale :

```text
environment/aws-readiness.env
```

Flux :

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

Les `terraform.tfvars` réels ne sont pas versionnés.

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

La réexécution repose sur le recalcul du delta, pas sur la recréation systématique.

## 8. Flux des preuves

```text
commande
   ↓
log d'étape
   ↓
redaction des secrets
   ↓
proofs/runtime/steps/<RUN_ID>
   ↓
SHA-256 + statut + durée dans manifest.tsv
   ↓
résumé du run
```

Les preuves runtime sont des traces techniques. Les livrables sélectionnent et expliquent les
éléments utiles à l'évaluation.

## 9. Dépendances d'exécution

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

- `ex1` fournit le log réel utilisé par `ex2` ;
- `ex3` dépend du réseau créé par `ex1` ;
- `ex2` peut utiliser le sample versionné pour les validations reproductibles.

## 10. Ordre de destruction

```text
terraform/exercice-3 destroy
          ↓
terraform/exercice-2 destroy
          ↓
terraform/exercice-1 destroy
          ↓
audit global AWS
```

L'exercice 3 doit être détruit avant l'exercice 1 en raison de sa dépendance réseau.

## 11. Responsabilités techniques

| Composant | Responsabilité |
| --- | --- |
| plateforme Ubuntu | HOST, KVM/libvirt, VM `ubuntu-devops` |
| runtime P5 | outils et configuration nécessaires au projet dans la VM |
| Terraform | infrastructure AWS |
| Ansible | configuration serveur et déploiement Angular/NGINX |
| NGINX | service Angular et production des logs HTTP |
| OpenSearch | indexation et analyse des logs |
| HAProxy | répartition, health checks et continuité de service |
| GitHub Actions | qualité, sécurité et non-régression du dépôt |

Cette répartition constitue le contrat d'architecture du projet.
