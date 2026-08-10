# Exercice 2 — Logs NGINX et Amazon OpenSearch

Cette fiche décrit l'implémentation Cloud retenue pour l'exercice 2 : Amazon
OpenSearch Service et OpenSearch Dashboards.

![Flux de l'exercice 2](../schemas/exercice-2.svg)

## Mode recommandé

```bash
bash scripts/commands/p5.sh ex2
```

Le centre de commande déploie OpenSearch, valide les sources, importe le jeu
reproductible puis les logs NGINX réels disponibles, vérifie mappings et
agrégations, puis s'arrête sur le checkpoint humain du dashboard.

Les étapes manuelles restent documentées pour comprendre ou rejouer une partie de
l'exercice.

## Objectif

Importer des événements NGINX structurés dans OpenSearch, vérifier leurs champs
et leurs agrégations, puis construire manuellement un dashboard comprenant les
trois visualisations demandées.

## Résultat final attendu

```text
échantillon reproductible ─┐
                           ├─► conversion Bulk NDJSON
logs NGINX réels ──────────┘
                                   ↓
                             nginx-access-*
                                   ↓
                    mappings + agrégations validés
                                   ↓
                      3 visualisations + dashboard
```

Verdict technique attendu :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

## Pourquoi deux sources de données ?

### Échantillon versionné

```text
terraform/exercice-2/samples/nginx-access.log.sample
```

Il contient 64 événements répartis dans le temps afin de rendre démontrables les
agrégations sur des tranches de 12 heures.

### Log NGINX réel

Produit par l'exercice 1 :

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

Il prouve la chaîne technique réelle :

```text
Angular/NGINX AWS
      ↓
trafic HTTP généré
      ↓
/var/log/nginx/access.log
      ↓
collecte SSH
      ↓
conversion NDJSON
      ↓
Amazon OpenSearch
```

Les deux sources sont donc complémentaires : le jeu versionné garantit la forme
du dashboard, le log réel garantit le bout en bout.

Le convertisseur génère un identifiant déterministe à partir du nom de fichier,
du numéro de ligne et du contenu. Réimporter une même ligne ne crée pas un doublon
de cette ligne dans OpenSearch.

## Prérequis

- étape 0A validée ;
- AWS Ready validé ;
- `environment/aws-readiness.env` à jour ;
- tfvars synchronisés ;
- budget actif ;
- IPv4 `/32` actuelle ;
- aucun domaine OpenSearch conflictuel.

Avec `p5.sh all`, ces prérequis sont contrôlés automatiquement.

Contrôles manuels :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/pre-deployment-check.sh --stage exercice-2
```

## Ce que Terraform crée

`terraform/exercice-2/` crée un domaine Amazon OpenSearch avec :

| Paramètre | Référence |
| --- | --- |
| Domaine | `p5-opensearch` par défaut |
| Moteur | `OpenSearch_2.19` |
| Instance | `t3.small.search` |
| Nœuds | 1 |
| Volume | 10 Gio `gp3` |
| HTTPS | obligatoire |
| TLS | 1.2 minimum |
| Chiffrement au repos | activé |
| Chiffrement inter-nœuds | activé |
| Accès | IPv4 `/32` du lab |

## Fichiers concernés

```text
terraform/exercice-2/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
├── opensearch/index-template.json
└── samples/nginx-access.log.sample

scripts/
├── commands/p5.sh
├── commands/import-opensearch-data.sh
├── commands/verify-opensearch-data.sh
├── commands/generate-nginx-traffic.sh
├── commands/collect-nginx-access-log.sh
└── tools/convert-nginx-logs.py
```

## Procédure manuelle détaillée

### 1. Contrôler l'étape

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-2
./scripts/commands/pre-deployment-check.sh --stage exercice-2
```

### 2. Initialiser et valider Terraform

```bash
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 fmt -check
terraform -chdir=terraform/exercice-2 validate
```

### 3. Produire et relire le plan

```bash
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
```

Vérifier compte, région, moteur, type d'instance, volume, politique `/32`, HTTPS,
TLS, chiffrement et coût potentiel.

### 4. Appliquer

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

### 5. Valider les sources avant import

Échantillon :

```bash
./scripts/commands/import-opensearch-data.sh
```

Log réel :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

Sans `--apply`, aucune donnée n'est envoyée.

### 6. Importer les deux sources

Jeu reproductible :

```bash
./scripts/commands/import-opensearch-data.sh --apply
```

Puis, si le log réel existe :

```bash
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log \
  --apply
```

Cette séquence est exactement celle utilisée par `p5.sh ex2` quand le log réel
est disponible.

Verdict d'import :

```text
IMPORT OPENSEARCH RÉUSSI
```

### 7. Vérifier mappings et agrégations

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le script vérifie :

- `@timestamp` ;
- `http_method` ;
- `url_path` ;
- `bytes_sent` ;
- au moins 64 documents ;
- au moins trois méthodes HTTP ;
- au moins quatre buckets de 12 h ;
- au moins cinq chemins distincts ;
- les agrégations nécessaires au dashboard.

Verdict :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

## Dashboard — checkpoint humain

Dans OpenSearch Dashboards :

1. créer un data view `nginx-access-*` sur `@timestamp` ;
2. vérifier Discover ;
3. créer un donut sur `http_method` ;
4. créer une somme de `bytes_sent` par intervalle fixe `12h` ;
5. créer un top 5 `url_path` par tranches de `12h` ;
6. assembler les trois vues dans un dashboard ;
7. enregistrer les captures nécessaires.

La création des visualisations reste manuelle car elle fait partie de la
compréhension évaluée.

`p5.sh ex2` affiche l'URL du dashboard et exige la saisie exacte `OK` lorsque ces
actions sont réellement terminées. `--yes` ne contourne pas cette étape.

## Preuves à conserver

### Infrastructure

- plan Terraform ;
- domaine actif ;
- endpoint anonymisé si nécessaire.

### Données

- import du jeu reproductible ;
- import du log réel ;
- mapping ;
- nombre de documents ;
- verdict de vérification.

### Interface

- Discover ;
- donut ;
- octets par 12 h ;
- top 5 par 12 h ;
- dashboard complet.

Gabarit :
[Livrable 2](../livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md).

## Ce qu'il ne faut pas publier

- endpoint complet inutile ;
- identifiants de compte ;
- IP publique non nécessaire ;
- réponses brutes non relues ;
- tfvars ou état Terraform ;
- logs opérateur complets.

## Nettoyage

Le mode global recommandé est :

```bash
bash scripts/commands/p5.sh cleanup
```

Si OpenSearch doit être détruit isolément après les captures :

```bash
terraform -chdir=terraform/exercice-2 destroy
```

Ne pas interpréter `check-aws-cleanup.sh` comme un verdict global tant que les
exercices 1 ou 3 existent encore.

## Étape suivante

- [Exercice 3 — HAProxy](03-haproxy.md)
- [Finalisation](../validation-preuves-nettoyage.md)
