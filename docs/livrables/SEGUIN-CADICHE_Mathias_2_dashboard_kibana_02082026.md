# Livrable 2 — Amazon OpenSearch et dashboard de logs

> **État vérifié le 23 août 2026.** Le nom du fichier conserve la référence historique à Kibana de la consigne, tandis que la réalisation Cloud utilise Amazon OpenSearch Service et OpenSearch Dashboards. Les preuves techniques proviennent du lab AWS réel ; les captures visuelles ont été validées au checkpoint humain et restent hors des données runtime publiques du dépôt.

## 1. Objectif

Démontrer la transformation de logs NGINX en documents structurés et indexés, puis leur exploitation à travers trois visualisations et un dashboard opérationnel.

```text
logs NGINX
  ↓
conversion
  ↓
Bulk API
  ↓
Amazon OpenSearch
  ↓
Discover
  ↓
3 visualisations
  ↓
dashboard
```

## 2. Choix de réalisation

- mode : Amazon OpenSearch Service ;
- infrastructure : `terraform/exercice-2/` ;
- domaine : `p5-opensearch` ;
- moteur validé : OpenSearch 2.19 ;
- index : `nginx-access-*` ;
- données : sample reproductible + log NGINX réel de l'exercice 1 ;
- interface : OpenSearch Dashboards ;
- accès : HTTPS et IPv4 d'administration limitée en `/32` ;
- chiffrement : activé par l'infrastructure Terraform.

## 3. Exécution de référence

```bash
bash scripts/commands/p5.sh ex2
```

Run de validation retenu : `20260823T031553Z`.

```text
validated_steps=9
failed_steps=0
result=OK
```

Le run a revérifié Terraform, les deux sources de données, leur présence dans OpenSearch, les mappings et agrégations, puis a imposé un checkpoint humain avant de valider la partie visuelle.

## 4. Preuve Terraform / OpenSearch

Le domaine a été créé lors du déploiement AWS réel. La création Terraform a été suivie d'un post-plan sans dérive. Lors du run final, Terraform a de nouveau obtenu :

```text
No changes. Your infrastructure matches the configuration.
```

L'état AWS contrôlé indiquait :

```text
DomainName        : p5-opensearch
Created           : true
Deleted           : false
Processing        : false
UpgradeProcessing : false
EngineVersion     : OpenSearch_2.19
```

Verdict automatisé :

```text
ÉTAT AWS EXERCICE 2 VALIDÉ — OPENSEARCH ACTIF
```

Les endpoints complets et l'ARN ne sont pas reproduits dans ce livrable car leur valeur n'est pas nécessaire pour démontrer la compétence.

Traces techniques privées :

```text
proofs/runtime/steps/20260823T031553Z/02-tf-ex2-plan.log
proofs/runtime/steps/20260823T031553Z/03-tf-ex2-show.log
proofs/runtime/steps/20260823T031553Z/04-tf-ex2-output.log
proofs/runtime/exercice-2/20260823T031905Z-etat-aws-exercice-2.log
```

## 5. Preuve d'import

Deux jeux de données ont été contrôlés :

```text
Sample reproductible : 64 documents
Logs NGINX réels     : 91 documents
Total indexé          : 155 documents
```

Le sample couvre :

```text
2026-07-30T00:05:00Z → 2026-07-31T23:20:00Z
```

Le log réel de l'exercice 1 couvre :

```text
2026-08-23T01:36:57Z → 2026-08-23T01:53:22Z
```

Lors de la réconciliation finale, les **91/91 documents réels** étaient déjà présents et le Bulk a donc été correctement ignoré au lieu de créer des doublons.

```text
OK  91/91 documents déjà présents — Bulk ignoré
OK  documents présents dans nginx-access-* : 155
Verdict : OPENSEARCH CONVERGÉ
```

Cette convergence idempotente prouve que le mécanisme d'import sait distinguer les documents déjà indexés des données manquantes.

## 6. Preuve technique des données

Commande de vérification :

```bash
ENDPOINT="$(terraform -chdir=terraform/exercice-2 output -raw opensearch_endpoint)"
bash scripts/commands/verify-opensearch-data.sh --endpoint "$ENDPOINT"
```

Résultat réel :

```text
OK  mappings @timestamp, http_method, url_path et bytes_sent
OK  documents : 155
OK  méthodes HTTP : 4
OK  tranches de 12 heures : 5
OK  chemins exploitables : 9
```

Distribution des méthodes :

```text
GET     90
POST    32
HEAD    21
OPTIONS 12
```

Somme de `bytes_sent` par tranches de 12 heures :

```text
2026-07-30 00:00 UTC   28 952 octets
2026-07-30 12:00 UTC   73 240 octets
2026-07-31 00:00 UTC   39 528 octets
2026-07-31 12:00 UTC   65 816 octets
2026-08-23 00:00 UTC   70 048 octets
```

Verdict :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Trace principale :

```text
proofs/runtime/steps/20260823T031553Z/09-opensearch-verify.log
```

## 7. Discover

Le data view utilisé est :

```text
nginx-access-*
```

avec `@timestamp` comme champ temporel. La vérification a porté sur les champs structurés utiles au dashboard, notamment :

```text
@timestamp
http_method
bytes_sent
url_path
status
request
```

