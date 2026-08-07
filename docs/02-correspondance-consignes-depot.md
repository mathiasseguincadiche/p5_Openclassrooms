# 02 — Correspondance entre les consignes et le dépôt

Cette matrice distingue la demande OpenClassrooms, l’implémentation du dépôt et la preuve qui reste à produire. Le choix de réalisation est **AWS pour les trois exercices**.

## Exercice 1

| Consigne | Emplacement | État |
| --- | --- | --- |
| Fichiers Terraform HCL | `terraform/exercice-1/` | Présents |
| `init`, `plan`, `apply` | Fiche de l’exercice 1 | À exécuter réellement |
| Une cible AWS accessible en SSH | `terraform/exercice-1/main.tf` | Présente |
| Inventaire Ansible | `ansible/inventories/hosts_aws.example` | Exemple anonymisé |
| Playbook `deploy.yml` | `ansible/playbooks/deploy.yml` | Présent |
| Installation de NGINX | Playbook | Présente |
| Déploiement Angular | `application/angular/` et `ansible/files/angular-app/` | Sources et build réel synchronisés par la CI |
| Handler de rechargement | Playbook | Présent |
| Preuves | Gabarit du livrable 1 | À compléter après le déploiement AWS |

Les deux sous-réseaux servent aussi à l’exercice 3 ; ils ne représentent pas deux exercices ni deux cibles Ansible.

## Exercice 2

| Consigne | Emplacement | État |
| --- | --- | --- |
| Mode officiel retenu | Fiche de l’exercice 2 | **Cloud AWS** |
| Domaine Amazon OpenSearch | `terraform/exercice-2/` | Présent |
| Échantillon NGINX | `terraform/exercice-2/samples/` | Présent |
| Index `nginx-access` | Interface du service choisi | À créer réellement |
| Donut des verbes HTTP | Dashboard | À créer |
| Histogramme des octets par 12 h | Dashboard | À créer |
| Top 5 des requêtes par 12 h | Dashboard | À créer |
| Quatre captures | Gabarit du livrable 2 | À insérer |

Le dépôt ne crée pas automatiquement les visualisations : la manipulation de l’interface fait partie de l’apprentissage demandé.

## Exercice 3

| Consigne | Emplacement | État |
| --- | --- | --- |
| Deux EC2 `nginxdemos/hello` | `terraform/exercice-3/main.tf` | Présentes |
| Une EC2 HAProxy | Même fichier | Présente |
| Répartition `roundrobin` | Terraform et générateur | Présente |
| Health checks | Terraform et générateur | Présents |
| Test de panne et reprise | Fiche et gabarit du livrable 3 | À exécuter |
| `haproxy.cfg` | `scripts/tools/generer-haproxy-config.sh` | À générer ou extraire |

L’exercice 3 réutilise le VPC, les sous-réseaux et la paire de clés créés par l’exercice 1. Cette dépendance appartient à l’implémentation du dépôt.

## Éléments transverses

| Élément | Rôle | Statut |
| --- | --- | --- |
| GitHub Actions | Contrôle qualité | Pas un exercice P5 |
| Audit des secrets | Refus des données sensibles suivies par Git | Contrôle bloquant |
| Scripts Bash courts | Vérification et nettoyage | Aides facultatives |
| Journal et décisions | Traçabilité | Suivi, pas livrable principal |
| Schémas SVG | Explication visuelle | Support pédagogique |
