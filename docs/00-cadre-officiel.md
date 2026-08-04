# 00 — Cadre officiel et périmètre du P5

## Projet

Le projet dure environ 60 heures et vise quatre compétences :

1. définir et provisionner une infrastructure avec Terraform ;
2. automatiser la configuration et le déploiement avec Ansible ;
3. collecter, analyser et visualiser des logs avec ELK ou OpenSearch ;
4. améliorer disponibilité et performance avec une solution Cloud et HAProxy.

## Trois exercices, pas cinq

La navigation OpenClassrooms contient sept activités pédagogiques, mais
seulement trois d'entre elles sont des exercices :

1. **Terraform + Ansible** ;
2. **ELK / OpenSearch + dashboard** ;
3. **HAProxy + deux services applicatifs**.

Les quatre autres entrées sont une page de ressources et trois cours. Elles
préparent les exercices ; elles ne doivent pas être renommées en « exercice 4 »
ou « exercice 5 » dans le dépôt.

## Périmètre évalué

| Élément | Statut dans le P5 | Emplacement dans ce dépôt |
| --- | --- | --- |
| Terraform | Obligatoire pour l'exercice 1 ; utilisé aussi pour les options Cloud | `terraform/` |
| Ansible et `deploy.yml` | Obligatoire pour l'exercice 1 | `ansible/` |
| Application Angular derrière NGINX | Résultat attendu de l'exercice 1 | `ansible/files/angular-app/` |
| Amazon OpenSearch | Mode Cloud AWS retenu pour l'exercice 2 | `terraform/exercice-2/` |
| Trois visualisations Kibana | Obligatoires | `docs/exercices/02-elk-opensearch.md` |
| HAProxy + deux `nginxdemos/hello` | Obligatoires pour l'exercice 3 | `terraform/exercice-3/` |
| Health checks et simulation de panne | Obligatoires | Exercice 3 et preuves associées |
| Kubernetes, Helm, Prometheus, Grafana, Vault | Hors périmètre de ce projet | Retirés du dépôt |
| GitHub Actions comme exercice autonome | Hors périmètre | La CI reste un contrôle du dépôt, pas un exercice P5 |

## Choix Local ou Cloud

Les consignes proposent plusieurs modes :

- exercice 1 : Docker ou AWS ;
- exercice 2 : Docker Compose local ou Amazon OpenSearch ;
- exercice 3 : Docker Compose local ou EC2 sur AWS.

### Choix retenu pour ce projet

La réalisation validée utilise **AWS pour les trois exercices** :

1. exercice 1 : VPC, sous-réseaux et instance EC2 provisionnés avec Terraform,
   puis configuration avec Ansible ;
2. exercice 2 : domaine Amazon OpenSearch et OpenSearch Dashboards ;
3. exercice 3 : une instance EC2 HAProxy et deux instances EC2 exécutant
   `nginxdemos/hello`.

Les options locales sont rappelées uniquement pour rester fidèle aux consignes.
Elles ne sont ni implémentées ni maintenues comme un second parcours dans ce
dépôt. Un choix technique du dépôt n'est pas une nouvelle consigne.

## Incohérences présentes dans les sources

Les documents fournis comportent quelques formulations contradictoires :

- la page des livrables parle d'un dépôt GitLab, tandis que l'exercice 1 demande
  un lien vers un dépôt GitHub ;
- une page mentionne `t3.micro`, puis le résultat attendu mentionne
  `t2.micro` ;
- le récapitulatif du troisième livrable parle de « pipelines Cloud », alors
  que l'exercice détaillé demande explicitement le fichier `haproxy.cfg`.

Le wiki retient les instructions détaillées de chaque exercice et signale ces
écarts. La consigne visible sur la plateforme au moment de la remise et la
validation du mentor restent prioritaires.
