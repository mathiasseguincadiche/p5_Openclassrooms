# 01 — Parcours débutant : comprendre le P5 avant de l'exécuter

## À qui s'adresse ce guide ?

Ce document est destiné à une personne qui découvre le dépôt et veut comprendre **ce qu'elle va faire avant de lancer des commandes AWS**.

Aucune maîtrise préalable de Terraform, Ansible, OpenSearch ou HAProxy n'est supposée. En revanche, ce guide n'essaie pas de remplacer un cours complet sur chacun de ces outils : il explique les concepts nécessaires **dans le contexte exact du P5**.

Si un terme reste inconnu, utiliser le [`GLOSSAIRE.md`](GLOSSAIRE.md).

Ce guide répond à six questions :

1. quel problème chaque exercice résout-il ?
2. quel outil est responsable de quoi ?
3. dans quelle machine une commande est-elle exécutée ?
4. comment les exercices s'enchaînent-ils ?
5. que doit-on observer pour considérer une étape réussie ?
6. quelles actions peuvent créer un coût, modifier AWS ou détruire des ressources ?

Pour la procédure exacte à exécuter de A à Z, utiliser ensuite [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).

> **Ce document explique ; le runbook fait exécuter.**  
> Si vous cherchez uniquement la prochaine commande, vous êtes probablement dans le mauvais document.

## Le P5 en une phrase

Le projet apprend à **créer une infrastructure AWS avec du code, configurer une application de manière reproductible, exploiter ses logs, puis démontrer qu'un service peut continuer à répondre lorsqu'un backend tombe**.

## Vision d'ensemble

```text
Windows 11 Pro
    ↓
WSL2 — Ubuntu 26.04
plan de contrôle du P5
    ↓
inspect → prepare → status
    ↓
Exercice 1
Terraform construit l'infrastructure
Ansible configure et déploie Angular/NGINX
    ↓
   ┌────────────────────┐
   │                    │
   ▼                    ▼
Exercice 2          Exercice 3
OpenSearch          HAProxy
logs NGINX          réutilise réseau ex. 1
   │                    │
   └──────────┬─────────┘
              ▼
      preuves et livrables
              ↓
       nettoyage 3 → 2 → 1
```

## Avant toute chose : comprendre qu'il existe plusieurs machines

Le mot « Ubuntu » apparaît à plusieurs endroits dans le projet, mais il ne désigne pas toujours la même machine.

| Machine | Version | Rôle |
| --- | --- | --- |
| **distribution WSL2 locale** | Ubuntu 26.04 LTS `resolute` | plan de contrôle : Bash, Terraform, Ansible, AWS CLI, Node.js, scripts P5 |
| **EC2 exercice 1** | Ubuntu 24.04 LTS `noble` par défaut | cible Ansible qui héberge NGINX et Angular |
| **EC2 exercice 3** | Ubuntu 24.04 LTS `noble` par défaut | HAProxy et deux backends de démonstration |

Cette différence est normale.

Quand une documentation dit :

```text
« Dans Ubuntu sous WSL2 »
```

elle parle de votre environnement Linux local.

Quand elle dit :

```text
« Sur l'EC2 p5-web »
```

elle parle d'une machine créée dans AWS.

## Étape 0 — Comprendre la frontière Windows / WSL2 / P5

Le P5 ne construit pas lui-même votre poste Windows ni la distribution WSL2.

