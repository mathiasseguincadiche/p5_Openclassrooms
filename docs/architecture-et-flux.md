# Architecture et flux du P5

## Objectif

Ce document décrit **comment le P5 est réellement construit** : frontières de responsabilité, plan de contrôle, composants AWS, flux réseau, flux de données, convergence, preuves et dépendances entre exercices.

Il répond principalement à :

```text
quels composants existent ?
qui possède quoi ?
comment communiquent-ils ?
d'où viennent les valeurs utilisées ?
quelles dépendances imposent l'ordre d'exécution et de destruction ?
```

Pour apprendre progressivement les concepts, utiliser [`01-parcours-debutant.md`](01-parcours-debutant.md). Pour exécuter le projet, utiliser [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).

![Architecture de référence du P5](schemas/vue-ensemble.svg)

## 1. Architecture en couches

Le projet peut être lu en cinq couches :

```text
1. plateforme
   Windows 11 Pro + WSL2 + distribution Ubuntu

2. plan de contrôle P5
   p5.sh + scripts + runtime spécifique

3. infrastructure AWS
   Terraform exercices 1, 2 et 3

4. configuration / application / données
   Ansible + Angular + NGINX + pipeline OpenSearch + HAProxy

5. validation
   logs + preuves + livrables + CI + non-régression
```

Cette séparation évite une confusion fréquente : un seul dépôt orchestre plusieurs outils, mais chaque outil conserve une responsabilité précise.

## 2. Frontière plateforme / projet

