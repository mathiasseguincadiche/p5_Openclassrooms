# Exercice 2 — Amazon OpenSearch, logs NGINX et Dashboard as Code

## Objectif pédagogique

Le deuxième exercice transforme des logs techniques en informations exploitables.
La consigne OpenClassrooms emploie le vocabulaire ELK/Kibana ; le mode Cloud du
dépôt utilise **Amazon OpenSearch** et **OpenSearch Dashboards**.

![Exercice 2 — logs NGINX vers Amazon OpenSearch](../schemas/exercice-2.svg)

Le pipeline accepte deux sources complémentaires :

- le sample versionné garantit la reproductibilité ;
- le vrai `access.log` de l'exercice 1 relie l'observabilité à une application
  réellement déployée.

La construction du dashboard n'est plus une opération répétitive à réaliser à
la souris. Sa définition est **versionnée et réconciliée automatiquement**. Le
checkpoint humain reste obligatoire pour vérifier visuellement le résultat et
produire les captures réelles.

## Ce qui doit être démontré

Le dashboard comporte trois visualisations :

1. **donut** : répartition des méthodes HTTP ;
2. **histogramme** : somme des octets envoyés par tranches de 12 heures ;
3. **top 5** : URL les plus fréquentes par tranches de 12 heures.

Les preuves visuelles minimales restent :

- une capture du donut ;
- une capture de la somme des octets / 12 h ;
- une capture du top 5 / 12 h ;
- une capture du dashboard complet.

## Fichiers à connaître

| Élément | Emplacement |
| --- | --- |
| Terraform OpenSearch | `terraform/exercice-2/` |
| Mapping OpenSearch | `terraform/exercice-2/opensearch/index-template.json` |
| Définition Dashboard as Code | `terraform/exercice-2/opensearch/dashboards/p5-dashboard.json` |
| Sample reproductible | `terraform/exercice-2/samples/nginx-access.log.sample` |
| Convertisseur NGINX | `scripts/tools/convert-nginx-logs.py` |
| Générateur Saved Objects | `scripts/tools/build-opensearch-saved-objects.py` |
| Import des données | `scripts/commands/import-opensearch-data.sh` |
| Vérification des données | `scripts/commands/verify-opensearch-data.sh` |
| Synchronisation Dashboards | `scripts/commands/sync-opensearch-dashboards.sh` |
| Test du contrat Dashboards | `scripts/tests/test-opensearch-dashboard-assets.sh` |
| Log réel collecté | `proofs/runtime/exercice-2/nginx-access-real.log` |
| Orchestration | `scripts/commands/p5.sh` |

## 1. Flux complet

Dans un pipeline ELK classique :

```text
logs → Logstash → Elasticsearch → Kibana
```

Dans ce projet Cloud :

```text
NGINX access.log
      ↓
convertisseur P5
      ↓
Bulk API
      ↓
Amazon OpenSearch
      ↓
Saved Objects versionnés
      ↓
OpenSearch Dashboards
      ↓
contrôle visuel humain
```

Le projet ne cherche pas à reproduire artificiellement tous les composants d'un
cluster ELK local. Il utilise le service Cloud demandé tout en conservant la
reproductibilité des données et de la couche de visualisation.

## 2. Sources de données

### Sample versionné

```text
terraform/exercice-2/samples/nginx-access.log.sample
```

Il sert aux tests reproductibles, au parsing connu et à la CI indépendante
d'une EC2 réelle.

### Vrai log de l'exercice 1

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

Il est collecté depuis `/var/log/nginx/access.log` sur l'EC2 Angular. Il relie
l'observabilité à l'application réellement déployée.

Le sample et le log réel ont donc deux rôles différents et complémentaires.

## 3. Contrat de champs

Les visualisations reposent sur quatre champs principaux :

| Champ | Type attendu | Usage |
| --- | --- | --- |
| `@timestamp` | date | buckets temporels de 12 h |
| `http_method` | keyword | répartition par méthode HTTP |
| `bytes_sent` | numérique | somme des octets envoyés |
| `url_path` | keyword | top 5 des URL |

Avant d'importer les Saved Objects, le script de synchronisation interroge
`_field_caps` sur le domaine réel. Il refuse de continuer si un champ requis
est absent, possède un type incompatible ou n'est pas agrégable.

Cette vérification évite de créer un dashboard graphiquement présent mais
fonctionnellement faux.