La plateforme est fournie par [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

La séparation est :

```text
Windows_11_Pro_Custom
└── Windows 11 Pro
    └── WSL2
        └── distribution Ubuntu
            ├── Docker Engine
            ├── Terraform
            └── AWS CLI

p5_Openclassrooms
└── dans cette distribution Ubuntu
    ├── runtime spécifique P5
    ├── Node.js / Ansible propres au projet
    ├── configuration AWS du lab
    ├── Terraform des exercices
    ├── Ansible
    ├── application Angular
    ├── scripts
    ├── logs
    └── preuves
```

Le P5 ne crée, ne déplace, n'exporte et ne supprime jamais la distribution WSL2 ou son VHDX.

### Pourquoi le checkout reste-t-il dans le filesystem Linux ?

Le workspace attendu est par exemple :

```text
~/labs/p5_Openclassrooms
```

et non :

```text
/mnt/c/...
/mnt/d/...
```

Le projet utilise Bash, permissions Unix, Terraform, Ansible, Docker et de nombreux petits fichiers. Le filesystem Linux du VHDX est donc le contexte de référence.

Le fait que le VHDX soit physiquement stocké sur `D:` ne signifie pas que le projet travaille sous `/mnt/d`.

Référence : [`../environment/wsl2/README.md`](../environment/wsl2/README.md).

## Étape 1 — Comprendre le centre de commande `p5.sh`

Le point d'entrée principal est :

```bash
bash scripts/commands/p5.sh
```

Sans argument, un menu s'ouvre. Une commande peut aussi être appelée directement :

```bash
bash scripts/commands/p5.sh inspect
```

### Pourquoi existe-t-il un orchestrateur ?

On pourrait lancer Terraform, Ansible et tous les scripts à la main. `p5.sh` ajoute cependant un contrat commun :

- ordre d'exécution ;
- contrôles de prérequis ;
- lecture de l'état réel ;
- gestion des deltas Terraform ;
- confirmations ;
- vérification des outputs ;
- journalisation ;
- collecte des preuves ;
- checkpoints humains ;
- nettoyage ordonné.

### Le principe de convergence

Le moteur ne part pas du principe que rien n'existe.

Il compare :

```text
état attendu
    vs
état réel
```

Puis :

```text
aucun écart → ne rien modifier
écart connu  → corriger cet écart
état inconnu → s'arrêter et chercher une source fiable
```

C'est essentiel pour pouvoir reprendre le projet après une fermeture de terminal ou un redémarrage.

## Étape 2 — Comprendre `inspect`, `prepare` et `status`

Ces trois commandes ne font pas la même chose.

### `inspect` — observer

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` cherche à savoir ce qui existe déjà :

- configuration ;
- states Terraform ;
- outputs ;
- preuves ;
- état de reprise.

**Idée à retenir :** avant de réparer, observer.

### `prepare` — converger les prérequis

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` ne veut pas dire « créer les trois exercices ».

Le P5 vérifie les outils communs fournis par la plateforme Windows/WSL2, notamment Terraform, AWS CLI et Docker, puis converge ses propres besoins lorsqu'ils présentent un écart :

- Node.js ;
- Ansible Core ;
- dépendances/outils de validation du projet ;
- configuration locale AWS ;
- clé SSH du lab ;
- IPv4 publique `/32` ;
- budget ;
- `terraform.tfvars` locaux.

### `status` — vérifier sans déployer

```bash
bash scripts/commands/p5.sh status
```

Le verdict attendu avant le passage à Terraform est :

```text
GO TERRAFORM
```

Cela veut dire :

> le lab est suffisamment qualifié pour lire un plan Terraform.

Cela ne veut pas dire :

> appliquer tout ce que Terraform propose sans le lire.

## Avant la première mutation AWS : les cinq questions à savoir répondre

Avant d'accepter un changement Terraform, vous devez pouvoir dire :

1. **quel compte AWS** est utilisé ?
2. **quelle région** est utilisée ?
3. **quelles ressources** le plan veut créer/modifier/détruire ?
4. **pourquoi** ces ressources sont nécessaires à l'exercice ?
5. **quel coût ou risque** peut subsister tant qu'elles existent ?

Si l'une de ces réponses est inconnue, ne confirmez pas encore la mutation.

## Étape 3 — Exercice 1 : Terraform construit, Ansible configure

C'est la séparation la plus importante du premier exercice.

### Terraform : l'infrastructure

Terraform décrit notamment :

```text
VPC 10.0.0.0/16
├── subnet public 1
├── subnet public 2
├── Internet Gateway
├── table de routage publique
├── Security Group web
├── paire de clés EC2
└── EC2 Ubuntu 24.04
```

Il fixe aussi des garde-fous comme :

- SSH limité à votre IPv4 publique `/32` ;
- HTTP public sur le port 80 pour la démonstration ;
- IMDSv2 obligatoire ;
- volume racine gp3 chiffré.

### Ce que Terraform ne fait pas ici

Terraform ne copie pas le build Angular dans `/var/www/p5` et n'installe pas la configuration NGINX du projet.

Cette responsabilité appartient à Ansible.

### Ansible : la configuration

Une fois l'EC2 disponible :

```text
outputs Terraform
       ↓
inventaire Ansible
       ↓
SSH / Ansible ping
       ↓
deploy.yml
       ↓
NGINX + Angular
```

Le playbook :

- installe NGINX et `curl` ;
- crée `appuser` et `appgroup` ;
- crée `/var/www/p5` ;
- copie l'artefact Angular ;
- installe la configuration NGINX ;
- vérifie `nginx -t` ;
- active et démarre le service.

### Pourquoi rejouer Ansible ?

Le premier passage doit modifier une machine neuve.

Le second répond à :

> « Si la cible est déjà conforme, Ansible sait-il ne rien refaire inutilement ? »

Résultat attendu :

```text
changed=0
unreachable=0
failed=0
```

C'est la preuve d'idempotence demandée par le projet.

### Pourquoi Angular existe-t-il dans un projet orienté infrastructure ?

L'application n'est pas le but métier du P5. Elle fournit une **charge applicative réelle et compilable** permettant de démontrer :

```text
sources Angular
→ build
→ artefact
→ Ansible
→ EC2
→ NGINX
→ HTTP
```

Il n'y a ni backend métier ni base de données dans cette application.

### Pourquoi générer du trafic ?

L'exercice 2 a besoin de logs HTTP réels.

Après le déploiement, le moteur génère donc du trafic puis collecte :

```text
/var/log/nginx/access.log
```

Ce fichier devient une source de données pour OpenSearch.

## Avant de considérer l'exercice 1 terminé

Vous devez pouvoir expliquer :

- ce que Terraform a créé ;
- ce qu'Ansible a configuré ;
- pourquoi le second passage doit être à `changed=0` ;
- comment le navigateur atteint NGINX ;
- pourquoi le `access.log` est utile à l'exercice 2.

Guide détaillé : [`exercices/01-terraform-ansible.md`](exercices/01-terraform-ansible.md).

## Étape 4 — Exercice 2 : passer du log brut à l'information

Un log NGINX brut ressemble à une suite de lignes techniques. Pour construire un dashboard, il faut transformer ces lignes en champs exploitables.

Le parcours est :

```text
ligne NGINX
    ↓
parsing
    ↓
typage des champs
    ↓
Bulk API
    ↓
index OpenSearch
    ↓
agrégations
    ↓
visualisations
```

### Pourquoi Amazon OpenSearch ?

La consigne pédagogique peut utiliser le vocabulaire ELK/Kibana. Le mode Cloud choisi dans ce dépôt utilise :

```text
Amazon OpenSearch
+ OpenSearch Dashboards
```

Le projet ne prétend donc pas déployer un cluster Elasticsearch/Kibana qu'il ne contient pas réellement.

### Pourquoi un sample ET un log réel ?

Le **sample versionné** permet :

- des tests reproductibles ;
- une CI qui n'a pas besoin d'une EC2 réelle ;
- un format connu pour vérifier le parser.

Le **log réel de l'exercice 1** permet de démontrer :

- que le pipeline traite aussi l'activité de l'application réellement déployée.

Les deux sources ont donc des rôles différents.

### Pourquoi le mapping est-il important ?

Une visualisation ne travaille pas seulement avec du texte.

Exemple :

```text
bytes_sent
```

doit être numérique pour calculer une somme.

Un champ mal typé peut exister dans l'index tout en restant inutilisable pour la métrique demandée.

### Les trois visualisations attendues

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 heures ;
3. top 5 de `url_path` par tranches de 12 heures.

Puis les trois sont regroupées dans un dashboard.

### Pourquoi le dashboard reste-t-il manuel ?

Le dépôt peut vérifier les données et les agrégations automatiquement. Mais l'objectif pédagogique demande également de construire et de lire une représentation visuelle réelle.

Le checkpoint humain garantit qu'une automatisation ne déclare pas :

```text
« dashboard validé »
```

alors que personne ne l'a réellement vérifié.

Même `--yes` ne remplace pas cette étape.

## Avant de considérer l'exercice 2 terminé

Vous devez pouvoir expliquer :

- la différence entre sample et log réel ;
- comment une ligne NGINX devient un document ;
- pourquoi le mapping influence les graphiques ;
- ce que mesure chaque visualisation ;
- pourquoi quatre captures sont nécessaires.

Guide détaillé : [`exercices/02-opensearch.md`](exercices/02-opensearch.md).

## Étape 5 — Exercice 3 : continuer à servir pendant une panne

L'architecture est :

```text
            client
              │
              ▼
           HAProxy
           /     \
          /       \
     backend 1  backend 2
     Docker     Docker
     nginx hello nginx hello
```

### Quelle infrastructure est réutilisée ?

L'exercice 3 ne crée pas un nouveau VPC isolé.

Terraform recherche le VPC et les subnets publics de l'exercice 1 grâce à leurs tags.

Cela explique une dépendance importante :

```text
Exercice 1 ──► Exercice 3
```

### Round-robin

HAProxy utilise :

```text
balance roundrobin
```

Les requêtes sont réparties entre les backends disponibles.

### Health checks

HAProxy vérifie régulièrement que chaque backend répond correctement.

Comportement recherché :

```text
AVANT PANNE
backend 1 + backend 2

PENDANT PANNE
backend défaillant retiré
service toujours disponible via l'autre backend

APRÈS RESTAURATION
backend restauré réintégré
```

### Pourquoi une vraie panne contrôlée ?

Une configuration syntaxiquement valide ne prouve pas la résilience.

L'exercice cherche à observer un comportement :

> le service reste-t-il disponible lorsqu'un backend n'est plus sain ?

Le script de failover doit ensuite restaurer le backend afin de ne pas laisser volontairement le lab dans un état dégradé.

## Avant de considérer l'exercice 3 terminé

Vous devez pouvoir expliquer :

- pourquoi HAProxy existe ;
- comment le round-robin répartit le trafic ;
- comment un health check retire un backend ;
- pourquoi le service continue pendant la panne ;
- comment le backend revient dans le pool.

Guide détaillé : [`exercices/03-haproxy.md`](exercices/03-haproxy.md).

## Étape 6 — Comprendre les dépendances entre exercices

### Exercice 1 → Exercice 2

```text
NGINX access.log réel
→ pipeline de parsing
→ OpenSearch
```

L'exercice 2 possède un sample reproductible, mais la preuve réelle d'observabilité peut utiliser le log collecté sur l'EC2 de l'exercice 1.

### Exercice 1 → Exercice 3

```text
VPC + subnets de l'exercice 1
→ retrouvés par tags
→ infrastructure de l'exercice 3
```

Conséquence :

> ne pas détruire l'exercice 1 tant que l'exercice 3 doit encore être créé ou testé.

## Étape 7 — Comprendre les preuves

Un fichier `.tf` prouve que du code Terraform existe. Il ne prouve pas qu'AWS a réellement créé la ressource.

Même logique pour Ansible, OpenSearch et HAProxy.

Une preuve utile répond à :

```text
Quelle action a été exécutée ?
Quel résultat a été observé ?
Pourquoi ce résultat valide-t-il le besoin ?
```

Le moteur conserve notamment des éléments sous :

```text
logs/<UTC>/
proofs/runtime/
```

Ces traces sont privées par défaut. Les livrables sélectionnent ensuite les éléments nécessaires.

## Étape 8 — Comprendre la différence entre code, CI et preuve AWS

Trois niveaux existent :

```text
CODE
= décrit l'état et les opérations voulues

CI
= vérifie le dépôt dans un environnement de test

PREUVE AWS
= montre le comportement réellement observé dans le lab
```

La CI peut vérifier notamment :

- syntaxe Bash ;
- ShellCheck ;
- Terraform `fmt` et `validate` ;
- Ansible syntax-check ;
- lint, typecheck, tests et build Angular ;
- NGINX ;
- OpenSearch local éphémère ;
- HAProxy dans un environnement de test ;
- contrat WSL2 ;
- non-régression et sécurité.

Elle ne peut pas prouver à votre place :

- qu'une EC2 a réellement été créée dans votre compte AWS ;
- que votre dashboard OpenSearch Dashboards existe ;
- que votre panne réelle a été observée ;
- que vos captures sont prêtes pour l'évaluation.

À retenir :

```text
CI VERTE   = dépôt cohérent
PREUVE AWS = exercice réellement observé
```

## Étape 9 — Finaliser les preuves et livrables

Quand les trois exercices sont terminés :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Le verdict strict attendu lorsque les éléments requis sont présents est :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Une capture doit ensuite être relue : une preuve technique peut contenir une IP, un identifiant ou une information inutile qu'il ne faut pas forcément publier.

## Étape 10 — Nettoyer AWS

Le nettoyage fait partie du projet.

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Pourquoi cet ordre ?

Parce que l'exercice 3 dépend du réseau de l'exercice 1. Il doit donc disparaître avant son socle.

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, ne supposez pas que les coûts sont terminés.

## Les commandes essentielles à reconnaître

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh ex1
bash scripts/commands/p5.sh ex2
bash scripts/commands/p5.sh ex3
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Vous n'avez pas besoin de les mémoriser toutes avant de commencer. Vous devez surtout comprendre leur **intention** et leur **niveau de mutation**.

Référence : [`CENTRE_DE_COMMANDE.md`](CENTRE_DE_COMMANDE.md).

## Ce que vous devez savoir expliquer à la fin

### Environnement

- frontière `Windows_11_Pro_Custom` / `p5_Openclassrooms` ;
- différence WSL2 Ubuntu 26.04 / EC2 Ubuntu 24.04 ;
- pourquoi le workspace reste sur le filesystem Linux ;
- différence plateforme commune / runtime spécifique P5.

### Terraform

- rôle d'un provider ;
- rôle du state ;
- intérêt de `plan` avant `apply` ;
- notion de delta et de convergence ;
- pourquoi les outputs sont préférés aux valeurs recopiées à la main.

### Ansible et application

- différence Terraform / Ansible ;
- rôle d'un inventaire ;
- rôle d'un playbook ;
- notion d'idempotence ;
- rôle de NGINX ;
- chaîne source Angular → build → Ansible → NGINX.

### Observabilité

- chemin d'un log NGINX jusqu'à OpenSearch ;
- différence sample / log réel ;
- rôle du mapping ;
- signification des trois visualisations ;
- pourquoi le checkpoint dashboard reste humain.

### Haute disponibilité

- rôle d'un load balancer ;
- différence round-robin / health check ;
- pourquoi le service continue pendant la panne ;
- pourquoi l'exercice 3 dépend du réseau de l'exercice 1.

### Exploitation

- différence CI verte / preuve réelle ;
- importance du state pour la reprise ;
- pourquoi le nettoyage suit `3 → 2 → 1` ;
- pourquoi `NETTOYAGE AWS COMPLET` est un vrai critère de fin.

Lorsque ces notions sont claires, passer au [`RUNBOOK_EXECUTION_GUIDEE.md`](RUNBOOK_EXECUTION_GUIDEE.md).
