# Exercice 2 — Monitoring et logging avec ELK / OpenSearch

![Flux de l'exercice 2](../schemas/exercice-2.svg)

## Objectif officiel

Démarrer un environnement de logs, importer un échantillon NGINX, explorer les
données puis construire un dashboard avec trois visualisations précises.

## Option retenue : Amazon OpenSearch sur AWS

OpenClassrooms autorise une stack ELK locale ou un service Cloud. Pour cette
réalisation, le choix validé est **Amazon OpenSearch** avec OpenSearch
Dashboards. L’infrastructure se trouve dans `terraform/exercice-2/`. Le mode
Docker Compose local n’est pas implémenté dans ce dépôt.

Le terme « Kibana » employé dans les consignes correspond à OpenSearch
Dashboards dans le parcours AWS retenu.

## Étapes attendues

1. démarrer l’environnement ;
2. importer `nginx-access.log` ;
3. créer l’index ou le motif `nginx-access` ;
4. vérifier les champs dans Discover ;
5. créer les trois visualisations ;
6. assembler le dashboard ;
7. produire quatre captures lisibles.

## Trois visualisations obligatoires

1. **Donut** : répartition des verbes HTTP (`GET`, `POST`, etc.).
2. **Histogramme** : quantité cumulée de données envoyées par tranches de
   12 heures.
3. **Histogramme cumulé ou empilé** : top 5 des requêtes HTTP par tranches de
   12 heures.

Une courbe ou une heatmap peut servir à expérimenter, mais ne remplace aucun de
ces trois graphiques.

## Implémentation du dépôt

```text
terraform/exercice-2/
├── main.tf
├── variables.tf
├── outputs.tf
└── samples/nginx-access.log.sample
```

Les visualisations ne sont pas automatisées. Leur création manuelle permet de
comprendre les champs, les agrégations et la plage temporelle demandés.

## Commandes Cloud

```bash
cp terraform/exercice-2/terraform.tfvars.example \
  terraform/exercice-2/terraform.tfvars
terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 plan
terraform -chdir=terraform/exercice-2 apply
terraform -chdir=terraform/exercice-2 output -raw opensearch_dashboards_endpoint
```

Amazon OpenSearch peut être coûteux. Après les captures :

```bash
terraform -chdir=terraform/exercice-2 destroy
```

## Livrables et preuves

- capture du dashboard complet avec les trois graphiques ;
- capture lisible du donut ;
- capture lisible de l’histogramme des octets par 12 heures ;
- capture lisible du top 5 des requêtes par 12 heures ;
- preuve de l’index et des données dans Discover ;
- aucune adresse, clé ou identité AWS sensible visible.

Gabarit :
[`SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_2_dashboard_kibana_02082026.md).
