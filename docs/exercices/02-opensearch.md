# Exercice 2 — Amazon OpenSearch, logs NGINX et dashboard

## Objectif pédagogique

Le deuxième exercice apprend à transformer des logs techniques en informations exploitables.

La consigne OpenClassrooms utilise le vocabulaire ELK/Kibana. Le mode Cloud choisi par ce dépôt utilise **Amazon OpenSearch** et **OpenSearch Dashboards**.

![Exercice 2 — logs NGINX vers Amazon OpenSearch](../schemas/exercice-2.svg)

Le pipeline accepte deux sources complémentaires : le sample versionné garantit la reproductibilité,
et le vrai `access.log` de l'exercice 1 relie l'observabilité à une application réellement déployée.
La construction et la vérification visuelle du dashboard restent un **checkpoint humain**.

## Ce qui doit être démontré

Le dashboard comporte trois visualisations :

1. **donut** : répartition des méthodes HTTP ;
2. **histogramme** : somme des octets envoyés par tranches de 12 heures ;
3. **top 5** : URL/requêtes les plus fréquentes par tranches de 12 heures.

Les preuves visuelles minimales sont :

- une capture du donut ;
- une capture de la somme des octets / 12 h ;
- une capture du top 5 / 12 h ;
- une capture du dashboard complet.

## Fichiers à connaître

| Élément | Emplacement |
| --- | --- |
| Terraform OpenSearch | `terraform/exercice-2/` |
| modèle de mapping | `terraform/exercice-2/opensearch/index-template.json` |
| sample reproductible | `terraform/exercice-2/samples/nginx-access.log.sample` |
| convertisseur | `scripts/tools/convert-nginx-logs.py` |
| import | `scripts/commands/import-opensearch-data.sh` |
| vérification | `scripts/commands/verify-opensearch-data.sh` |
| log réel collecté | `proofs/runtime/exercice-2/nginx-access-real.log` |
| orchestration | `scripts/commands/p5.sh` |

## 1. ELK et OpenSearch : comprendre la correspondance

Dans un pipeline ELK classique :

```text
logs → Logstash → Elasticsearch → Kibana
```

Dans ce projet Cloud :

```text
logs
  ↓
convertisseur P5
  ↓
Bulk API
  ↓
Amazon OpenSearch
  ↓
OpenSearch Dashboards
```

Le projet ne cherche pas à reproduire artificiellement tous les composants d'un cluster ELK local. Il utilise le service Cloud autorisé par l'exercice tout en conservant le travail attendu sur les données et le dashboard.

## 2. Sources de données

### Source 1 — sample versionné

```text
terraform/exercice-2/samples/nginx-access.log.sample
```

Pourquoi le conserver ?

- tests reproductibles ;
- CI indépendante d'une EC2 réelle ;
- format connu ;
- possibilité de vérifier le parsing sans AWS.

### Source 2 — vrai log de l'exercice 1

```text
proofs/runtime/exercice-2/nginx-access-real.log
```

Il est collecté depuis `/var/log/nginx/access.log` sur l'EC2 Angular.

Pourquoi l'utiliser ?

Parce qu'il relie l'observabilité à une application réellement déployée au lieu de rester uniquement sur un dataset fourni.

Le sample reste toutefois la base reproductible du dépôt.

## 3. Comprendre les champs utiles

Le pipeline doit permettre d'exploiter au minimum des informations telles que :

```text
horodatage
méthode HTTP
URL / chemin
code de statut
bytes envoyés
```

Les visualisations dépendent directement du typage de ces champs.

Exemples :

- une méthode HTTP doit être agrégable comme catégorie ;
- `bytes_sent` doit être numérique pour calculer une somme ;
- l'horodatage doit être reconnu comme date pour créer des buckets de 12 h ;
- `url_path` doit permettre une agrégation `terms` pour extraire un top 5.

## 4. Infrastructure Amazon OpenSearch

Le module `terraform/exercice-2` crée un domaine avec :

