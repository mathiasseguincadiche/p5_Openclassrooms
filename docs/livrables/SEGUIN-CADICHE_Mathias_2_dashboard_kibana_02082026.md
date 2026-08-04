# Livrable 2 — Dashboard ELK / OpenSearch

> **Gabarit à compléter.** Les captures doivent provenir de l'environnement
> réellement utilisé pendant l'exercice.

## 1. Mode choisi

- Mode retenu : **Amazon OpenSearch**.
- Infrastructure : `terraform/exercice-2/`.
- Données : `terraform/exercice-2/samples/nginx-access.log.sample` ou le
  fichier fourni par le starter officiel.

## 2. Déploiement et index

```bash
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 validate
terraform -chdir=terraform/exercice-2 plan
terraform -chdir=terraform/exercice-2 apply
```

**Preuves à insérer :** domaine disponible, URL OpenSearch Dashboards
anonymisée, index `nginx-access` visible et données consultables dans Discover.

## 3. Visualisation 1 — Donut des verbes HTTP

- Agrégation sur le champ de méthode HTTP.
- Les catégories `GET`, `POST` et autres méthodes présentes sont lisibles.

**Capture réelle à insérer.**

## 4. Visualisation 2 — Octets par tranches de 12 heures

- Axe temporel par intervalles de 12 heures.
- Somme ou quantité cumulée du champ représentant les octets transférés.

**Capture réelle à insérer.**

## 5. Visualisation 3 — Top 5 des requêtes par 12 heures

- Axe temporel par intervalles de 12 heures.
- Cinq requêtes ou URL les plus fréquentes.
- Affichage cumulé ou empilé conformément à l'interface utilisée.

**Capture réelle à insérer.**

## 6. Dashboard complet

Le dashboard doit montrer les trois visualisations simultanément avec des
titres explicites.

**Capture réelle du dashboard complet à insérer.**

## 7. Nettoyage

```bash
terraform -chdir=terraform/exercice-2 destroy
aws opensearch list-domain-names
```

**Preuve à insérer :** domaine supprimé. OpenSearch peut générer des coûts tant
qu'il reste actif.
