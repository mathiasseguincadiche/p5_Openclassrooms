# 00 — Cadre officiel et périmètre du P5

## Pourquoi ce document existe

Avant de parler de Terraform, Ansible ou AWS, il faut séparer trois notions :

1. **ce que demande OpenClassrooms** ;
2. **les options proposées dans les consignes** ;
3. **le choix d'implémentation de ce dépôt**.

Cette distinction évite de transformer une décision technique personnelle en nouvelle consigne pédagogique.

## Contexte de formation

Ce projet appartient au parcours **Expert DevOps OpenClassrooms**. Il vise à manipuler plusieurs responsabilités centrales d'un ingénieur DevOps :

- décrire et provisionner une infrastructure par le code ;
- automatiser la configuration et le déploiement ;
- collecter et exploiter des logs ;
- améliorer la disponibilité d'un service ;
- produire des preuves techniques compréhensibles ;
- nettoyer les ressources Cloud à la fin du lab.

Le projet est construit autour de **trois exercices évalués**.

## Exercice 1 — Infrastructure as Code et Ansible

### Besoin pédagogique

La première partie demande de construire une infrastructure avec Terraform, puis d'utiliser Ansible pour configurer une cible et y déployer une application Angular derrière NGINX.

Les notions fondamentales sont :

```text
Terraform init
      ↓
Terraform plan
      ↓
lecture du delta
      ↓
Terraform apply
      ↓
serveur cible
      ↓
Ansible inventory + ping
      ↓
deploy.yml
      ↓
NGINX + Angular
```

### Options proposées par OpenClassrooms

Les consignes permettent une cible locale basée sur Docker ou une cible Cloud AWS.

### Choix de ce dépôt

Ce dépôt retient **AWS** :

- Terraform provisionne le réseau et une EC2 ;
- la cible est joignable en SSH ;
- Ansible installe NGINX et déploie le build Angular ;
- le second passage Ansible est utilisé comme preuve d'idempotence.

### Résultats attendus ici

Le projet considère l'exercice 1 validable lorsque :

- Terraform est valide ;
- le plan a été lu et appliqué sur le bon compte AWS ;
- l'EC2 est accessible ;
- `ansible ... -m ping` réussit ;
- `deploy.yml` s'exécute sans erreur ;
- Angular est servi en HTTP par NGINX ;
- le second passage Ansible obtient `changed=0`, `unreachable=0`, `failed=0` ;
- les logs NGINX réels ont été collectés.

## Exercice 2 — Logs, analyse et dashboard

### Besoin pédagogique

La consigne utilise le vocabulaire **ELK / Kibana** : charger un échantillon de logs NGINX, explorer les données et construire un dashboard.

### Options proposées par OpenClassrooms

Deux modes sont proposés :

- environnement ELK local avec Docker Compose ;
- service Cloud AWS OpenSearch.

### Choix de ce dépôt

Ce dépôt retient **Amazon OpenSearch**.

La correspondance conceptuelle est la suivante :

| Consigne | Implémentation Cloud de ce dépôt |
| --- | --- |
| Elasticsearch | Amazon OpenSearch |
| Kibana | OpenSearch Dashboards |
| index de logs NGINX | index `nginx-access-*` |
| données d'exemple | sample versionné + logs réels de l'exercice 1 |
| visualisations | visualisations construites dans OpenSearch Dashboards |

### Les trois visualisations obligatoires

Le dashboard doit montrer :

1. un diagramme **donut** de répartition des verbes/méthodes HTTP ;
2. la quantité cumulée de données envoyées par le serveur par tranches de **12 heures** ;
3. le **top 5** des requêtes/URL par tranches de **12 heures**.

Pour la preuve, il faut conserver :

- une capture lisible de chaque visualisation ;
- une capture du dashboard complet.

Le dépôt automatise le traitement technique des données, mais la construction et la validation visuelle du dashboard restent un checkpoint humain.

## Exercice 3 — HAProxy et disponibilité

### Besoin pédagogique

L'exercice introduit le rôle d'un load-balancer et demande une architecture composée de :

- un serveur HAProxy ;
- deux instances du même service applicatif `nginxdemos/hello`.

Le comportement attendu est :