## 4. Infrastructure Amazon OpenSearch

Le module `terraform/exercice-2` crée notamment :

- un domaine OpenSearch pour le lab ;
- un volume EBS gp3 ;
- le chiffrement au repos ;
- le chiffrement nœud-à-nœud ;
- HTTPS obligatoire ;
- TLS 1.2 ;
- un accès filtré par l'IPv4 publique `/32` du poste.

Si l'IP publique change, relancer `prepare` avant de modifier manuellement une
politique d'accès.

## 5. Outputs Terraform

Les valeurs de référence viennent de Terraform :

```text
opensearch_domain_name
opensearch_endpoint
opensearch_arn
opensearch_dashboards_endpoint
```

Lecture :

```bash
terraform -chdir=terraform/exercice-2 output
```

Le dépôt ne stocke pas d'endpoint AWS inventé ou codé en dur dans les scripts.

## 6. Lancer l'exercice

Le parcours normal est :

```bash
bash scripts/commands/p5.sh ex2
```

L'orchestrateur effectue désormais :

```text
Terraform OpenSearch
       ↓
validation des logs
       ↓
import du sample
       ↓
import du vrai access.log si disponible
       ↓
vérification mapping + agrégations
       ↓
génération du bundle Saved Objects
       ↓
vérification field_caps réel
       ↓
import / réconciliation Dashboards
       ↓
vérification des 5 Saved Objects
       ↓
checkpoint visuel humain
```

## 7. Convergence Terraform

Le cycle Terraform reste :

```text
init
  ↓
plan -detailed-exitcode
  ↓
show
  ↓
confirmation si delta
  ↓
apply
  ↓
post-plan
```

Un plan vide n'est pas appliqué. Un delta doit être compris avant mutation.

OpenSearch est potentiellement facturable tant que le domaine existe. Après les
preuves et la soutenance, le nettoyage reste nécessaire.

## 8. Validation et import des logs

Prévisualisation sans mutation :

```bash
bash scripts/commands/import-opensearch-data.sh
```

Pour le log réel :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

Import réel :

```bash
ENDPOINT="$(terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_endpoint)"

bash scripts/commands/import-opensearch-data.sh \
  --endpoint "$ENDPOINT" \
  --apply
```

Le script réconcilie le template et les documents déterministes au lieu de
considérer chaque exécution comme un premier déploiement.

## 9. Vérification OpenSearch

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$ENDPOINT"
```

Ce contrôle vérifie notamment :

- le mapping ;
- la présence de documents ;
- l'agrégabilité des champs ;
- les agrégations nécessaires au dashboard.

## 10. Dashboard as Code

La source de vérité lisible est :

```text
terraform/exercice-2/opensearch/dashboards/p5-dashboard.json
```

Elle décrit :

```text
index pattern : nginx-access-*
  └── time field : @timestamp

visualisation 1
  └── donut / Terms / http_method

visualisation 2
  └── histogramme / Sum(bytes_sent) / 12 h

visualisation 3
  └── histogramme empilé / Top 5 url_path / 12 h

dashboard
  └── P5 — Observabilité NGINX
      ├── visualisation 1
      ├── visualisation 2
      └── visualisation 3
```

Le fichier reste volontairement plus lisible qu'un export NDJSON brut.

## 11. Génération déterministe des Saved Objects

Le générateur :

```text
scripts/tools/build-opensearch-saved-objects.py
```

combine la définition du dashboard avec le mapping OpenSearch versionné. Il
produit un bundle NDJSON contenant exactement cinq objets :

1. l'index pattern ;
2. le donut des méthodes HTTP ;
3. la somme de `bytes_sent` par 12 h ;
4. le top 5 `url_path` par 12 h ;
5. le dashboard contenant les trois visualisations.

Prévisualisation locale :

```bash
bash scripts/commands/sync-opensearch-dashboards.sh
```

Cette commande ne contacte pas AWS sans `--apply`.

## 12. Synchronisation OpenSearch Dashboards

Dans le parcours automatisé, `p5.sh ex2` appelle :

```bash
bash scripts/commands/sync-opensearch-dashboards.sh \
  --endpoint "$ENDPOINT" \
  --dashboards-url "$DASHBOARDS_URL" \
  --apply