- version moteur configurable, référence `OpenSearch_2.19` ;
- une instance pour le lab ;
- EBS gp3 ;
- chiffrement au repos ;
- chiffrement node-to-node ;
- HTTPS obligatoire ;
- politique TLS 1.2 ;
- accès filtré par l'IPv4 publique `/32` du poste.

### Pourquoi l'accès est filtré par IP ?

Le dashboard et l'API ne doivent pas être ouverts à Internet entier pour un lab personnel.

Si votre IP publique change, `prepare` doit être relancé afin de recalculer la configuration et le plan Terraform.

## 5. Outputs Terraform

Le module publie :

```text
opensearch_domain_name
opensearch_endpoint
opensearch_arn
opensearch_dashboards_endpoint
```

Lecture manuelle :

```bash
terraform -chdir=terraform/exercice-2 output
```

Endpoint API :

```bash
terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_endpoint
```

Dashboard :

```bash
terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_dashboards_endpoint
```

`p5.sh` considère ces outputs comme les valeurs de référence.

## 6. Lancer l'exercice

```bash
bash scripts/commands/p5.sh ex2
```

L'orchestrateur exécute la convergence Terraform puis le pipeline de données.

## 7. Terraform : lire le plan OpenSearch

Comme pour l'exercice 1 :

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

Avant d'accepter, vérifier :

- nom du domaine ;
- version moteur ;
- instance type ;
- volume ;
- chiffrement ;
- HTTPS ;
- SourceIp `/32` ;
- région ;
- compte AWS ;
- coût potentiel.

### Coût

OpenSearch doit être considéré comme facturable tant que le domaine existe. Ne pas laisser le domaine tourner plusieurs jours après la fin des captures.

## 8. Valider le sample sans mutation

```bash
bash scripts/commands/import-opensearch-data.sh
```

Sans `--apply`, le script prépare et valide le flux mais ne doit pas être interprété comme une autorisation implicite de modifier OpenSearch.

Le but est de détecter les erreurs de données avant l'import réel.

## 9. Valider le log réel

S'il existe :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log
```

Si le fichier est absent :

1. vérifier si l'exercice 1 a réellement été exécuté ;
2. vérifier la collecte NGINX ;
3. relancer `ex1` si nécessaire ;
4. ne pas fabriquer un faux `access.log` présenté comme preuve réelle.

## 10. Importer les documents

Après création du domaine et confirmation :

```bash
ENDPOINT="$(terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_endpoint)"
```

Import sample :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --endpoint "$ENDPOINT" \
  --apply
```

Import log réel :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log \
  --endpoint "$ENDPOINT" \
  --apply
```

### Pourquoi `--apply` est explicite ?

Le dépôt sépare volontairement :

```text
vérifier / prévisualiser
        vs
modifier l'état distant
```

Cette séparation réduit les mutations accidentelles.

## 11. Vérifier OpenSearch

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$ENDPOINT"
```

Ce contrôle doit répondre notamment :

- le mapping est-il présent/utilisable ?
- des documents sont-ils indexés ?
- les champs attendus sont-ils agrégables ?
- les agrégations nécessaires au dashboard retournent-elles des données ?

La CI exécute une variante locale avec un conteneur OpenSearch éphémère pour vérifier ce contrat sans utiliser le compte AWS.

## 12. Ouvrir OpenSearch Dashboards

```bash
terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_dashboards_endpoint
```

Ouvrir l'URL dans le navigateur depuis le poste dont l'IP `/32` est autorisée.

Si l'accès échoue après un changement de réseau, vérifier d'abord l'IP publique actuelle et le plan Terraform.

## 13. Vérifier Discover

Avant de construire des graphiques, explorer les documents.

Objectifs :

- confirmer que le data view/index attendu contient des données ;
- vérifier les timestamps ;
- inspecter `http_method` ;
- inspecter `bytes_sent` ;
- inspecter `url_path` ;
- vérifier la plage de temps sélectionnée.

Une visualisation vide peut être causée par une plage temporelle qui ne couvre pas les événements.

## 14. Visualisation 1 — Donut des méthodes HTTP

### Question

> Quelle proportion des requêtes utilise chaque méthode HTTP ?

### Configuration conceptuelle

