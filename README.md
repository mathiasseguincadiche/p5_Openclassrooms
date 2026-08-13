# P5 OpenClassrooms — Infrastructure as Code, observabilité et haute disponibilité sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt met en pratique un cycle DevOps complet autour d'AWS : **provisionner une infrastructure avec Terraform, configurer et déployer avec Ansible, exploiter des logs dans Amazon OpenSearch, puis démontrer la disponibilité d'un service avec HAProxy**.

> **Périmètre évalué : 100 % AWS.** Windows 11 et WSL2 constituent uniquement le poste de contrôle utilisé pour exécuter les outils. Ils ne sont pas un exercice du P5.

## En 30 secondes

Le projet comporte **trois exercices officiels** :

| Exercice | Question à résoudre | Réalisation dans ce dépôt | Résultat à prouver |
| --- | --- | --- | --- |
| **1 — Infrastructure et déploiement** | Comment construire une infrastructure reproductible et y déployer une application ? | Terraform crée le socle AWS ; Ansible déploie Angular derrière NGINX sur EC2 | infrastructure créée, application accessible et second passage Ansible avec `changed=0` |
| **2 — Logs et observabilité** | Comment transformer des logs HTTP en informations exploitables ? | Amazon OpenSearch reçoit un jeu reproductible et les logs NGINX réels ; OpenSearch Dashboards porte les visualisations | données indexées, agrégations valides, 3 visualisations et dashboard capturés |
| **3 — Disponibilité** | Comment continuer à servir du trafic lorsqu'un backend tombe ? | HAProxy répartit les requêtes vers deux `nginxdemos/hello` sur EC2 | round-robin, retrait du backend en panne, continuité du service et réintégration |

Le dépôt choisit le **mode Cloud AWS pour les trois exercices**. Les variantes locales proposées dans les consignes OpenClassrooms sont expliquées dans la documentation, mais elles ne constituent pas un second parcours maintenu ici.

## Architecture et dépendances

![Architecture et dépendances du P5](docs/schemas/vue-ensemble.svg)

Les exercices ne sont pas trois démonstrations isolées :

- l'**exercice 1** crée le VPC et les sous-réseaux réutilisés par l'exercice 3 ;
- l'**exercice 1** produit également le véritable `access.log` NGINX qui peut enrichir l'exercice 2 ;
- l'**exercice 2** conserve une étape volontairement humaine : construire et vérifier les visualisations dans OpenSearch Dashboards ;
- l'**exercice 3** dépend donc du réseau de l'exercice 1 et doit être détruit avant celui-ci ;
- les trois exercices alimentent enfin les preuves, les livrables et l'audit de nettoyage.

Le nettoyage final suit obligatoirement l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

## Ce que le dépôt automatise

Le point d'entrée officiel est :

```bash
bash scripts/commands/p5.sh
```

`p5.sh` est un orchestrateur convergent. Il applique le principe suivant :

```text
inspecter l'état réel
        ↓
calculer le delta
        ↓
aucun delta ? ── oui ──► ne rien modifier
        │
        non
        ↓
corriger uniquement ce qui diffère
        ↓
vérifier le résultat
        ↓
journaliser et conserver les preuves
```

Une relance du projet ne signifie donc pas « tout recréer ». Terraform recalcule l'écart, Ansible rejoue l'état désiré et les tests fonctionnels vérifient que le résultat est toujours réel.

### Commandes principales

| Commande | Rôle | Mutation possible |
| --- | --- | --- |
| `p5.sh` ou `p5.sh menu` | ouvrir le Control Center | selon l'action choisie |
| `p5.sh inspect` | observer l'état local, Terraform et AWS disponible | non |
| `p5.sh prepare` | préparer le poste, l'authentification AWS, le budget et les `tfvars` | oui, uniquement si nécessaire |
| `p5.sh status` | contrôler les prérequis sans déployer | non |
| `p5.sh ex1` | converger Terraform + Ansible + Angular/NGINX | oui |
| `p5.sh ex2` | converger OpenSearch et les données | oui |
| `p5.sh ex3` | converger HAProxy et rejouer les tests de résilience | oui |
| `p5.sh all` | exécuter le parcours complet sans détruire AWS | oui |
| `p5.sh diagnostics` | collecter les diagnostics et l'état des preuves | fichiers locaux uniquement |
| `p5.sh finalize` | contrôler les preuves et les livrables | fichiers locaux uniquement |
| `p5.sh logs` | consulter les journaux | non |
| `p5.sh cleanup` | détruire les ressources suivies puis auditer AWS | **oui, destructif** |

Documentation complète : [Centre de commande](docs/CENTRE_DE_COMMANDE.md).

## Parcours recommandé de A à Z

### 1. Comprendre avant d'exécuter

Commencer par :

