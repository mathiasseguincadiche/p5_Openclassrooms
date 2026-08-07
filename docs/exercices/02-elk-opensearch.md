# Exercice 2 — Logs NGINX et Amazon OpenSearch

Cette fiche décrit l’implémentation Cloud retenue pour l’exercice 2 : Amazon
OpenSearch Service et OpenSearch Dashboards.

![Flux de l’exercice 2](../schemas/exercice-2.svg)

## Objectif

Importer des événements NGINX structurés dans OpenSearch, vérifier leurs champs
et leurs agrégations, puis construire manuellement un dashboard comprenant les
trois visualisations demandées.

## Résultat final attendu

```text
logs NGINX
   ↓
conversion Bulk NDJSON
   ↓
nginx-access-*
   ↓
validation des mappings et agrégations
   ↓
3 visualisations + dashboard complet
```

Verdict technique attendu avant le dashboard :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

## Option retenue

Le dépôt utilise **Amazon OpenSearch Service**.

Le terme « Kibana » présent dans certaines consignes correspond ici à
**OpenSearch Dashboards**.

Le mode Docker Compose local sert uniquement aux tests du dépôt et n’est pas un
second parcours de remise.

## Prérequis

- étape 0A validée ;
- AWS Ready validé ;
- `environment/aws-readiness.env` à jour ;
- tfvars synchronisés ;
- budget actif ;
- adresse publique `/32` actuelle ;
- aucun domaine OpenSearch P5 conflictuel.

Contrôles :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/pre-deployment-check.sh --stage exercice-2
```

Si votre IP publique a changé, modifiez **uniquement**
`environment/aws-readiness.env`, puis :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

## Ce que Terraform crée

`terraform/exercice-2/` crée un domaine Amazon OpenSearch avec :

| Paramètre | Référence |
| --- | --- |
| Domaine | `p5-opensearch` par défaut |
| Moteur | `OpenSearch_2.19` |
| Instance | `t3.small.search` |
| Nombre de nœuds | 1 |
| Volume | 10 Gio `gp3` |
| HTTPS | obligatoire |
| TLS | 1.2 minimum |
| Chiffrement au repos | activé |
| Chiffrement inter-nœuds | activé |
| Accès | limité à l’IPv4 `/32` du lab |

Ces valeurs sont configurables via `aws-readiness.env` puis synchronisées vers
le tfvars de l’exercice 2.

## Fichiers concernés

```text
terraform/exercice-2/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── opensearch/
│   ├── README.md
│   └── index-template.json
└── samples/
    └── nginx-access.log.sample

scripts/
├── commands/import-opensearch-data.sh
├── commands/verify-opensearch-data.sh
├── commands/generate-nginx-traffic.sh
├── commands/collect-nginx-access-log.sh
└── tools/convert-nginx-logs.py
```

## Deux sources de données possibles

### Échantillon versionné

```text
terraform/exercice-2/samples/nginx-access.log.sample
```

Il contient 64 événements répartis de manière à rendre les trois agrégations
démontrables.

### Logs réels de l’exercice 1

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh
```

Le log collecté est écrit localement sous `proofs/runtime/exercice-2/`.

Les deux sources sont utiles : les logs réels prouvent la chaîne bout en bout,
tandis que l’échantillon garantit une distribution temporelle adaptée aux
visualisations de 12 heures.

## Étape 1 — Initialiser et valider Terraform

```bash
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 fmt -check
terraform -chdir=terraform/exercice-2 validate
```

## Étape 2 — Produire et relire le plan

```bash
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
```

Vérifier :

- compte et région ;
- nom du domaine ;
- moteur et type d’instance ;
- volume ;
- politique IP `/32` ;
- HTTPS/TLS ;
- chiffrement ;
- coût potentiel du domaine.

## Étape 3 — Appliquer

```bash
terraform -chdir=terraform/exercice-2 apply tfplan
terraform -chdir=terraform/exercice-2 output
```

Outputs :

```text
opensearch_domain_name
opensearch_endpoint
opensearch_arn
opensearch_dashboards_endpoint
```

Attendez que le domaine soit complètement actif avant l’import.

## Étape 4 — Prévisualiser la conversion

