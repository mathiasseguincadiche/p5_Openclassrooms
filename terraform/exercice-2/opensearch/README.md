# Chaîne de données OpenSearch

Ce dossier complète le module Terraform de l'exercice 2. Terraform crée le
domaine ; les scripts du dépôt préparent, importent et vérifient les données.
Les visualisations restent construites manuellement dans OpenSearch Dashboards
afin de démontrer la compréhension des champs et des agrégations.

## Fichiers

```text
terraform/exercice-2/
├── opensearch/
│   ├── README.md
│   └── index-template.json
└── samples/
    └── nginx-access.log.sample

scripts/
├── commands/
│   ├── import-opensearch-data.sh
│   └── verify-opensearch-data.sh
└── tools/
    └── convert-nginx-logs.py
```

L'échantillon contient 64 événements répartis sur deux jours. Il fournit au
moins quatre intervalles de douze heures, plusieurs méthodes HTTP, huit chemins
et des volumes d'octets différents.

## 1. Contrôler les données sans écrire dans OpenSearch

```bash
./scripts/commands/import-opensearch-data.sh
```

Cette commande :

1. valide chaque ligne au format NGINX `combined` ;
2. convertit les dates en ISO 8601 ;
3. transforme les nombres en types numériques ;
4. prépare les paires action/document de l'API Bulk ;
5. affiche le nombre de documents ;
6. ne contacte pas le domaine OpenSearch.

## 2. Importer les données

Après le déploiement Terraform et le contrôle AWS Ready de l'exercice 2 :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/import-opensearch-data.sh --apply
```

Le script récupère l'endpoint depuis l'état Terraform, crée ou met à jour le
template `p5-nginx-access`, importe les documents avec l'API Bulk puis force un
rafraîchissement de l'index.

Les fichiers techniques générés sont enregistrés localement sous
`proofs/runtime/exercice-2/`. Ce dossier est ignoré par Git afin d'éviter de
publier un endpoint ou une donnée d'environnement.

## 3. Vérifier l'index

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le verdict est bloquant lorsque l'un des éléments suivants manque :

- 64 documents ou davantage ;
- les mappings `@timestamp`, `http_method`, `url_path` et `bytes_sent` ;
- au moins trois méthodes HTTP ;
- au moins quatre tranches de douze heures ;
- au moins cinq chemins distincts.

Le script exécute également les agrégations utilisées par les trois graphiques.

## 4. Créer le motif d'index

Dans OpenSearch Dashboards :

1. ouvrir **Stack Management** puis **Index patterns** ;
2. créer le motif `nginx-access-*` ;
3. sélectionner `@timestamp` comme champ temporel ;
4. ouvrir **Discover** ;
5. régler la période sur les 30 et 31 juillet 2026 ;
6. vérifier que les 64 documents et leurs champs sont visibles.

## 5. Créer les trois visualisations

### Donut des méthodes HTTP

- source : `nginx-access-*` ;
- métrique : nombre de documents ;
- regroupement : `Terms` sur `http_method` ;
- taille : 10 ;
- type : donut.

### Octets cumulés par tranches de douze heures

- axe horizontal : `Date histogram` sur `@timestamp` ;
- intervalle fixe : `12h` ;
- métrique : `Sum` sur `bytes_sent` ;
- type : histogramme vertical.

### Top 5 des requêtes par tranches de douze heures

- axe horizontal : `Date histogram` sur `@timestamp` ;
- intervalle fixe : `12h` ;
- série : `Terms` sur `url_path` ;
- taille : 5 ;
- mode : empilé ou cumulé.

## 6. Preuves à conserver

- résultat de `verify-opensearch-data.sh` ;
- index visible dans Discover ;
- donut lisible ;
- histogramme des octets ;
- top 5 des chemins ;
- dashboard réunissant les trois visualisations.

Les captures doivent provenir du domaine réellement utilisé. Les réponses JSON
locales aident au diagnostic, mais ne remplacent pas les quatre captures.
