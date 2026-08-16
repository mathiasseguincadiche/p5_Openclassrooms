# Schémas de référence

Les six SVG de ce dossier forment le parcours visuel officiel du P5. Ils sont versionnés, statiques,
accessibles et conçus pour être lus rapidement dans GitHub et dans la documentation Markdown.

Un schéma répond à une question d'architecture ou d'exploitation. Le Markdown conserve les commandes,
les risques, les variantes et les preuves détaillées.

## Parcours visuel

| Schéma | Question principale |
| --- | --- |
| [Vue d'ensemble](vue-ensemble.svg) | où s'exécute le plan de contrôle et comment les trois exercices AWS dépendent-ils les uns des autres ? |
| [Étape 0](etape-0.svg) | dans quel ordre qualifier et préparer le P5 avant Terraform ? |
| [Exercice 1](exercice-1.svg) | comment les flux Terraform et Angular convergent-ils dans Ansible sans confondre infrastructure et configuration ? |
| [Exercice 2](exercice-2.svg) | comment le sample et le vrai log NGINX deviennent-ils des données OpenSearch puis des preuves visuelles ? |
| [Exercice 3](exercice-3.svg) | comment HAProxy exploite-t-il le réseau de l'exercice 1 et réagit-il à une panne backend ? |
| [Finalisation](finalisation/finalisation.svg) | comment valider les preuves, détruire dans le bon ordre et auditer la fermeture AWS ? |

## Lecture séquentielle

```text
Étape 0
  ↓
Exercice 1
  ├── access.log ──► Exercice 2
  └── VPC/subnets ─► Exercice 3
  ↓
Finalisation
```

Les deux dépendances structurantes sont donc :

```text
Exercice 1 → Exercice 2 : access.log NGINX
Exercice 1 → Exercice 3 : VPC et subnets AWS
```

La fermeture conserve l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

## Langage visuel

Les schémas utilisent les mêmes conventions :

- gris : plateforme, contexte ou source neutre ;
- bleu : infrastructure, plan de contrôle ou flux technique principal ;
- violet : configuration, transformation ou orchestration ;
- orange : observabilité, livrables ou point d'attention ;
- vert : résultat conforme ou service disponible ;
- rouge : panne contrôlée ou destruction ;
- flèches : dépendance ou flux réel, jamais simple proximité graphique.

La couleur complète le texte mais ne porte jamais seule une information essentielle.

## Règles techniques

Les SVG restent :

- autonomes ;
- accessibles avec `title`, `desc`, `role="img"` et `aria-labelledby` ;
- horizontaux et adaptés à GitHub ;
- inférieurs à la limite de poids du contrat de non-régression ;
- sans script, image encodée, ressource externe ou filtre SVG complexe ;
- lisibles avec les polices système ;
- suffisamment sobres pour que le texte détaillé reste dans le Markdown.

## Contrôle de non-régression

```bash
python3 scripts/tools/audit_non_regression.py --schemas-only
```

Le contrôle vérifie notamment :

- exactement six SVG ;
- dimensions et ratio horizontal ;
- poids maximal ;
- accessibilité ;
- nombre raisonnable de blocs texte ;
- absence d'éléments interdits ;
- plusieurs compositions adaptées aux sujets ;
- présence des six schémas dans le README racine.

Une évolution graphique est acceptable lorsqu'elle améliore la compréhension sans modifier le contrat
fonctionnel du P5.
