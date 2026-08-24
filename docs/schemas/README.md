# Schémas du projet P5

Ce dossier distingue deux niveaux de schémas :

- **les schémas officiels de soutenance en SVG vectoriel haute qualité**, utilisés dans le runbook LIVE et la documentation principale ;
- **les SVG techniques de référence**, conservés pour les explications plus détaillées et les contrôles de cohérence.

## Schémas officiels de soutenance — haute qualité

Les quatre visuels officiels sont regroupés dans [`officiels/`](officiels/) et disposent désormais d'un **master SVG vectoriel**. Ils peuvent être agrandis, projetés ou exportés en PDF sans pixellisation.

| Vue | Master HQ | Compatibilité raster | Fonction pendant l'oral |
| --- | --- | --- | --- |
| projet | [`vue-ensemble.svg`](officiels/vue-ensemble.svg) | [`vue-ensemble.webp`](officiels/vue-ensemble.webp) | comprendre en quelques secondes comment les trois exercices s'enchaînent |
| Exercice 1 | [`exercice-1.svg`](officiels/exercice-1.svg) | [`exercice-1.webp`](officiels/exercice-1.webp) | comprendre le socle AWS, le VPC, les subnets, l'EC2 et le rôle de Terraform, Ansible, NGINX et Angular |
| Exercice 2 | [`exercice-2.svg`](officiels/exercice-2.svg) | [`exercice-2.webp`](officiels/exercice-2.webp) | suivre le flux `access.log → parsing → Bulk API → OpenSearch → Dashboards` et les trois visualisations |
| Exercice 3 | [`exercice-3.svg`](officiels/exercice-3.svg) | [`exercice-3.webp`](officiels/exercice-3.webp) | comprendre HAProxy, les deux backends, le round-robin et le scénario `2 → 1 → 2` |

Le document canonique qui les utilise est [`../RUNBOOK_SOUTENANCE.md`](../RUNBOOK_SOUTENANCE.md). La documentation principale les référence également depuis [`../README.md`](../README.md).

Les fichiers WebP historiques sont conservés uniquement comme **fallback raster**. Pour toute nouvelle intégration, export PDF ou présentation, utiliser les SVG officiels.

### Principe graphique

La vue d'ensemble reste volontairement légère : elle raconte **la progression du projet**, sans répéter les détails présents dans les trois schémas d'exercice.

```text
Exercice 1 : construire et déployer
        │
        ├── access.log ─────► Exercice 2 : observer et analyser
        │
        └── VPC + subnets ──► Exercice 3 : répartir et résister
```

Les schémas détaillés ajoutent uniquement les informations nécessaires à la compréhension : rôle des outils, flux principal, résultat attendu et dépendances entre exercices.

## SVG techniques de référence

Les SVG techniques existants restent disponibles :

- [`vue-ensemble.svg`](vue-ensemble.svg) ;
- [`exercice-1.svg`](exercice-1.svg) ;
- [`exercice-2.svg`](exercice-2.svg) ;
- [`exercice-3.svg`](exercice-3.svg) ;
- [`etape-0.svg`](etape-0.svg) ;
- [`finalisation/finalisation.svg`](finalisation/finalisation.svg).

Ils servent aux explications techniques et aux contrôles de cohérence, mais ne sont pas les visuels principaux du runbook LIVE.

## Rappels techniques

### Exercice 1

```text
Terraform → provisionne l'infrastructure
AWS       → héberge les ressources
VPC       → réseau privé et isolé du projet
subnets   → organisent le placement des ressources
EC2       → machine virtuelle p5-web
Ansible   → configure la machine et déploie
NGINX     → sert l'application en HTTP
Angular   → application web
```

### Exercice 2

```text
access.log            → log réel issu de NGINX
sample reproductible  → jeu de données de démonstration
parsing / typage      → structure les champs
Bulk API              → envoie les documents
Amazon OpenSearch     → indexe et agrège
OpenSearch Dashboards → affiche les visualisations
```

### Exercice 3

```text
HAProxy            → répartit la charge
roundrobin         → alterne les requêtes
health check GET / → vérifie la disponibilité
fall 3             → retire après 3 échecs
rise 2             → réintègre après 2 succès
hello-1 / hello-2  → backends applicatifs
```

## Contrôle des SVG techniques

```bash
python3 scripts/tools/audit_non_regression.py --schemas-only
```