Avec l’échantillon :

```bash
./scripts/commands/import-opensearch-data.sh
```

Avec un log réel :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

Sans `--apply`, aucune donnée n’est envoyée à OpenSearch.

Le script :

1. valide le fichier NGINX ;
2. le convertit en Bulk NDJSON ;
3. compte les documents ;
4. affiche le résumé ;
5. quitte sans contacter OpenSearch.

## Étape 5 — Importer réellement

Échantillon :

```bash
./scripts/commands/import-opensearch-data.sh --apply
```

Log réel :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log --apply
```

Le script :

- récupère `opensearch_endpoint` si aucun endpoint n’est fourni ;
- crée ou met à jour le template `p5-nginx-access` ;
- importe dans `nginx-access-*` ;
- refuse toute erreur Bulk ;
- compte les documents ;
- enregistre les réponses sous `proofs/runtime/exercice-2/`.

Verdict d’import attendu :

```text
IMPORT OPENSEARCH RÉUSSI
```

## Étape 6 — Vérifier mappings et agrégations

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le script est non destructif et vérifie :

- `@timestamp` ;
- `http_method` ;
- `url_path` ;
- `bytes_sent` ;
- au moins 64 documents par défaut ;
- au moins trois méthodes HTTP ;
- au moins quatre buckets temporels de 12 h ;
- au moins cinq chemins distincts ;
- les agrégations utiles au dashboard.

Verdict :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

## Étape 7 — Créer le data view

Dans OpenSearch Dashboards :

- pattern : `nginx-access-*` ;
- champ temporel : `@timestamp`.

Ouvrir Discover et vérifier que les champs sont correctement typés.

## Étape 8 — Visualisation 1 : donut des verbes HTTP

Créer une visualisation avec :

- type : donut/pie ;
- agrégation : Terms ;
- champ : `http_method`.

La répartition des méthodes présentes doit être lisible.

## Étape 9 — Visualisation 2 : octets par tranches de 12 h

Configurer :

- Date histogram sur `@timestamp` ;
- intervalle fixe : `12h` ;
- métrique : Sum ;
- champ : `bytes_sent`.

## Étape 10 — Visualisation 3 : top 5 des URL par 12 h

Configurer :

- Date histogram sur `@timestamp` ;
- intervalle fixe : `12h` ;
- Terms sur `url_path` ;
- taille : 5 ;
- affichage empilé/cumulé si adapté à l’interface.

## Étape 11 — Construire le dashboard

Assembler les trois visualisations sur un même dashboard avec des titres
explicites.

La création des visualisations est volontairement manuelle : elle fait partie
de la compréhension évaluée.

## Preuves à conserver

### Infrastructure

- plan Terraform ;
- domaine actif ;
- endpoint Dashboards anonymisé si nécessaire.

### Données

- import réussi ;
- mapping ;
- nombre de documents ;
- verdict du script de vérification.

### Interface

- Discover ;
- donut des méthodes ;
- octets par 12 h ;
- top 5 par 12 h ;
- dashboard complet.

Gabarit :
[`Livrable 2`](../livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md).

## Ce qu’il ne faut pas publier

- URL complète inutile du domaine ;
- données identifiantes du compte ;
- IP publique complète si elle n’est pas nécessaire ;
- réponses brutes non relues ;
- tfvars ou état Terraform.

## Nettoyage de l’exercice 2

OpenSearch est un service payant : détruisez-le dès que les captures utiles sont
terminées.

```bash
terraform -chdir=terraform/exercice-2 destroy
```

Vous pouvez vérifier la disparition du domaine avec une commande AWS ciblée.

**Ne concluez pas avec `check-aws-cleanup.sh` tant que les exercices 1 ou 3 sont
encore déployés.** Cet audit vérifie l’ensemble du P5 et signalera correctement
ces ressources comme restantes.

Le verdict `NETTOYAGE AWS COMPLET` n’est attendu qu’à la fermeture globale du
lab.

## Étape suivante

- [Exercice 3 — HAProxy](03-haproxy.md)
- ou [Finalisation](../validation-preuves-nettoyage.md) si l’exercice 3 est déjà terminé.
