# Livrable 2 — Dashboard ELK / OpenSearch

> **Gabarit à compléter avec des preuves réelles.** Ce document décrit ce qui doit
> être démontré, mais il ne constitue pas une preuve tant que les sorties et
> captures du véritable environnement n'ont pas été insérées et relues.

## 1. Mode choisi et objectif

- Mode retenu : **Amazon OpenSearch Service**.
- Infrastructure : `terraform/exercice-2/`.
- Moteur de référence : `OpenSearch_2.19`.
- Type de nœud par défaut : `t3.small.search`.
- Stockage par défaut : 10 Gio `gp3`.
- Accès : HTTPS, TLS 1.2 minimum et adresse d'administration limitée en `/32`.
- Index de travail : `nginx-access-*`.

L'objectif est de démontrer la chaîne complète :

```text
logs NGINX
  → conversion structurée
  → import Bulk OpenSearch
  → vérification des mappings et agrégations
  → Discover
  → trois visualisations
  → dashboard final
```

Les données peuvent provenir :

1. des logs NGINX réellement collectés sur l'EC2 de l'exercice 1 ;
2. de l'échantillon reproductible
   `terraform/exercice-2/samples/nginx-access.log.sample` lorsque plusieurs
   tranches temporelles sont nécessaires à la démonstration.

## 2. Déploiement, données et index

### Précontrôle

Avant toute création AWS :

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-2
```

Le verdict attendu est `GO TERRAFORM`.

### Déploiement Terraform

```bash
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 fmt -check
terraform -chdir=terraform/exercice-2 validate
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 show tfplan
terraform -chdir=terraform/exercice-2 apply tfplan
terraform -chdir=terraform/exercice-2 output
```

Avant l'application, vérifier notamment :

- le compte AWS autorisé ;
- la région ;
- le domaine OpenSearch ;
- le type de nœud ;
- la taille du volume ;
- la restriction réseau `/32` ;
- le chiffrement et HTTPS.

### Prévisualisation puis import

Le script d'import est non destructif par défaut :

```bash
./scripts/commands/import-opensearch-data.sh
```

Il valide et transforme les données sans les envoyer au domaine. Après contrôle :

```bash
./scripts/commands/import-opensearch-data.sh --apply
```

Pour utiliser des logs réels de l'exercice 1 :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
./scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log --apply
```

### Vérification technique

```bash
./scripts/commands/verify-opensearch-data.sh
```

Le verdict attendu est :

```text
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Le contrôle vérifie notamment :

- les mappings `@timestamp`, `http_method`, `url_path` et `bytes_sent` ;
- au moins 64 documents ;
- plusieurs méthodes HTTP ;
- plusieurs chemins ;
- au moins quatre tranches de 12 heures ;
- les agrégations nécessaires aux visualisations.

**Preuves à insérer :**

- résultat du `terraform plan` relu ;
- domaine OpenSearch actif ;
- sorties Terraform utiles ;
- verdict de l'import ;
- verdict de la vérification ;
- vue Discover montrant l'index `nginx-access-*` et les champs correctement typés.

Ne pas exposer l'URL complète du domaine, l'identifiant du compte ou toute autre
donnée qui n'est pas nécessaire à la démonstration.

## 3. Visualisation 1 — Donut des verbes HTTP

Dans OpenSearch Dashboards :

- utiliser le motif de données `nginx-access-*` ;
- sélectionner `@timestamp` comme champ temporel ;
- créer une visualisation de type donut ;
- utiliser une agrégation **Terms** sur `http_method` ;
- afficher les méthodes réellement présentes (`GET`, `POST`, `HEAD`, `OPTIONS`,
  etc.).

La capture doit rendre lisibles :

- le titre de la visualisation ;
- les catégories ;
- leur répartition ;
- la période affichée.

**Capture réelle à insérer.**

## 4. Visualisation 2 — Octets par tranches de 12 heures

Créer une visualisation temporelle avec :

- un **Date histogram** sur `@timestamp` ;
- un intervalle fixe de `12h` ;
- une agrégation **Sum** sur `bytes_sent`.

La capture doit montrer plusieurs tranches de 12 heures afin que l'évolution soit
réellement observable.

**Capture réelle à insérer.**

## 5. Visualisation 3 — Top 5 des requêtes par 12 heures

Créer une visualisation avec :

- un **Date histogram** sur `@timestamp` ;
- un intervalle fixe de `12h` ;
- une agrégation **Terms** sur `url_path` ;
- une taille limitée à 5 ;
- un affichage empilé, cumulé ou équivalent permettant de comparer les chemins.

La capture doit permettre d'identifier les cinq chemins les plus fréquents et
leur évolution dans le temps.

**Capture réelle à insérer.**

## 6. Dashboard complet

Assembler les trois visualisations dans un dashboard unique avec des titres
explicites :

1. répartition des méthodes HTTP ;
2. volume d'octets par 12 heures ;
3. top 5 des chemins par 12 heures.

Le dashboard final doit être lisible sans ouvrir chaque visualisation
séparément.

**Capture réelle du dashboard complet à insérer.**

### Conclusion à rédiger

Expliquer en quelques lignes :

- ce que montrent les données ;
- pourquoi les champs et agrégations choisis répondent à la consigne ;
- ce que le dashboard permettrait d'observer dans un contexte d'exploitation.

Une capture seule ne suffit pas à démontrer la compréhension.

## 7. Nettoyage

OpenSearch est une ressource payante : le domaine doit être détruit dès que les
preuves sont terminées.

```bash
terraform -chdir=terraform/exercice-2 destroy
```

Vérifier ensuite spécifiquement le domaine :

```bash
aws --profile p5-lab --region us-east-1 \
  opensearch list-domain-names
```

**Preuve à insérer :** disparition du domaine OpenSearch utilisé pour le P5.

> Ne lancer `check-aws-cleanup.sh` comme verdict global qu'après la destruction
> finale des exercices 3, 2 et 1. Tant que l'exercice 1 ou 3 reste volontairement
> actif, cet audit global doit signaler des ressources restantes.

## Données à ne pas publier

Avant la remise, vérifier l'absence de :

- identifiants AWS ;
- URL complètes du domaine si elles ne sont pas nécessaires ;
- IP publiques complètes lorsqu'elles n'apportent aucune valeur pédagogique ;
- fichiers `terraform.tfvars` ou états Terraform ;
- journaux bruts non relus ;
- jetons, clés ou en-têtes d'autorisation.

Les sorties techniques intermédiaires restent sous
`proofs/runtime/exercice-2/` et ne sont pas versionnées.