La plateforme Windows/WSL2 est fournie par [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

### La plateforme possède

- Windows 11 Pro ;
- WSL2 ;
- la distribution `Ubuntu` ;
- le VHDX ;
- le réseau et le DNS WSL2 ;
- systemd ;
- Docker Engine ;
- Terraform ;
- AWS CLI.

### Le P5 possède

- son contrat d'exécution dans WSL2 ;
- son runtime spécifique, notamment Node.js et Ansible Core ;
- son plan de contrôle `p5.sh` ;
- sa configuration AWS locale ;
- ses `terraform.tfvars`, states, inventaires, logs et preuves locaux ;
- les trois modules Terraform ;
- la configuration Ansible ;
- l'application Angular ;
- les scripts OpenSearch et HAProxy ;
- les livrables et contrôles de non-régression.

Le P5 ne crée, ne déplace, n'exporte et ne détruit pas la distribution WSL2.

Contrat détaillé : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

## 3. Deux contextes Ubuntu distincts

L'architecture utilise plusieurs machines Linux.

| Contexte | Version de référence | Fonction |
| --- | --- | --- |
| distribution WSL2 locale | Ubuntu 26.04 LTS `resolute` | plan de contrôle du P5 |
| EC2 exercice 1 | Ubuntu 24.04 LTS `noble` par défaut | cible Ansible, NGINX et Angular |
| EC2 exercice 3 | Ubuntu 24.04 LTS `noble` par défaut | HAProxy et backends |

Le code source de cette distinction se trouve notamment dans :

- `environment/versions.env` pour WSL2 ;
- les filtres AMI des modules Terraform exercices 1 et 3 pour les EC2.

Une documentation qui parle d'« Ubuntu » sans préciser le contexte doit être lue avec prudence.

## 4. Plan de contrôle

```text
distribution WSL2 Ubuntu 26.04
       │
       ▼
scripts/commands/p5.sh
       │
       ├── scripts/lib/p5-runtime.sh
       │      ├── journalisation
       │      ├── preuves par étape
       │      ├── confirmations
       │      └── validation de valeurs
       │
       ├── scripts/commands/*.sh
       ├── scripts/tools/*
       ├── terraform/exercice-*/
       └── ansible/playbooks/deploy.yml
```

`p5.sh` orchestre le parcours mais ne remplace pas les outils qu'il appelle.

### Responsabilités

```text
p5.sh      → orchestration, garde-fous, ordre et preuves
Terraform  → infrastructure AWS et propriété via le state
Ansible    → configuration de l'EC2 exercice 1
Angular    → artefact applicatif
NGINX      → service web + logs HTTP
OpenSearch → indexation et analyse des logs
HAProxy    → répartition et health checks
```

Cycle général :

```text
inspecter → calculer le delta → confirmer → corriger → vérifier → prouver
```

## 5. Sources de vérité

L'architecture ne doit pas dépendre d'informations recopiées manuellement dans plusieurs documents.

| Domaine | Source de vérité |
| --- | --- |
| runtime WSL2 | `environment/versions.env` + contrôles de bootstrap |
| configuration locale du lab | `environment/aws-readiness.env` |
| commandes disponibles | `scripts/commands/p5.sh` |
| ressources AWS | `terraform/exercice-{1,2,3}/` |
| valeurs runtime d'infrastructure | outputs Terraform |
| configuration NGINX/Angular | `ansible/playbooks/deploy.yml` + `ansible/files/` |
| source applicative | `application/angular/` |
| données OpenSearch | sample/log réel + parser + mapping + scripts d'import |
| comportement HAProxy | `terraform/exercice-3/haproxy.cfg.tpl` |
| preuves/logs | `scripts/lib/p5-runtime.sh` |
| non-régression | `scripts/tools/audit_non_regression.py` + workflows GitHub Actions |

Matrice détaillée : [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md).

## 6. Exercice 1 — infrastructure et déploiement

Vue spécialisée : [`schemas/exercice-1.svg`](schemas/exercice-1.svg).

Le point essentiel est la séparation entre **construction de l'infrastructure** et **configuration du serveur**.

```text
application/angular/
       │ npm build
       ▼
artefact Angular
       │
       ├─────────────────────────────────────┐
       │                                     │
terraform/exercice-1                         │
       │                                     │
       ▼                                     │
VPC + réseau + SG + EC2 + outputs            │
       │                                     │
       └───────────────┬─────────────────────┘
                       ▼
                    Ansible
                       │
                       ▼
                NGINX + Angular
```

### 6.1 Infrastructure AWS

Le module crée :

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
        ├── Ubuntu 24.04 LTS par défaut
        ├── Python 3 via user_data
        ├── IMDSv2 obligatoire
        └── volume racine gp3 chiffré
```

### 6.2 Flux SSH

```text
WSL2 Ubuntu 26.04
   │ TCP/22 depuis l'IPv4 publique /32
   ▼
EC2 p5-web Ubuntu 24.04
   ├── Ansible ping
   └── ansible-playbook deploy.yml
```

L'inventaire Ansible doit être construit à partir de l'output Terraform pertinent plutôt qu'à partir d'une IP mémorisée.

### 6.3 Configuration Ansible

Le playbook :

```text
installe NGINX + curl
      ↓
crée appuser/appgroup
      ↓
crée /var/www/p5
      ↓
copie l'artefact Angular
      ↓
installe la configuration NGINX
      ↓
nginx -t
      ↓
active et démarre NGINX
```

Les handlers évitent de recharger NGINX sans changement pertinent. Le second passage est utilisé comme preuve d'idempotence.

### 6.4 Flux HTTP et logs

```text
Internet
   │ HTTP :80
   ▼
Security Group web
   ▼
NGINX
   ├──► Angular SPA
   │
   └──► /var/log/nginx/access.log
             │ collecte SSH
             ▼
proofs/runtime/exercice-2/nginx-access-real.log
```

Le log réel devient une entrée de l'exercice 2.

## 7. Exercice 2 — OpenSearch et observabilité

Vue spécialisée : [`schemas/exercice-2.svg`](schemas/exercice-2.svg).

### 7.1 Domaine AWS

`terraform/exercice-2` crée un domaine Amazon OpenSearch avec notamment :

- version moteur configurable, référence `OpenSearch_2.19` ;
- une instance pour le lab ;
- EBS gp3 ;
- chiffrement au repos ;
- chiffrement node-to-node ;
- HTTPS obligatoire ;
- TLS 1.2 minimum ;
- accès limité à l'IPv4 publique d'administration `/32`.

La consigne pédagogique peut employer le vocabulaire ELK/Kibana ; l'implémentation réelle de ce dépôt utilise Amazon OpenSearch et OpenSearch Dashboards.

### 7.2 Deux sources, un pipeline

```text
sample versionné ──────────────┐
                               │
access.log réel de l'ex. 1 ────┤
                               ▼
                    convert-nginx-logs.py
                               │
                               ▼
                    documents Bulk NDJSON
                               │
                               ▼
                    import-opensearch-data.sh
                               │
                               ▼
                         OpenSearch
                               │
                               ▼
                    verify-opensearch-data.sh
                               │
                               ▼
                    OpenSearch Dashboards
```

### 7.3 Pourquoi deux sources ?

Le sample :

- rend les tests reproductibles ;
- permet une CI sans EC2 AWS ;
- stabilise le contrat de parsing.

Le log réel :

- prouve le lien entre l'application réellement déployée et l'observabilité.

### 7.4 Validation automatique et humaine

Automatisable :

- parsing ;
- mapping ;
- import ;
- nombre de documents ;
- agrégations.

Checkpoint humain :

- Discover ;
- trois visualisations ;
- dashboard complet ;
- captures finales.

Cette frontière est volontaire : l'automatisation ne doit pas fabriquer une preuve visuelle à la place de l'opérateur.

## 8. Exercice 3 — HAProxy et résilience

Vue spécialisée : [`schemas/exercice-3.svg`](schemas/exercice-3.svg).

L'exercice 3 **réutilise** le VPC et les subnets de l'exercice 1 à partir de leurs tags.

### 8.1 Topologie réseau

```text
Internet
   │ TCP/80 public
   ▼
Security Group HAProxy
   ▼
EC2 p5-haproxy
Ubuntu 24.04
HAProxy installé via apt
   │ HTTP privé
   ├────────────────┐
   ▼                ▼
EC2 hello-1      EC2 hello-2
Ubuntu 24.04     Ubuntu 24.04
Docker           Docker
nginxdemos/hello nginxdemos/hello
```

Le Security Group des backends autorise HTTP depuis le **Security Group HAProxy**, pas depuis Internet entier.

Les backends restent joignables en SSH depuis l'IPv4 `/32` du poste d'administration pour les opérations de test prévues.

### 8.2 Configuration HAProxy

Le template définit notamment :

```text
balance roundrobin
option httpchk GET /
http-check expect status 200
check inter 3s fall 3 rise 2
```

### 8.3 Scénario de résilience

```text
2 backends UP
      ↓
trafic réparti
      ↓
arrêt contrôlé d'un backend
      ↓
health checks → DOWN
      ↓
trafic maintenu vers le backend sain
      ↓
restauration
      ↓
health checks → UP
      ↓
réintégration dans le pool
```

La preuve porte donc sur le **comportement**, pas uniquement sur la syntaxe du fichier HAProxy.

Le script de failover prévoit la restauration du backend afin de ne pas laisser volontairement l'environnement dans un état dégradé.

## 9. Flux de configuration

La configuration locale principale est :

```text
environment/aws-readiness.env
```

Elle centralise notamment :

- profil et région AWS ;
- compte attendu ;
- IPv4 `/32` ;
- clé SSH ;
- types d'instances ;
- paramètres OpenSearch ;
- budget et confirmations.

Flux :

```text
environment/aws-readiness.env
        │
        ▼
sync-terraform-tfvars.sh
        │
    ┌───┼───┐
    ▼   ▼   ▼
   ex1 ex2 ex3
terraform.tfvars locaux
```

Les vrais `terraform.tfvars` restent locaux, avec des permissions restrictives, et ne sont pas versionnés.

## 10. Flux Terraform et convergence

Pour chaque exercice :

```text
terraform init
      ↓
terraform plan -detailed-exitcode -out=tfplan
      ↓
terraform show tfplan
      ↓
code 0 = aucun delta ──► pas d'apply
code 2 = delta réel ───► confirmation
      ↓
sauvegarde locale du state
      ↓
terraform apply tfplan
      ↓
nouvelle sauvegarde du state
      ↓
post-plan
      ↓
aucun delta attendu
```

Le principe est important :

> la réexécution repose sur le recalcul du delta et la conservation du state, pas sur une recréation systématique.

Référence : [`convergence-et-reexecution.md`](convergence-et-reexecution.md).

## 11. Flux des preuves

Le runtime organise les preuves par exécution et par étape.

```text
commande
   ↓
log d'étape
   ↓
redaction des secrets lorsqu'applicable
   ↓
proofs/runtime/...
   ↓
manifest / résumé
   ↓
sélection humaine pour les livrables
```

Les traces brutes sont privées par défaut. Un livrable ne doit publier que les éléments nécessaires, contextualisés et relus.

Référence : [`contrat-preuves-automatiques.md`](contrat-preuves-automatiques.md).

## 12. Dépendances d'exécution

```text
prepare
  ↓
status
  ↓
ex1
  ├──► ex2 via access.log réel
  └──► ex3 via VPC/subnets
        ↓
diagnostics
  ↓
finalize
```

Nuance importante :

- ex2 dispose d'un sample versionné et peut tester son pipeline de manière reproductible ;
- la preuve réelle d'observabilité peut utiliser le log de l'exercice 1 ;
- ex3 dépend réellement du réseau de l'exercice 1.

## 13. Ordre de destruction

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

L'exercice 3 doit être détruit avant l'exercice 1 à cause de sa dépendance réseau.

Le verdict final du parcours est :

```text
NETTOYAGE AWS COMPLET
```

L'arrêt de la distribution WSL2 n'est pas un nettoyage AWS.

## 14. Architecture de validation

La validation du projet possède plusieurs niveaux :

```text
source code / configuration
        ↓
validation locale
        ↓
GitHub Actions
        ↓
exécution AWS réelle
        ↓
preuves runtime
        ↓
livrables
```

### La CI peut prouver

- cohérence syntaxique ;
- lint et tests ;
- validation Terraform ;
- syntaxe Ansible ;
- build Angular ;
- comportement local des composants testables ;
- non-régression structurelle et documentaire.

### La CI ne peut pas prouver à elle seule

- l'exécution réelle des exercices dans le compte AWS de l'opérateur ;
- la construction visuelle effective du dashboard ;
- une panne AWS réellement observée ;
- la qualité finale des captures de soutenance.

La distinction correcte est :

```text
CI verte = dépôt cohérent
preuve AWS = comportement réellement observé
```

## 15. Matrice des responsabilités techniques

| Composant | Responsabilité | Ne possède pas |
| --- | --- | --- |
| `Windows_11_Pro_Custom` | Windows, WSL2, distribution, stack commune | ressources AWS du P5 |
| runtime P5 | dépendances et configuration propres au projet | cycle de vie WSL2 |
| `p5.sh` | orchestration, garde-fous, preuves | infrastructure hors Terraform |
| Terraform | ressources AWS + state | configuration NGINX/Angular de l'EC2 ex. 1 |
| Ansible | configuration de l'EC2 ex. 1 | VPC/EC2 AWS |
| Angular | artefact applicatif | infrastructure |
| NGINX | service Angular + logs HTTP | analyse des logs |
| OpenSearch | stockage/analyse des logs | création automatique des preuves visuelles humaines |
| OpenSearch Dashboards | exploration/visualisation | infrastructure AWS globale |
| HAProxy | répartition et health checks | création du réseau |
| GitHub Actions | qualité et non-régression | preuve d'exécution AWS réelle |

Cette matrice constitue le contrat d'architecture du P5.

## 16. Règles de maintenance de ce document

Relire cette architecture lorsque changent :

- `environment/versions.env` ;
- les commandes/orchestrations de `p5.sh` ;
- un module Terraform ;
- le playbook Ansible ;
- le pipeline Angular ;
- le mapping ou les scripts OpenSearch ;
- `haproxy.cfg.tpl` ;
- l'organisation des preuves ;
- les dépendances entre exercices.

La liste détaillée des déclencheurs est maintenue dans [`MATRICE_TRACABILITE.md`](MATRICE_TRACABILITE.md).