```text
Type       : donut
Agrégation : Terms
Champ      : http_method
```

Le résultat doit rendre visibles des catégories comme GET, POST ou toute autre méthode réellement présente.

### Ce que la capture doit montrer

- titre compréhensible ;
- légende ;
- valeurs/catégories lisibles ;
- absence de filtre parasite.

## 15. Visualisation 2 — Somme de `bytes_sent` par 12 h

### Question

> Combien d'octets le serveur a-t-il envoyé sur chaque période de douze heures ?

### Configuration conceptuelle

```text
Axe temps    : date histogram
Intervalle   : 12 h
Métrique     : Sum
Champ        : bytes_sent
```

`bytes_sent` doit être numérique. Si l'interface refuse une somme, revenir au mapping au lieu de contourner le problème avec un autre champ.

## 16. Visualisation 3 — Top 5 des URL par 12 h

### Question

> Quelles URL dominent l'activité au fil du temps ?

### Configuration conceptuelle

```text
Temps         : date histogram 12 h
Catégories    : Terms
Champ         : url_path
Taille        : 5
Présentation  : histogramme empilé/cumulé selon l'interface
```

La terminologie exacte de l'interface OpenSearch peut varier, mais le sens de la métrique ne doit pas changer.

## 17. Construire le dashboard

Ajouter les trois visualisations dans un dashboard unique.

Le dashboard doit être lisible sans avoir besoin d'expliquer oralement où se trouve chaque information.

Bonnes pratiques :

- titres explicites ;
- tailles de panneaux cohérentes ;
- plage de temps visible ;
- légendes non tronquées ;
- aucun filtre résiduel non expliqué.

## 18. Les quatre captures

Conserver :

```text
1. donut HTTP
2. bytes_sent / 12 h
3. top 5 URL / 12 h
4. dashboard complet
```

Les captures doivent provenir de l'environnement réellement utilisé pour le projet.

## 19. Checkpoint humain de `p5.sh`

`p5.sh ex2` affiche une action manuelle et demande de confirmer uniquement après avoir réalisé les vérifications/captures.

Même avec :

```bash
bash scripts/commands/p5.sh ex2 --yes
```

le moteur ne doit pas déclarer le dashboard humainement validé à votre place.

C'est volontaire : **l'automatisation ne doit pas fabriquer une preuve pédagogique**.

## 20. Différence entre sample et preuve réelle

| Élément | Rôle |
| --- | --- |
| sample versionné | reproductibilité et tests |
| log réel ex. 1 | relier observabilité et application déployée |
| test local OpenSearch | qualité du dépôt |
| domaine AWS | réalisation Cloud de l'exercice |
| captures Dashboards | preuve visuelle demandée |

## 21. Diagnostic

### Dashboard inaccessible

Vérifier :

```bash
aws sts get-caller-identity
terraform -chdir=terraform/exercice-2 output
```

Puis :

- domaine actif ;
- bonne région ;
- bonne IP `/32` ;
- endpoint correct.

### Aucun document

Rejouer :

```bash
bash scripts/commands/import-opensearch-data.sh
bash scripts/commands/verify-opensearch-data.sh --endpoint "$ENDPOINT"
```

Ne pas commencer les graphiques avant d'avoir des données vérifiées.

### Aucun résultat dans Discover

Contrôler :

- data view/index ;
- plage temporelle ;
- filtres ;
- timestamps des événements.

### Impossible de sommer `bytes_sent`

Le champ est probablement mal typé ou le mauvais champ est sélectionné. Vérifier le mapping.

### Top 5 incohérent

Contrôler :

- agrégation `terms` ;
- champ `url_path` ;
- taille = 5 ;
- intervalle de 12 h ;
- filtres globaux.

## 22. Definition of Done

```text
OpenSearch AWS actif
+ données importées
+ mapping et agrégations vérifiés
+ Discover exploitable
+ donut HTTP
+ bytes_sent / 12 h
+ top 5 URL / 12 h
+ dashboard complet
+ 4 captures réelles
```

Étape suivante : [Exercice 3 — HAProxy](03-haproxy.md).
