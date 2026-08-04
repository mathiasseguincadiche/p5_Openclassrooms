# 04 — Audit de non-régression

Cet audit compare la version précédant la simplification à la structure actuelle.
Son objectif n’est pas de restaurer tout l’ancien volume, mais de garantir
qu’aucune capacité utile au P5 n’a été perdue.

## Méthode

Chaque suppression est classée dans l’une des catégories suivantes :

1. **hors périmètre** : ne correspond pas aux trois exercices évalués ;
2. **doublon** : même information disponible ailleurs dans une forme plus claire ;
3. **automatisation opaque** : masque les commandes que l’étudiant doit apprendre ;
4. **capacité utile** : doit être conservée ou réintroduite.

## Capacités réintroduites

| Capacité utile | Régression constatée | Correction actuelle |
| --- | --- | --- |
| Préparation de la VM | ancienne phase 0 supprimée | guide Ubuntu Server 26.04 et bootstrap autonome |
| Préparation du compte AWS | identité seulement détectée | étape 0B avec compte, région, quotas, budget et collisions |
| Contrôle avant déploiement | script supprimé | `pre-deployment-check.sh` rétabli et renforcé |
| Garde-fou de compte | risque de mauvais compte Terraform | `allowed_account_ids` dans les trois modules |
| Suivi des coûts | aucune condition préalable | budget volontaire et alertes 50 %, 80 % et 100 % |
| Nettoyage vérifiable | contrôle manuel uniquement | audit AWS non destructif après `destroy` |
| Chaîne de l’application | simple page témoin sans sources structurées | `application/angular/` et build vers Ansible |
| Diagnostic du lab | contrôle devenu trop minimal | vérification OS, Docker, AWS, SSH, Terraform et structure |
| Compréhension de l’arborescence | fichiers techniques dispersés | flux source → build → Ansible → EC2 documenté |
| Protection CI | aucune vérification de l’étape 0 | contrôles dédiés ajoutés à la CI |
| Schémas | SVG trop larges et chargés | schémas compacts, sans filtre ni effet décoratif |

## Suppressions maintenues volontairement

| Élément ancien | Décision | Justification |
| --- | --- | --- |
| Exercices génériques 4 et 5 | supprimés | le P5 évalué contient trois exercices |
| Templates Kubernetes | supprimés | technologie hors périmètre du projet |
| Prometheus, Grafana et Vault | supprimés | ne participent pas aux livrables demandés |
| Déploiement intégral en un clic | supprimé | empêche la lecture des plans et la compréhension |
| Automatisation du dashboard | supprimée | les visualisations doivent être construites et comprises |
| Bibliothèques Bash volumineuses | remplacées | scripts autonomes plus faciles à auditer |

## Contrat de non-régression

Une évolution ne doit pas être fusionnée si elle retire ou casse :

- l’installation et la validation de la VM de lab ;
- l’étape 0B, son fichier d’exemple et le verdict `GO AWS` ;
- le verrouillage du compte et les tags communs Terraform ;
- la vérification des quotas, d’OpenSearch et du budget ;
- le contrôle des ressources AWS restantes ;
- les trois modules Terraform ;
- la source ou la préparation de l’application Angular ;
- le playbook et la configuration NGINX ;
- l’échantillon de logs et la procédure OpenSearch ;
- la configuration HAProxy et les tests de panne ;
- les livrables, les preuves ou le nettoyage AWS ;
- les contrôles de sécurité relatifs aux secrets et aux états Terraform.

## Limites honnêtes

Le dépôt ne peut pas contenir le véritable starter Angular tant que ses sources
n’ont pas été fournies ou que leur redistribution n’est pas autorisée. Cette
absence est visible, documentée et contrôlée comme avertissement.

Le dépôt ne peut pas prouver seul l’état du MFA root, l’absence de clés root,
la validité du moyen de paiement ou la réception d’un courriel de budget. Ces
points restent des confirmations manuelles obligatoires de l’étape 0B.
