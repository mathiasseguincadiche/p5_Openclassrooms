# Architecture et flux du P5

## Objectif

Ce document décrit l'architecture de référence du P5 : frontières de responsabilité, plan de
contrôle, composants AWS, flux réseau et données, convergence, preuves et dépendances entre
exercices.

![Architecture de référence du P5](schemas/vue-ensemble.svg)

Les schémas spécialisés sont regroupés dans [`schemas/README.md`](schemas/README.md). Ils portent la
lecture rapide ; le présent document conserve les détails techniques qui justifient cette architecture.

## 1. Frontière du projet

La plateforme Windows/WSL2 est fournie par
[`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

Le P5 commence dans **`Ubuntu` sous WSL2**. Il possède :

- son runtime logiciel dans WSL2 ;
- son plan de contrôle `p5.sh` ;
- les modules Terraform des trois exercices ;
- la configuration Ansible et l'application Angular ;
- les scripts OpenSearch et HAProxy ;
- les preuves et livrables du projet.

Le P5 ne gère pas le cycle de vie WSL2 de la distribution WSL2.

Contrat détaillé : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

## 2. Plan de contrôle

```text
distribution WSL2 Ubuntu
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

`p5.sh` orchestre le parcours. Terraform reste propriétaire de l'infrastructure AWS et Ansible de la
configuration serveur.

Le cycle général est :

```text
inspecter → calculer le delta → corriger → vérifier → prouver
```

## 3. Exercice 1 — infrastructure et déploiement

Vue spécialisée : [`schemas/exercice-1.svg`](schemas/exercice-1.svg).

Le point important est la séparation des responsabilités :

```text
application/angular ── npm build ──► artefact Angular ───────┐
                                                             │
terraform/exercice-1 ──► VPC + SG + EC2 + outputs ───────────┤
                                                             ▼
                                                          Ansible
                                                             │
                                                             ▼
                                                     NGINX + Angular
```

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
        └── volume racine gp3 chiffré
```

### Flux SSH

```text
distribution WSL2 Ubuntu
   │ TCP/22 depuis l'IPv4 publique /32
   ▼
EC2 p5-web
   ├── Ansible ping
   └── ansible-playbook deploy.yml
```

### Flux HTTP et logs

```text
Internet → Security Group web → NGINX → Angular SPA
                                      │
                                      ▼
                              /var/log/nginx/access.log
                                      │ collecte SSH
                                      ▼
                 proofs/runtime/exercice-2/nginx-access-real.log
```

Le log réel devient une source de données de l'exercice 2.

## 4. Exercice 2 — OpenSearch et observabilité

Vue spécialisée : [`schemas/exercice-2.svg`](schemas/exercice-2.svg).

### Domaine AWS

Le module `terraform/exercice-2` crée un domaine Amazon OpenSearch avec :

- OpenSearch 2.19 ;
- EBS gp3 ;
- chiffrement au repos ;
- chiffrement node-to-node ;
- HTTPS obligatoire ;
- TLS >= 1.2 ;
- accès limité à l'IPv4 publique d'administration `/32`.

### Deux sources, un pipeline

```text
sample versionné ──────────────┐
                               ├──► convert-nginx-logs.py
access.log réel de l'ex. 1 ────┘
                                      │
                                      ▼
                              documents Bulk NDJSON
                                      │
                                      ▼
                        import-opensearch-data.sh
                                      │
                                      ▼
                             index nginx-access-*
                                      │
                                      ▼
                        verify-opensearch-data.sh
```

La validation technique automatise mapping, nombre de documents et agrégations. La création et la
vérification visuelle de Discover, des trois visualisations et du dashboard restent un checkpoint
humain.

## 5. Exercice 3 — HAProxy et résilience

Vue spécialisée : [`schemas/exercice-3.svg`](schemas/exercice-3.svg).

`terraform/exercice-3` réutilise le VPC et les subnets de l'exercice 1 à partir de leurs tags.

### Topologie réseau

```text
Internet
   │ TCP/80 public
   ▼
Security Group HAProxy
   ▼
EC2 p5-haproxy
   │ HTTP privé
   ├───────────────┐
   ▼               ▼
EC2 hello-1     EC2 hello-2
Docker           Docker
nginxdemos/hello nginxdemos/hello
```

Le Security Group des backends autorise HTTP depuis le Security Group HAProxy, pas depuis Internet.

### Health checks

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

Le scénario de preuve est :

```text
2 backends UP
      ↓
arrêt contrôlé de hello-1
      ↓
health checks → DOWN
      ↓
trafic maintenu vers hello-2
      ↓
restauration hello-1
      ↓
health checks → UP
      ↓
réintégration dans le pool
```

Le script de failover restaure le backend même en cas d'interruption intermédiaire.

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

Les vrais `terraform.tfvars` ne sont pas versionnés.

## 7. Flux Terraform et convergence

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

La réexécution repose sur le recalcul du delta et la conservation du state, pas sur une recréation
systématique.

Référence : [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

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

Les traces runtime sont privées par défaut. Les livrables sélectionnent, contextualisent et
anonymisent les éléments nécessaires à l'évaluation.

Référence : [`validation-preuves-nettoyage.md`](validation-preuves-nettoyage.md).

## 9. Dépendances d'exécution

```text
prepare
  ↓
ex1
  ├──► ex2  via access.log
  └──► ex3  via VPC/subnets
        ↓
diagnostics
  ↓
finalize
```

- `ex2` peut utiliser le sample versionné pour ses validations reproductibles ;
- la preuve réelle d'observabilité utilise le log de l'exercice 1 ;
- `ex3` dépend réellement du réseau de l'exercice 1.

## 10. Ordre de destruction

Vue spécialisée : [`schemas/finalisation/finalisation.svg`](schemas/finalisation/finalisation.svg).

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
| plateforme Windows | Windows 11 Pro, WSL2 et distribution `Ubuntu` |
| runtime P5 | outils et configuration nécessaires au projet dans WSL2 |
| `p5.sh` | orchestration et garde-fous |
| Terraform | infrastructure AWS et propriété via le state |
| Ansible | configuration serveur et déploiement Angular/NGINX |
| NGINX | service Angular et production des logs HTTP |
| OpenSearch | indexation et analyse des logs |
| OpenSearch Dashboards | validation visuelle avec checkpoint humain |
| HAProxy | répartition, health checks et continuité de service |
| GitHub Actions | qualité, sécurité et non-régression du dépôt |

Cette répartition constitue le contrat d'architecture du P5.
