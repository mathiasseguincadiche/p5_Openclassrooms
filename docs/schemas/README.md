# Schémas pédagogiques

Les schémas de ce dossier sont des **SVG statiques versionnés** destinés au README et à la documentation Markdown.

Ils ne remplacent pas les guides détaillés : un schéma doit permettre de comprendre une idée en quelques secondes, tandis que le Markdown explique les commandes, risques et preuves.

## Les six vues officielles

| Schéma | Question à laquelle il répond |
| --- | --- |
| [Vue d'ensemble](vue-ensemble.svg) | comment les trois exercices dépendent-ils les uns des autres ? |
| [Étape 0](etape-0.svg) | que faut-il préparer avant le premier déploiement ? |
| [Exercice 1](exercice-1.svg) | comment Terraform, Ansible, NGINX et Angular s'enchaînent-ils ? |
| [Exercice 2](exercice-2.svg) | comment les logs deviennent-ils des données puis des visualisations ? |
| [Exercice 3](exercice-3.svg) | comment HAProxy répartit-il, détecte-t-il une panne et réintègre-t-il un backend ? |
| [Finalisation](finalisation/finalisation.svg) | comment passer des preuves au nettoyage complet ? |

## Vue d'ensemble

La vue globale doit rendre immédiatement visibles les deux dépendances essentielles :

```text
Exercice 1 → Exercice 2 : logs NGINX
Exercice 1 → Exercice 3 : réseau AWS
```

et la sortie :

```text
preuves → livrables → cleanup 3 → 2 → 1
```

## Règles techniques

Les SVG doivent rester :

- autonomes ;
- accessibles avec `title`, `desc` et `role=img` ;
- horizontaux et adaptés à GitHub ;
- légers ;
- sans script ;
- sans image encodée ;
- sans ressource externe ;
- sans filtre SVG complexe ;
- lisibles sans dépendance à une police fournie avec le dépôt.

Le texte est volontairement limité afin de laisser les détails à la documentation.

## Pourquoi des SVG versionnés ?

Ils fournissent :

- rendu déterministe dans GitHub ;
- contrôle des changements avec Git ;
- affichage net à différentes résolutions ;
- intégration directe dans Markdown ;
- contrôle automatique de l'accessibilité et du poids.

## Contrôle de non-régression

```bash
python3 scripts/tools/audit_non_regression.py --schemas-only
```

Le contrôle vérifie notamment :

- exactement six SVG ;
- poids maximal ;
- dimensions ;
- ratio horizontal ;
- accessibilité ;
- absence d'éléments interdits ;
- diversité des compositions ;
- présence des six schémas dans le README racine.

Une évolution graphique est donc possible, mais elle doit rester au service de la compréhension technique du projet.
