# Exercice 2 — Monitoring et logging avec OpenSearch

![Flux de l'exercice 2](../schemas/exercice-2.svg)

## Objectif officiel

Démarrer un environnement de logs, importer des événements NGINX, explorer les
données puis construire un dashboard avec trois visualisations précises.

## Option retenue : Amazon OpenSearch

Le parcours utilise Amazon OpenSearch Service et OpenSearch Dashboards. Le terme
« Kibana » des consignes correspond ici à OpenSearch Dashboards. Le mode Docker
Compose local n’est pas une seconde implémentation du dépôt.

## Implémentation complète

```text
terraform/exercice-2/
├── main.tf
├── outputs.tf
├── variables.tf
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

L’échantillon contient 64 événements, plusieurs méthodes HTTP, au moins cinq
chemins et quatre tranches temporelles de douze heures. Il permet donc de créer
les trois visualisations demandées. Les logs réels de l’exercice 1 peuvent aussi
être collectés puis importés.

## 1. Contrôler et déployer le domaine

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-2

cp terraform/exercice-2/terraform.tfvars.example \
  terraform/exercice-2/terraform.tfvars
$EDITOR terraform/exercice-2/terraform.tfvars

terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 validate
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
terraform -chdir=terraform/exercice-2 apply tfplan
```

Attendre que le domaine soit en état actif avant l’import.

## 2. Prévisualiser puis importer les données

```bash
./scripts/commands/import-opensearch-data.sh
./scripts/commands/import-opensearch-data.sh --apply
```

Sans `--apply`, le script valide le format NGINX et génère uniquement le Bulk
NDJSON local. Avec `--apply`, il :

1. crée ou met à jour le template `p5-nginx-access` ;
2. importe les documents dans `nginx-access-*` ;
3. refuse les erreurs Bulk ;
4. enregistre les réponses sous `proofs/runtime/exercice-2/`.

Pour importer les véritables logs NGINX :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log --apply
```

L’échantillon temporel fourni reste utile pour démontrer plusieurs tranches de
12 heures lorsque les logs réels ont été produits sur une période trop courte.

## 3. Vérifier les champs et les agrégations

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le script vérifie :

- les mappings `@timestamp`, `http_method`, `url_path` et `bytes_sent` ;
- au moins 64 documents ;
- au moins trois méthodes HTTP ;
- au moins quatre tranches de douze heures ;
- au moins cinq chemins exploitables ;
- les agrégations utilisées par le dashboard.

Le verdict attendu est :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

## 4. Créer les trois visualisations

Dans OpenSearch Dashboards, créer un motif de données `nginx-access-*` avec
`@timestamp` comme champ temporel.

1. **Donut des verbes HTTP**
   - agrégation Terms sur `http_method` ;
   - afficher `GET`, `POST`, `HEAD`, `OPTIONS` ou les méthodes présentes.
2. **Octets par tranches de 12 heures**
   - Date histogram sur `@timestamp` avec intervalle fixe `12h` ;
   - somme de `bytes_sent`.
3. **Top 5 des requêtes par tranches de 12 heures**
   - Date histogram fixe `12h` ;
   - Terms sur `url_path`, taille 5 ;
   - affichage empilé ou cumulé.

Assembler ensuite les trois visualisations dans un dashboard unique avec des
titres explicites.

## Preuves attendues

- domaine OpenSearch actif ;
- template, index et documents visibles ;
- verdict du script de vérification ;
- capture Discover avec les champs typés ;
- capture du donut ;
- capture des octets par 12 heures ;
- capture du top 5 par 12 heures ;
- capture du dashboard complet ;
- aucune URL complète, identité ou donnée sensible visible.

Gabarit :
[`SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md).

## Nettoyage

```bash
terraform -chdir=terraform/exercice-2 destroy
./scripts/commands/check-aws-cleanup.sh
```

OpenSearch doit être supprimé dès que les captures sont terminées.
