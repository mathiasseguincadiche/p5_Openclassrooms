# Livrable 2 — Amazon OpenSearch et dashboard de logs

> **Gabarit à compléter avec des preuves réelles.** Le nom du livrable conserve la référence historique Kibana de la consigne, mais le mode Cloud choisi utilise Amazon OpenSearch et OpenSearch Dashboards.

## 1. Objectif

Démontrer la transformation de logs NGINX en données indexées puis en visualisations utiles à l'exploitation.

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
- index : `nginx-access-*` ;
- données : sample reproductible + log réel de l'exercice 1 lorsque disponible ;
- interface : OpenSearch Dashboards ;
- accès : HTTPS et IPv4 `/32`.

## 3. Exécution de référence

```bash
bash scripts/commands/p5.sh ex2
```

La commande converge Terraform, valide les données, importe le sample et le log réel disponible, vérifie les agrégations puis ouvre un checkpoint humain pour le dashboard.

## 4. Preuve Terraform / OpenSearch

À montrer :

- plan relu ;
- domaine OpenSearch actif ;
- HTTPS ;
- chiffrement ;
- SourceIp `/32` ;
- outputs utiles.

Outputs disponibles :

```text
opensearch_domain_name
opensearch_endpoint
opensearch_arn
opensearch_dashboards_endpoint
```

**Preuve Terraform/OpenSearch réelle à insérer ici.**

## 5. Preuve d'import

Récupérer l'endpoint :

```bash
ENDPOINT="$(terraform -chdir=terraform/exercice-2 \
  output -raw opensearch_endpoint)"
```

Le mode de validation du sample est :

```bash
bash scripts/commands/import-opensearch-data.sh
```

L'import réel correspondant est :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --endpoint "$ENDPOINT" \
  --apply
```

Pour le log réel de l'exercice 1 :

```bash
bash scripts/commands/import-opensearch-data.sh \
  --input proofs/runtime/exercice-2/nginx-access-real.log \
  --endpoint "$ENDPOINT" \
  --apply
```

**Preuve de l'import sans erreur à insérer ici.**

## 6. Preuve technique des données

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$ENDPOINT"
```

À montrer :

- index présent ;
- documents présents ;
- mapping exploitable ;
- `http_method` agrégable ;
- `bytes_sent` numérique ;
- `url_path` agrégable ;
- agrégations nécessaires au dashboard fonctionnelles.

**Preuve de vérification technique à insérer ici.**

## 7. Discover

Dans OpenSearch Dashboards, vérifier :

- le bon data view/index ;
- la plage temporelle ;
- les champs structurés ;
- plusieurs documents ;
- absence de filtre parasite.

**Capture Discover à insérer si elle apporte une preuve utile au livrable.**

## 8. Visualisation 1 — Donut des méthodes HTTP

### Question

Quelle proportion des requêtes correspond à chaque méthode HTTP ?

### Configuration

```text
Type       : donut
Agrégation : Terms
Champ      : http_method
```

### Capture

**Capture réelle du donut à insérer ici.**

### Interprétation

Rédiger ce que la répartition montre réellement dans vos données.

## 9. Visualisation 2 — Octets envoyés par 12 heures

### Question

Quel volume de données est envoyé par le serveur sur chaque tranche de 12 h ?

### Configuration

```text
Temps      : Date histogram
Intervalle : 12 h
Métrique   : Sum
Champ      : bytes_sent
```

### Capture

**Capture réelle de l'histogramme à insérer ici.**

### Interprétation

Expliquer les périodes où le volume varie et le sens de la somme.

## 10. Visualisation 3 — Top 5 des URL par 12 heures

### Question

Quelles URL sont les plus sollicitées au fil du temps ?

### Configuration

```text
Temps      : Date histogram
Intervalle : 12 h
Catégories : Terms
Champ      : url_path
Taille     : 5
```

### Capture

**Capture réelle du top 5 à insérer ici.**

### Interprétation

Expliquer ce que les cinq chemins dominants montrent dans l'échantillon ou les logs réels.

## 11. Dashboard complet

Assembler les trois visualisations et vérifier :

- titres explicites ;
- légendes lisibles ;
- plage de temps cohérente ;
- aucun filtre résiduel non expliqué ;
- trois panneaux visibles.

**Capture réelle du dashboard complet à insérer ici.**

## 12. Quatre captures attendues

Checklist :

- [ ] donut méthodes HTTP ;
- [ ] `bytes_sent` / 12 h ;
- [ ] top 5 `url_path` / 12 h ;
- [ ] dashboard complet.

## 13. Conclusion à rédiger

La conclusion doit expliquer :

- comment les logs ont été transformés ;
- pourquoi les champs choisis répondent aux trois métriques ;
- ce que le dashboard permet d'observer ;
- la différence entre la vérification automatisée des données et le checkpoint humain du dashboard.

## 14. Sécurité des preuves

Ne pas publier :

- identifiants AWS ;
- tokens ;
- state Terraform ;
- vrais `tfvars` ;
- logs bruts complets non relus ;
- endpoints complets lorsqu'ils ne sont pas nécessaires.

## 15. Nettoyage

Le nettoyage global est orchestré en fin de projet :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```
