# 04 — Audit de non-régression

> Document de gouvernance. Pour réaliser le lab, suivre `RUNBOOK_EXECUTION_GUIDEE.md`.

## Objectif

Le dépôt doit pouvoir évoluer sans perdre une capacité nécessaire au P5.

Une simplification documentaire n'est acceptable que si elle ne supprime pas :

- un exercice ;
- une vérification ;
- un garde-fou ;
- une preuve ;
- une dépendance ;
- une procédure de nettoyage.

## Contrat exécutable

La vérification centrale est :

```bash
python3 scripts/tools/audit_non_regression.py
```

Elle est également exécutée dans GitHub Actions.

## Référence technique de comparaison

Le script conserve comme baseline historique interne le commit :

```text
2e0600fbf573815077cf541e30a0d9d01591a180
```

Cette référence existe uniquement pour le **contrat de non-régression**. Elle n'est pas une documentation à suivre et ne définit pas l'architecture actuelle.

L'architecture courante est décrite par :

- `README.md` ;
- `docs/README.md` ;
- `docs/architecture-et-flux.md` ;
- le code actuel de `main` ou de la branche contrôlée.

## 1. Capacités obligatoires

L'audit exige des fichiers représentant :

- pilotage et documentation ;
- préparation AWS ;
- Angular et Ansible ;
- OpenSearch ;
- HAProxy ;
- preuves et nettoyage ;
- validation continue.

Une refonte peut modifier la rédaction ou l'organisation, mais pas retirer silencieusement ces capacités.

## 2. Trois exercices

Le contrat vérifie :

```text
3 guides sous docs/exercices/
3 modules sous terraform/
```

Une quatrième technologie ne doit pas être présentée comme exercice évalué.

## 3. Aucun Mermaid

La documentation utilise des SVG versionnés.

Le contrat refuse les blocs :

```text
```mermaid
```

Cette règle garantit un rendu stable et indépendant d'un moteur Mermaid.

## 4. Application Angular réelle

L'audit vérifie :

- présence de `@angular/core` ;
- script de build ;
- sources Angular ;
- artefact Ansible avec `<app-root` ;
- bundle JavaScript ;
- chemins corrects dans le playbook.

Le but est d'empêcher le remplacement silencieux de l'application par une page témoin sans rapport avec les sources.

## 5. Garde-fous Terraform

Pour les trois modules :

- compte AWS attendu ;
- `allowed_account_ids` ;
- tags communs ;
- IP `/32` dans le contrat de variables.

Pour les EC2 :

- IMDSv2 ;
- volume racine chiffré.

Pour OpenSearch :

- moteur attendu ;
- chiffrement ;
- HTTPS.

Pour HAProxy :

- deux backends ;
- round-robin ;
- réutilisation du VPC.

## 6. Contrôles destructifs

L'audit vérifie la présence de garde-fous autour de :

- destruction AWS ;
- import OpenSearch ;
- budget ;
- test de failover.

Une commande mutatrice doit rester clairement distincte de son mode de contrôle/prévisualisation lorsque ce mécanisme existe.

## 7. Fichiers sensibles interdits

Le contrat refuse notamment :

```text
terraform.tfstate
terraform.tfstate.*
terraform.tfvars réels
environment/aws-readiness.env
ansible/inventories/hosts_aws
```

Le contrôle des secrets complète cette vérification.

## 8. Schémas

Six SVG sont attendus exactement :

```text
docs/schemas/vue-ensemble.svg
docs/schemas/etape-0.svg
docs/schemas/exercice-1.svg
docs/schemas/exercice-2.svg
docs/schemas/exercice-3.svg
docs/schemas/finalisation/finalisation.svg
```

Le contrat vérifie notamment :

- taille ;
- dimensions ;
- accessibilité `title`/`desc` ;
- absence de scripts/images externes ;
- lisibilité Markdown ;
- diversité des compositions ;
- intégration au README racine.

## 9. Documentation

Le contrat protège plusieurs marqueurs essentiels, notamment :

```text
GO TERRAFORM
NETTOYAGE AWS COMPLET
```

Ces marqueurs servent au parcours et aux contrôles automatisés.

La documentation ne doit pas réintroduire des affirmations contredisant les sources Angular réelles ou le périmètre AWS actuel.

## 10. Tests spécialisés

En complément de l'audit Python, les workflows exécutent :

- tests du centre de commande ;
- contrat d'authentification AWS ;
- contrat de convergence ;
- contrat des informations requises ;
- contrat des preuves ;
- tests NGINX/Angular ;
- tests OpenSearch local ;
- tests HAProxy ;
- Terraform validate ;
- Ansible syntax-check ;
- Markdown et YAML.

## 11. Ce que la non-régression ne peut pas prouver

Même une CI entièrement verte ne certifie pas :

- un `terraform apply` réel sur le compte de l'étudiant ;
- l'état actuel du moyen de paiement ou des quotas ;
- la réception d'une alerte budget ;
- l'existence des captures OpenSearch ;
- la qualité visuelle du dashboard ;
- la réussite du failover sur le compte AWS réel ;
- l'absence de toute ressource AWS hors du périmètre inspecté.

Ces éléments appartiennent au runtime et aux preuves humaines.

## 12. Critère d'acceptation d'une refonte

Une refonte documentaire ou technique est acceptable si :

```text
les exigences sont plus claires
+ le code reste exact
+ les preuves restent réalisables
+ les garde-fous restent actifs
+ la CI reste verte
```

L'audit est donc un filet de sécurité, pas un substitut à la compréhension du projet.
