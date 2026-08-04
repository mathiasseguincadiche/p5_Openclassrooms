# Décisions techniques du P5

## Périmètre

Le dépôt est limité aux trois exercices officiels. Les anciens exercices
Docker, GitHub Actions et Kubernetes ont été retirés.

## Mode de réalisation

Décision validée : **AWS pour les trois exercices**. Aucun parcours Docker local
parallèle n’est maintenu dans le dépôt.

| Exercice | Choix principal | Conséquence |
| --- | --- | --- |
| 1 | AWS + Terraform + Ansible | Une cible EC2, plus deux sous-réseaux réutilisables par l’exercice 3 |
| 2 | Amazon OpenSearch | Coût potentiel élevé ; destruction après les captures |
| 3 | AWS + HAProxy | Réutilisation du VPC de l’exercice 1 et création de trois instances |

## Application Angular

Le dépôt ne contient pas le projet Angular source du starter officiel. La page
`ansible/files/angular-app/index.html` est un support statique temporaire. Elle
ne doit pas être présentée comme la preuve d’une application Angular construite.

## Simplicité pédagogique

Les anciens lanceurs automatiques et le script de création du dashboard ont été
supprimés. Les commandes importantes restent visibles dans les fiches afin que
le débutant comprenne `plan`, `apply`, Ansible, les visualisations et les tests
de panne.

## Sécurité

- accès d’administration limité à `your_ip_cidr` en `/32` ;
- clés, variables locales et états exclus de Git ;
- aucun mot de passe requis dans `haproxy.cfg` ;
- plans Terraform relus avant application ;
- destruction AWS séparée, confirmée et exécutée dans l’ordre 3 → 2 → 1.
