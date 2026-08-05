# Décisions techniques du P5

Ce document enregistre les choix qui structurent l'implémentation actuelle. Il
évite qu'une future simplification remplace une décision validée par une
approximation ou une ancienne hypothèse.

## Périmètre

Le dépôt couvre exactement les trois exercices officiels du P5. Le parcours
retenu est **100 % AWS** : la VM Ubuntu Server sert de poste DevOps et les
infrastructures évaluées sont créées dans AWS.

Les exemples Docker, Kubernetes et GitHub Actions génériques ne font pas partie
du parcours principal. Docker reste néanmoins utilisé sur la VM et dans
l'exercice HAProxy lorsque cette utilisation répond directement au besoin.

## Socle commun

| Décision | Choix actuel | Justification |
| --- | --- | --- |
| Poste DevOps | Ubuntu Server 26.04 | environnement CLI reproductible et proche des usages OPS |
| Région AWS | `us-east-1` | région commune aux trois modules et aux contrôles de préparation |
| Terraform | `>= 1.15.0, < 2.0.0` | version moderne, contrôlée par la CI |
| Provider AWS | `~> 5.0` | compatibilité fixée dans chaque module |
| Compte AWS | `allowed_account_ids` obligatoire | empêche un déploiement dans le mauvais compte |
| Accès d'administration | IPv4 réelle en `/32` | évite d'ouvrir SSH ou OpenSearch au monde entier |
| Tags | projet, gestionnaire, objectif et exercice | facilite l'inventaire, le nettoyage et le suivi des coûts |
| Mutation | option `--apply` ou confirmation explicite | sépare l'aperçu non destructif de l'action réelle |

## Application Angular

Le dépôt contient un **véritable projet Angular compilable** dans
`application/angular/`, avec `package-lock.json` et Node.js 22.22.0.

```text
sources Angular
    → npm ci
    → npm run build
    → artefact navigateur
    → ansible/files/angular-app/
    → NGINX sur EC2
```

La CI reconstruit l'application et compare exactement le build à l'artefact
versionné pour Ansible. Une page HTML témoin ne peut donc pas remplacer
silencieusement l'application réelle.

## Exercice 1 — Terraform, Ansible et NGINX

| Décision | Choix actuel | Justification |
| --- | --- | --- |
| Instance | `t3.micro` par défaut | dimension adaptée à une démonstration, coût à vérifier avant déploiement |
| Système EC2 | Ubuntu Server 24.04 LTS | AMI Canonical sélectionnée automatiquement |
| Provisionnement | Terraform | réseau, sécurité, clé SSH et EC2 déclaratifs |
| Configuration | Ansible | installation NGINX et copie idempotente du build |
| Serveur web | NGINX sur le port 80 | service simple à contrôler par HTTP et compatible SPA |
| Preuve | HTTP, bundle JavaScript et fallback SPA | démontre que le véritable build est servi |

Le module crée le réseau qui sera réutilisé par l'exercice 3. Il ne doit donc
pas être détruit avant la fin du test HAProxy.

## Exercice 2 — Amazon OpenSearch

| Décision | Choix actuel | Justification |
| --- | --- | --- |
| Moteur | OpenSearch 2.19 | version déclarée explicitement dans Terraform |
| Nœud | `t3.small.search`, un exemplaire | taille pédagogique minimale, service payant à surveiller |
| Stockage | 10 Gio `gp3` | volume limité pour le jeu de données de démonstration |
| Transport | HTTPS et TLS 1.2 minimum | évite un endpoint en clair |
| Chiffrement | au repos et entre les nœuds | protection activée malgré le caractère pédagogique |
| Accès | politique IP limitée à l'adresse `/32` | réduit l'exposition du domaine |
| Données | mapping strict et 64 événements | garantit les trois agrégations demandées |
| Dashboard | construction manuelle | la compréhension des champs et visualisations fait partie de l'évaluation |

L'import réel exige `--apply`. Le mode par défaut prépare et montre les données
sans les envoyer au domaine.

## Exercice 3 — HAProxy et reprise

| Décision | Choix actuel | Justification |
| --- | --- | --- |
| Réseau | VPC et sous-réseaux de l'exercice 1 | évite une seconde architecture inutile |
| Instances | trois `t3.micro` | un HAProxy et deux backends distincts |
| Backends | deux conteneurs `nginxdemos/hello` | le nom de serveur rend l'alternance observable |
| Algorithme | `roundrobin` | comportement simple à démontrer et à vérifier |
| Santé | requête HTTP avec seuils `fall` et `rise` | retrait puis réintégration automatiques d'un backend |
| Exposition | backends HTTP accessibles uniquement depuis HAProxy | limite l'accès direct au service interne |
| Test destructif | option `--apply` et restauration par `trap` | évite une panne permanente en cas d'interruption |

## Preuves et livrables

Les sorties et captures réelles sont placées dans `proofs/runtime/`, ignoré par
Git. Les trois livrables restent dans `docs/livrables/` et le contrôle strict
échoue tant qu'un marqueur de preuve manquante subsiste.

Le dépôt aide à collecter et vérifier les preuves, mais n'en fabrique aucune.

## Nettoyage et coûts

La destruction suit obligatoirement l'ordre **3 → 2 → 1**, car l'exercice 3
réutilise le réseau de l'exercice 1. Le script exige le mot `DETRUIRE`, puis
`check-aws-cleanup.sh` recherche les ressources P5 restantes.

Le budget est conservé après la démonstration pour détecter un oubli. Aucun type
d'instance ou service ne doit être supposé gratuit : le prix et les quotas du
compte doivent être vérifiés avant chaque création.

## Documentation et schémas

Mermaid n'est pas utilisé. Les schémas sont des SVG statiques autonomes, légers
et accessibles. Ils partagent une typographie, une palette sémantique et des
règles de contraste, mais chaque vue possède une composition adaptée :

- carte du parcours pour la vue globale ;
- fondations et porte de validation pour l'étape 0 ;
- couloirs pour le déploiement ;
- pipeline pour les données OpenSearch ;
- topologie et chronologie pour HAProxy ;
- procédure de sortie pour la finalisation.

La cohérence ne doit plus être confondue avec la duplication d'un gabarit.