La plage temporelle finale a été élargie afin de couvrir à la fois le sample de juillet et les vrais logs du 23 août. Cela évite qu'un filtre de temps trop court masque une partie des 155 documents.

La vérification automatisée des 155 documents complète la vérification visuelle réalisée dans OpenSearch Dashboards.

## 8. Visualisation 1 — Donut des méthodes HTTP

### Question

Quelle proportion des requêtes correspond à chaque méthode HTTP ?

### Configuration validée

```text
Type       : Donut
Agrégation : Terms
Champ      : http_method
Métrique   : Count
```

### Résultat et interprétation

Les données contiennent quatre méthodes :

```text
GET     = 90  (~58 %)
POST    = 32  (~21 %)
HEAD    = 21  (~14 %)
OPTIONS = 12  (~8 %)
```

`GET` est donc nettement majoritaire. Le donut permet de voir immédiatement la répartition du trafic par verbe HTTP et de repérer qu'une part significative du jeu contient aussi des requêtes `POST`, `HEAD` et `OPTIONS`.

La visualisation a été contrôlée avec une plage temporelle couvrant l'ensemble des données avant validation du checkpoint humain.

## 9. Visualisation 2 — Octets envoyés par 12 heures

### Question

Quel volume de données est envoyé par le serveur sur chaque tranche de 12 h ?

### Configuration validée

```text
Temps      : Date Histogram
Intervalle : 12 h
Métrique   : Sum
Champ      : bytes_sent
```

### Résultat et interprétation

Le maximum observé est **73 240 octets** pour la tranche du 30 juillet à 12:00 UTC. La tranche issue des logs NGINX réels du 23 août totalise **70 048 octets**.

Cette métrique représente la somme du volume effectivement envoyé pour toutes les requêtes appartenant à chaque fenêtre de 12 heures. Les différences entre les barres reflètent donc la combinaison du nombre de requêtes et de leur taille de réponse.

## 10. Visualisation 3 — Top 5 des URL par 12 heures

### Question

Quelles URL sont les plus sollicitées au fil du temps ?

### Configuration validée

```text
Temps      : Date Histogram
Intervalle : 12 h
Catégories : Terms
Champ      : url_path
Taille     : 5
Métrique   : Count
```

### Résultat et interprétation

La vérification technique a confirmé **9 chemins exploitables** dans les 155 documents. La visualisation limite volontairement l'affichage aux cinq chemins les plus fréquents afin de conserver un graphique lisible et de suivre leur évolution par tranche de 12 heures.

Le classement détaillé reste celui calculé par OpenSearch au moment de la capture ; il n'est pas recopié manuellement ici afin de ne pas inventer des valeurs distinctes du résultat visuel.

## 11. Dashboard complet

Les trois visualisations ont été assemblées dans un dashboard OpenSearch :

```text
1. répartition des méthodes HTTP
2. somme de bytes_sent / 12 h
3. top 5 url_path / 12 h
```

Le contrôle final a porté sur :

- les trois panneaux visibles ;
- les titres et légendes lisibles ;
- la plage temporelle couvrant juillet et août ;
- l'absence de filtre résiduel susceptible de masquer les données ;
- la cohérence entre les graphiques et les agrégations automatisées.

L'orchestrateur a ensuite demandé une confirmation explicite :

```text
ACTION MANUELLE — Dashboard OpenSearch
- vérifier/créer le donut des méthodes HTTP
- vérifier/créer la somme de bytes_sent par tranches de 12 h
- vérifier/créer le top 5 url_path par tranches de 12 h
- enregistrer les captures nécessaires aux livrables
Tapez exactement OK
```

Cette action a été confirmée et le run a terminé par :

```text
Exercice 2 convergé côté infrastructure/données et preuve visuelle confirmée.
```

## 12. Quatre captures attendues

Le checkpoint humain a été validé après enregistrement des éléments visuels de remise :

- [x] donut méthodes HTTP ;
- [x] `bytes_sent` / 12 h ;
- [x] top 5 `url_path` / 12 h ;
- [x] dashboard complet.

Ces images sont des éléments de présentation et ne sont pas nécessaires au fonctionnement du dépôt. Les logs runtime et les endpoints complets restent privés par défaut.

## 13. Conclusion à rédiger

Les 91 lignes NGINX réelles de l'exercice 1 ont été combinées à un sample reproductible de 64 lignes, soit 155 documents structurés dans OpenSearch. Le mapping rend `http_method` et `url_path` agrégables et `bytes_sent` numérique, ce qui permet de construire les trois métriques demandées. La vérification automatisée prouve la présence et la cohérence des données ; le checkpoint humain prouve que ces données ont été correctement transformées en visualisations lisibles dans OpenSearch Dashboards.

## 14. Sécurité des preuves

Ne sont pas publiés dans ce document :

- identifiants ou secrets AWS ;
- tokens ou informations de session ;
- state Terraform ;
- vrais `tfvars` ;
- logs bruts complets non relus ;
- endpoint OpenSearch complet lorsqu'il n'apporte rien à la démonstration.

Les scripts et résultats synthétiques suffisent à rendre la démarche reproductible sans exposer les données sensibles du lab.

## 15. Nettoyage

Le domaine OpenSearch reste actif tant que les preuves et la relecture finale ne sont pas terminées.

Le nettoyage global sera déclenché avec :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```
