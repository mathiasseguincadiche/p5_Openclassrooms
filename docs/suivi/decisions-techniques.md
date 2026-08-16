# Décisions techniques du P5

> Document de gouvernance. Il enregistre les choix de l'implémentation actuelle sans constituer un runbook.

## Périmètre

Le projet évalué est **AWS**. Le P5 s'exécute dans la VM `ubuntu-devops`, Ubuntu Server 26.04 LTS en CLI. Le HOST Ubuntu, KVM/libvirt et le cycle de vie de cette VM sont fournis séparément par `mathiasseguincadiche/Ubuntu-desktops-custom`.

Le dépôt maintient exactement trois exercices :

```text
1. Terraform + Ansible
2. Amazon OpenSearch
3. HAProxy
```

## Décisions transverses

| Sujet | Choix actuel | Raison |
| --- | --- | --- |
| environnement d'exécution | VM `ubuntu-devops`, Ubuntu Server 26.04 CLI | isolation du runtime P5 et cohérence avec la plateforme Ubuntu/KVM |
| propriétaire plateforme | `Ubuntu-desktops-custom` | une seule source de vérité pour HOST, KVM/libvirt et VM |
| propriétaire runtime P5 | `p5_Openclassrooms` | conserver une préparation logicielle reproductible propre au projet |
| emplacement checkout | `~/labs/p5_Openclassrooms` dans la VM | filesystem Linux local et environnement CLI reproductible |
| région modèle | `us-east-1` | région commune au lab, configurable |
| Terraform | `>= 1.15.0, < 2.0.0` avec cible P5 1.15.8 | contrat actuel du dépôt |
| AWS provider | `~> 5.0` | plage contrôlée par les lockfiles |
| compte | `allowed_account_ids` | refuser un déploiement dans le mauvais compte |
| administration | IPv4 publique `/32` | limiter SSH et OpenSearch |
| configuration locale | `environment/aws-readiness.env` | source unique, non versionnée |
| mutation | confirmation ou `--apply` explicite selon les scripts | distinguer observation et action |
| secrets | hors Git + audit dédié | réduire le risque de fuite |

## Frontière plateforme / projet

```text
Ubuntu-desktops-custom
├── HOST Ubuntu
├── KVM/libvirt
├── réseau et stockage de virtualisation
└── cycle de vie de ubuntu-devops

p5_Openclassrooms
├── contrôle que le guest correspond au contrat P5
├── converge les dépendances P5 dans le guest
├── prépare AWS
└── exécute les trois exercices
```

Le P5 ne doit donc pas contenir de logique de provisioning KVM/libvirt. La préparation P5 peut en revanche installer ou réaligner Terraform, Ansible, Node.js, AWS CLI, Docker et les outils nécessaires **à l'intérieur de la VM**.

## Application Angular

Le dépôt contient une **application Angular** réelle dans :

```text
application/angular/
```

Chaîne :

```text
sources
  ↓
npm ci / tests / build
  ↓
artefact navigateur
  ↓
ansible/files/angular-app
  ↓
NGINX sur EC2
```

La CI reconstruit l'application et compare le build à l'artefact Ansible.

## Exercice 1

| Sujet | Choix | Raison |
| --- | --- | --- |
| cible | AWS EC2 | mode Cloud retenu |
| type par défaut | `t3.micro` | taille de lab, toujours soumise au coût/quota réel |
| OS EC2 | Ubuntu 24.04 LTS | AMI Canonical automatique |
| réseau | VPC + deux subnets publics | socle réutilisable par ex. 3 |
| IaC | Terraform | infrastructure déclarative |
| configuration | Ansible | séparation infra/configuration |
| serveur HTTP | NGINX | servir Angular et produire `access.log` |
| preuve forte | second playbook `changed=0` | idempotence |

Le VPC de l'exercice 1 reste actif jusqu'à la fin de l'exercice 3.

## Exercice 2

| Sujet | Choix | Raison |
| --- | --- | --- |
| mode | Amazon OpenSearch | option Cloud de l'exercice |
| moteur | OpenSearch 2.19 | référence actuelle du lab |
| instance | `t3.small.search` par défaut | dimension de démonstration configurable |
| stockage | 10 Gio gp3 | dataset limité |
| sécurité | HTTPS + chiffrement | éviter un domaine en clair |
| accès | SourceIp `/32` | limiter l'exposition |
| données | sample + log réel ex. 1 | reproductibilité + preuve réelle |
| dashboard | manuel | conserver la compréhension pédagogique |

Le sample reproductible contient le volume de données nécessaire aux tests automatisés. Les logs réels restent un enrichissement runtime.

## Exercice 3

| Sujet | Choix | Raison |
| --- | --- | --- |
| réseau | VPC/subnets de l'exercice 1 | éviter une architecture AWS dupliquée |
| instances | 1 HAProxy + 2 backends | topologie demandée |
| backend | `nginxdemos/hello:plain-text` dans Docker | identifier facilement le serveur répondant |
| algorithme | `roundrobin` | répartition simple et observable |
| santé | check HTTP, `fall 3`, `rise 2` | panne et réintégration démontrables |
| HTTP backend | autorisé depuis SG HAProxy uniquement | éviter le contournement public du répartiteur |
| test réel | `--apply` après prévisualisation | mutation volontaire explicite |
| restauration | mécanisme `trap` dans le script | réduire le risque de backend laissé arrêté |

## Convergence

Le projet privilégie :

```text
inspecter
→ planifier
→ appliquer uniquement un delta
→ vérifier l'absence de delta
→ tester la fonction réelle
```

Un state existant est une information à conserver, pas un obstacle à supprimer.

La même règle s'applique au runtime P5 : une dépendance déjà conforme dans `ubuntu-devops` n'est pas réinstallée inutilement.

## Preuves

Les preuves brutes sont locales à la VM :

```text
logs/<RUN_ID>/
proofs/runtime/
```

Les livrables sélectionnent des éléments relus et contextualisés.

La CI ne remplace jamais les preuves AWS réelles.

## Nettoyage

L'ordre est :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

La destruction exige une confirmation forte et l'audit final doit produire :

```text
NETTOYAGE AWS COMPLET
```

Le nettoyage P5 ne détruit pas la VM `ubuntu-devops` : son cycle de vie appartient au dépôt plateforme.

## Documentation

Les schémas sont des SVG statiques versionnés. Aucun moteur de diagramme dynamique n'est nécessaire au rendu du dépôt.

Le README racine explique le projet ; `docs/` porte le détail. Les documents de gouvernance restent séparés du parcours d'exécution afin qu'un nouveau lecteur ne doive pas connaître l'historique des refontes.