```

Le script :

1. génère le bundle ;
2. vérifie les champs réels avec `_field_caps` ;
3. attend que l'API Dashboards soit disponible ;
4. importe les Saved Objects avec `overwrite=true` ;
5. relit chacun des cinq objets via l'API ;
6. enregistre le bundle, la réponse d'import et la vérification comme preuves ;
7. affiche l'URL directe du dashboard.

Une réexécution reconstruit donc la couche de présentation de manière
reproductible après destruction puis recréation du domaine OpenSearch.

## 13. Les trois visualisations

### Donut des méthodes HTTP

Question traitée :

> Quelle proportion des requêtes utilise chaque méthode HTTP ?

Contrat :

```text
Type       : donut
Agrégation : Terms
Champ      : http_method
```

### Somme de `bytes_sent` par 12 h

Question traitée :

> Combien d'octets le serveur a-t-il envoyé sur chaque période de douze heures ?

Contrat :

```text
Axe temps  : date histogram
Intervalle : 12 h
Métrique   : Sum
Champ      : bytes_sent
```

### Top 5 des URL par 12 h

Question traitée :

> Quelles URL dominent l'activité au fil du temps ?

Contrat :

```text
Temps      : date histogram 12 h
Catégories : Terms
Champ      : url_path
Taille     : 5
```

Ces paramètres sont testés automatiquement dans le dépôt.

## 14. Checkpoint humain

L'automatisation construit le dashboard ; elle ne prétend pas juger sa lisibilité
à la place de l'opérateur.

À la fin de `p5.sh ex2`, le terminal fournit l'URL directe et demande uniquement
de vérifier :

- le donut ;
- la courbe/histogramme `bytes_sent` / 12 h ;
- le top 5 `url_path` / 12 h ;
- le dashboard complet ;
- la plage temporelle ;
- l'absence de filtre parasite ;
- les quatre captures nécessaires.

Même avec :

```bash
bash scripts/commands/p5.sh ex2 --yes
```

le checkpoint pédagogique ne doit pas être validé silencieusement à la place de
l'utilisateur.

## 15. Preuves techniques automatiques

Lors d'une synchronisation réelle, le script ajoute sous :

```text
proofs/runtime/exercice-2/
```

les preuves techniques de la couche Dashboards :

```text
*-dashboards-saved-objects.ndjson
*-dashboards-import.json
*-dashboards-verify.json
```

Ces fichiers complètent les captures :

- l'API prouve que les objets ont été importés et relus ;
- les captures prouvent que le rendu réel est présentable.

## 16. Contrat de CI

Le test :

```bash
bash scripts/tests/test-opensearch-dashboard-assets.sh
```

vérifie :

- les cinq IDs déterministes ;
- le champ `http_method` du donut ;
- `Sum(bytes_sent)` ;
- les intervalles de 12 h ;
- `url_path` avec taille 5 ;
- les trois références du dashboard ;
- l'en-tête `osd-xsrf` ;
- l'import avec `overwrite=true` ;
- un cycle API complet contre un serveur local simulé.

La CI ne remplace pas la validation AWS réelle, mais elle verrouille le contrat
d'automatisation avant le déploiement.

## 17. Dépannage

### Dashboard inaccessible

Vérifier :

```bash
aws sts get-caller-identity
terraform -chdir=terraform/exercice-2 output
```

Puis contrôler l'état du domaine, la région, l'IPv4 `/32` et les endpoints.

### Saved Objects non importés

Relire le log de l'étape `dashboards-assets-sync`. Ne pas recréer immédiatement
les graphiques à la souris : corriger d'abord l'accès API ou le contrat de champs,
puis relancer la convergence.

### Visualisation vide

Contrôler :

- la plage temporelle ;
- la présence de documents ;
- les timestamps ;
- les filtres globaux.

### `bytes_sent` impossible à sommer

Le champ doit être numérique et agrégable. Le contrôle `_field_caps` doit
échouer avant l'import du dashboard si ce contrat n'est pas respecté.

## 18. Definition of Done

```text
OpenSearch AWS actif
+ données importées
+ mapping et agrégations vérifiés
+ contrat field_caps validé
+ index pattern créé automatiquement
+ donut HTTP créé automatiquement
+ bytes_sent / 12 h créé automatiquement
+ top 5 URL / 12 h créé automatiquement
+ dashboard complet créé automatiquement
+ 5 Saved Objects relus par l'API
+ contrôle visuel humain
+ 4 captures réelles
```

Étape suivante : [Exercice 3 — HAProxy](03-haproxy.md).