1. répartir alternativement les requêtes entre les deux backends ;
2. surveiller leur état de santé ;
3. retirer automatiquement un backend défaillant ;
4. continuer à servir les requêtes via l'autre backend ;
5. réintégrer automatiquement le backend restauré.

### Options proposées par OpenClassrooms

Le lab peut être réalisé localement avec Docker Compose ou dans le Cloud.

### Choix de ce dépôt

Ce dépôt retient **AWS EC2** :

- une EC2 HAProxy ;
- deux EC2 backend ;
- `nginxdemos/hello` exécuté dans Docker sur les backends ;
- des Security Groups distincts ;
- health checks HTTP HAProxy ;
- test réel de panne et de reprise.

Le livrable technique central est une configuration HAProxy lisible accompagnée des preuves de round-robin, panne, continuité et réintégration.

## Pourquoi les trois exercices sont liés dans ce dépôt

OpenClassrooms présente les exercices comme des activités successives. L'implémentation de ce dépôt ajoute une réutilisation technique contrôlée afin d'éviter de créer inutilement plusieurs réseaux AWS :

```text
EXERCICE 1
VPC + subnets + EC2 Angular
   │             │
   │             └── access.log NGINX ──► EXERCICE 2
   │                                      OpenSearch
   │
   └── VPC + subnets + clé ─────────────► EXERCICE 3
                                          HAProxy + backends
```

Cette décision a une conséquence opérationnelle majeure : **l'exercice 1 ne doit pas être détruit avant l'exercice 3**.

L'ordre de fermeture du lab est donc :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

## Incohérences dans les formulations de la plateforme

Certaines pages OpenClassrooms ne sont pas parfaitement homogènes entre elles. Deux exemples importants :

- le type d'instance EC2 est présenté avec des valeurs différentes selon les sections de l'exercice 1 ;
- la page récapitulative des livrables utilise pour l'exercice 3 une formulation générique qui ne correspond pas aussi précisément que le détail de l'exercice, lequel demande explicitement le travail HAProxy et son fichier de configuration.

Le dépôt applique donc la règle suivante :

1. suivre le besoin détaillé de l'exercice ;
2. rendre les paramètres techniques configurables lorsque la consigne n'impose pas une valeur fiable et unique ;
3. conserver la sécurité et la maîtrise des coûts ;
4. vérifier la consigne visible sur la plateforme au moment de la remise ;
5. faire valider toute ambiguïté de livraison par le mentor ou l'évaluateur.

C'est pour cette raison que le type EC2 n'est pas considéré comme une vérité codée en dur dans la documentation : il provient de la configuration locale et des variables Terraform.

## Environnement d'exécution retenu

Les commandes P5 sont exécutées dans la distribution WSL2 `Ubuntu`, Ubuntu 26.04 LTS en CLI. Cette plateforme est fournie par le dépôt séparé [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

Cette décision d'environnement **n'ajoute pas un quatrième exercice**. Elle ne change pas le périmètre pédagogique : elle fournit seulement un runtime Linux isolé et reproductible pour exécuter les trois exercices AWS.

La préparation logicielle strictement nécessaire au P5 reste gérée par `p5_Openclassrooms` à l'intérieur de cette distribution WSL2.

## Ce que le P5 n'évalue pas

Les éléments suivants ne font pas partie des trois exercices :

- le Windows 11 Pro ;
- WSL2 ;
- la création, le réseau, le stockage ou le backup de `Ubuntu` sous WSL2 ;
- Kubernetes ;
- Helm ;
- Prometheus ;
- Grafana ;
- Vault ;
- GitHub Actions comme exercice autonome.

GitHub Actions protège le dépôt. Windows 11 Pro et WSL2 hébergent le runtime. Aucun de ces éléments ne devient un livrable pédagogique du P5.

## Réalisation de référence du dépôt

La réalisation retenue est donc :

```text
P5 OpenClassrooms
│
├── Exercice 1
│   └── AWS + Terraform + Ansible + NGINX + Angular
│
├── Exercice 2
│   └── Amazon OpenSearch + OpenSearch Dashboards
│
└── Exercice 3
    └── AWS EC2 + HAProxy + 2 × nginxdemos/hello
```

Pour savoir **où** chaque besoin est implémenté et **quelle preuve** le valide, poursuivre avec [`02-correspondance-consignes-depot.md`](02-correspondance-consignes-depot.md).