1. [Cadre officiel et choix d'implémentation](docs/00-cadre-officiel.md) ;
2. [Architecture et flux](docs/architecture-et-flux.md) ;
3. [Parcours pédagogique](docs/01-parcours-debutant.md).

### 2. Préparer l'environnement de contrôle

Le code P5 est exécuté depuis **Windows 11 Pro + WSL2 + Ubuntu 26.04**. La workstation elle-même est maintenue dans le dépôt [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

Le checkout actif du P5 doit rester dans le filesystem Linux WSL2, par exemple :

```bash
~/labs/p5_Openclassrooms
```

et non sous `/mnt/c` ou `/mnt/d`.

Après ouverture du terminal :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

Le précontrôle est considéré comme valide lorsqu'il se termine par le verdict **`GO TERRAFORM`**. Ce verdict autorise à passer à la lecture du plan ; il ne dispense jamais de vérifier le delta et les coûts avant un `apply`.

Détails : [Installation et environnement de contrôle](docs/00-preparation-environnement.md) et [Préparation du compte AWS](docs/00b-preparation-compte-aws.md).

![Préparation de l'environnement](docs/schemas/etape-0.svg)

### 3. Exécuter l'exercice 1

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours :

1. construit ou vérifie l'artefact Angular ;
2. initialise Terraform ;
3. calcule le plan ;
4. n'applique que si un delta existe et après confirmation ;
5. récupère les outputs Terraform ;
6. génère l'inventaire Ansible ;
7. attend SSH et teste `ansible ping` ;
8. déploie Angular + NGINX ;
9. rejoue Ansible pour prouver l'idempotence ;
10. vérifie l'application ;
11. génère du trafic et collecte le vrai log NGINX.

Résultats attendus :

```text
Terraform : aucun delta après convergence
Ansible   : changed=0 | unreachable=0 | failed=0 au second passage
HTTP      : application Angular servie par NGINX
Logs      : access.log réel collecté pour l'exercice 2
```

Guide détaillé : [Exercice 1 — Terraform et Ansible](docs/exercices/01-terraform-ansible.md).

![Exercice 1](docs/schemas/exercice-1.svg)

### 4. Exécuter l'exercice 2

```bash
bash scripts/commands/p5.sh ex2
```

Le dépôt automatise l'infrastructure OpenSearch, la validation des logs, l'import Bulk et les contrôles des données. Il **ne valide pas à votre place les trois visualisations demandées**.

Dans OpenSearch Dashboards, il faut réellement vérifier ou créer :

1. un **donut** de répartition des méthodes HTTP ;
2. la **somme de `bytes_sent` par tranches de 12 h** ;
3. le **top 5 de `url_path` par tranches de 12 h** ;
4. le dashboard rassemblant ces trois visualisations.

Résultat attendu : données exploitables et **quatre captures réelles** : les trois visualisations et le dashboard complet.

Guide détaillé : [Exercice 2 — OpenSearch et dashboard](docs/exercices/02-elk-opensearch.md).

![Exercice 2](docs/schemas/exercice-2.svg)

### 5. Exécuter l'exercice 3

```bash
bash scripts/commands/p5.sh ex3
```

Terraform réutilise le réseau de l'exercice 1 et crée :

- une EC2 HAProxy accessible en HTTP ;
- deux EC2 backend exécutant `nginxdemos/hello` ;
- des Security Groups séparant le load-balancer et les backends.

Le test vérifie ensuite :

1. les deux backends en round-robin ;
2. l'arrêt contrôlé d'un backend ;
3. la continuité du service via le backend restant ;
4. la restauration ;
5. la réintégration automatique du backend.

Guide détaillé : [Exercice 3 — HAProxy](docs/exercices/03-haproxy.md).

![Exercice 3](docs/schemas/exercice-3.svg)

### 6. Finaliser les preuves

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Une CI verte prouve la cohérence du **dépôt** ; elle ne prouve pas qu'un `terraform apply` réel a été exécuté sur votre compte AWS.

Les preuves runtime sont conservées localement sous :

```text
proofs/runtime/
logs/<UTC>/
```

Elles doivent être relues et, lorsque nécessaire, anonymisées avant d'être intégrées aux livrables.

Verdict final attendu avant remise :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Guide : [Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md).

![Finalisation](docs/schemas/finalisation/finalisation.svg)

### 7. Nettoyer AWS

Une fois les preuves terminées :

```bash
bash scripts/commands/p5.sh cleanup
```

La destruction finale exige une confirmation forte et suit l'ordre `3 → 2 → 1`.

Le projet n'est considéré comme fermé que lorsque l'audit affiche :

```text
NETTOYAGE AWS COMPLET
```

## Les trois exercices en détail

### Exercice 1 — Terraform + Ansible

Terraform est responsable de l'infrastructure ; Ansible est responsable de la configuration du système et de l'application. Le dépôt garde volontairement cette séparation :

```text
Terraform
  └── AWS : VPC, réseau, Security Group, clé, EC2
             ↓ SSH
Ansible
  └── Ubuntu : NGINX, fichiers Angular, configuration, service
```

La validation locale et la CI vérifient notamment `terraform fmt`, `terraform validate`, la syntaxe Ansible, la configuration NGINX et la synchronisation entre le build Angular et l'artefact réellement déployé.

### Exercice 2 — Amazon OpenSearch

La consigne OpenClassrooms parle historiquement de la stack ELK et de Kibana. Dans le **mode Cloud retenu**, le service AWS utilisé est Amazon OpenSearch et l'interface correspondante est OpenSearch Dashboards. Le besoin pédagogique reste le même : transformer des logs NGINX en données indexées puis construire les trois visualisations attendues.

### Exercice 3 — HAProxy

Le comportement attendu est plus important que la simple présence du fichier de configuration : le service doit montrer l'alternance entre les deux backends, détecter la panne d'un backend, continuer à répondre puis réintégrer le backend restauré.

La configuration met notamment en œuvre :

```text
balance roundrobin
option httpchk GET /
fall 3
rise 2
```

## Sécurité et maîtrise des coûts

Le projet inclut des garde-fous explicites :

- verrouillage du compte AWS attendu avec `allowed_account_ids` ;
- refus du compte root pour l'exploitation normale ;
- préférence pour des identifiants temporaires ;
- SSH limité à l'IPv4 publique `/32` du poste ;
- IMDSv2 obligatoire sur les EC2 ;
- volumes racine EC2 chiffrés ;
- HTTPS et chiffrement OpenSearch ;
- budget AWS contrôlé avant le déploiement ;
- `terraform.tfstate`, `terraform.tfvars`, inventaires réels, clés et preuves brutes exclus de Git ;
- confirmations humaines conservées pour les actions sensibles.

Une CI verte ne signifie pas « coût nul ». Toujours relire le plan Terraform et terminer par l'audit de nettoyage.

Voir [SECURITY.md](SECURITY.md) et [Préparation du compte AWS](docs/00b-preparation-compte-aws.md).

## Versions de référence

Le contrat reproductible est versionné dans `environment/versions.env`. Les versions de travail principales sont notamment :

| Composant | Référence du dépôt |
| --- | --- |
| Ubuntu WSL2 | 26.04 |
| Node.js | 22.22.0 |
| Ansible Core | 2.20.1 |
| Terraform | 1.15.8 |
| OpenSearch local de CI | 2.19.6 |
| NGINX de CI | `nginx:1.28-alpine` |
| HAProxy de CI | `haproxy:3.2-alpine` |

Les EC2 des exercices 1 et 3 sélectionnent automatiquement une AMI **Ubuntu 24.04 LTS** si aucune AMI explicite n'est fournie. Le système du poste de contrôle et celui des serveurs AWS sont donc volontairement deux contextes différents.

## Arborescence utile

```text
p5_Openclassrooms/
├── application/angular/       # sources de l'application Angular
├── ansible/                   # playbook, inventaire exemple et artefact Angular
├── aws/                       # politique IAM et modèle de budget
├── environment/               # contrat de versions et configuration locale modèle
├── terraform/
│   ├── exercice-1/            # réseau + EC2 Angular
│   ├── exercice-2/            # Amazon OpenSearch
│   └── exercice-3/            # HAProxy + deux backends
├── scripts/
│   ├── commands/              # commandes opérateur et orchestrateur p5.sh
│   ├── lib/                   # runtime, logs et preuves
│   ├── tests/                 # contrats reproductibles
│   └── tools/                 # audits et transformations
├── proofs/                    # convention de preuves ; runtime ignoré par Git
└── docs/                      # documentation officielle du projet
```

## Documentation officielle

Le portail est [`docs/README.md`](docs/README.md).

Pour aller droit au but :

- **je découvre le projet** → [Parcours pédagogique](docs/01-parcours-debutant.md) ;
- **je veux tout exécuter de A à Z** → [Runbook d'exécution guidée](docs/RUNBOOK_EXECUTION_GUIDEE.md) ;
- **je veux comprendre l'architecture** → [Architecture et flux](docs/architecture-et-flux.md) ;
- **je veux comprendre une commande** → [Centre de commande](docs/CENTRE_DE_COMMANDE.md) puis le guide de l'exercice concerné ;
- **je reprends après une interruption** → [Convergence et réexécution](docs/convergence-et-reexecution.md) ;
- **je suis bloqué** → [Troubleshooting](docs/troubleshooting.md) ;
- **je prépare la remise** → [Livrables](docs/livrables/README.md) et [Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md) ;
- **je vérifie la conformité aux consignes** → [Traçabilité consignes → code → preuves](docs/02-correspondance-consignes-depot.md).

## Ce qui n'est pas le P5

Kubernetes, Helm, Prometheus, Grafana et Vault ne font pas partie des trois exercices de ce projet. GitHub Actions protège le dépôt, mais n'est pas un quatrième exercice.

Le but du P5 est volontairement lisible :

```text
Infrastructure as Code
        +
Configuration as Code
        +
Observabilité
        +
Haute disponibilité
        +
Preuves opérationnelles
```

C'est ce parcours que le code, la documentation, les tests et les livrables de ce dépôt doivent tous raconter de la même manière.