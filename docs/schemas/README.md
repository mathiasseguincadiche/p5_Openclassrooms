# Schémas de référence

Les six SVG de ce dossier constituent le **langage visuel officiel du P5**. Ils sont versionnés, statiques, accessibles et pensés pour être compris rapidement dans GitHub, dans le handbook de soutenance et dans la documentation technique.

Un schéma ne cherche pas à tout montrer. Il répond à **une question précise** et utilise le bon niveau de zoom :

- vue globale pour comprendre le projet en quelques secondes ;
- vue de déploiement pour comprendre où vivent les composants ;
- vue de flux pour comprendre ce qui circule ;
- vue dynamique pour comprendre ce qui se passe pendant une panne.

Le Markdown conserve ensuite les commandes, les explications, les risques et les preuves détaillées.

## Parcours visuel

| Schéma | Type de vue | Question principale |
| --- | --- | --- |
| [Vue d'ensemble](vue-ensemble.svg) | contexte projet | comment les trois exercices AWS s'emboîtent-ils ? |
| [Étape 0](etape-0.svg) | procédure | dans quel ordre qualifier et préparer le P5 avant Terraform ? |
| [Exercice 1](exercice-1.svg) | déploiement | comment Terraform, AWS, Ansible, NGINX et Angular s'articulent-ils ? |
| [Exercice 2](exercice-2.svg) | flux de données | comment un `access.log` devient-il un indicateur dans OpenSearch Dashboards ? |
| [Exercice 3](exercice-3.svg) | topologie + scénario dynamique | comment HAProxy répartit-il le trafic et réagit-il à la panne d'un backend ? |
| [Finalisation](finalisation/finalisation.svg) | procédure | comment valider les preuves, détruire dans le bon ordre et auditer AWS ? |

## Le fil conducteur du projet

![Architecture globale du P5](vue-ensemble.svg)

La lecture attendue est volontairement simple :

```text
Exercice 1
Construire et déployer
      │
      ├── access.log ─────► Exercice 2 : observer
      │
      └── VPC + subnets ──► Exercice 3 : répartir et résister
```

Les deux dépendances structurantes sont donc :

```text
Exercice 1 → Exercice 2 : access.log NGINX
Exercice 1 → Exercice 3 : VPC et subnets AWS
```

La fermeture conserve l'ordre inverse des dépendances :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

## Comment lire les schémas

Chaque schéma suit les mêmes règles de lecture.

### 1. Lire d'abord le titre

Le titre décrit la question principale du dessin. Si le titre parle de déploiement, on cherche **où sont les composants**. S'il parle de flux, on cherche **ce qui circule et dans quel ordre**.

### 2. Lire les grands conteneurs

Les cadres donnent le périmètre : AWS, VPC, subnet, service managé ou scénario de panne. Une boîte placée dans un conteneur signifie qu'elle appartient à ce périmètre.

### 3. Suivre les flèches

Une flèche représente une relation réelle : trafic HTTP, administration SSH, donnée de log, dépendance ou réutilisation. La proximité graphique seule n'a pas de signification.

### 4. Terminer par le résultat

Chaque exercice doit aboutir à un résultat démontrable :

| Exercice | Résultat concret |
| --- | --- |
| Exercice 1 | application Angular visible dans le navigateur |
| Exercice 2 | trois visualisations et un dashboard lisibles |
| Exercice 3 | alternance des backends et failover `2 → 1 → 2` |

## Langage visuel

Les couleurs servent de repère secondaire ; elles ne portent jamais seules une information essentielle.

| Couleur dominante | Sens |
| --- | --- |
| gris | contexte, Internet ou source neutre |
| bleu | infrastructure AWS et réseau |
| violet | configuration, orchestration ou transformation |
| orange | observabilité, données ou point d'attention |
| vert | service disponible, résultat valide ou backend actif |
| rouge | panne contrôlée ou action destructive |

Les conventions de forme restent stables :

```text
grand cadre        = périmètre ou couche
boîte              = composant ou ressource
flèche pleine      = flux ou dépendance active
flèche pointillée  = administration ou réutilisation logique
texte sur flèche   = donnée ou relation transportée
```

## Règles pédagogiques de conception

Un schéma du P5 doit respecter les règles suivantes :

1. répondre à une question identifiable ;
2. garder un seul niveau d'abstraction principal ;
3. éviter de mélanger topologie, procédure et dépannage dans le même dessin ;
4. nommer les relations importantes ;
5. afficher les technologies utiles à la compréhension ;
6. limiter le texte pour rester lisible à l'écran ;
7. être compréhensible même sans distinguer les couleurs ;
8. être accompagné, dans le Markdown, d'une courte explication de lecture.

## Règles techniques

Les SVG restent :

- autonomes ;
- accessibles avec `title`, `desc`, `role="img"` et `aria-labelledby` ;
- horizontaux et adaptés à GitHub ;
- inférieurs à la limite de poids du contrat de non-régression ;
- sans script, image encodée, ressource externe ou filtre SVG complexe ;
- lisibles avec les polices système ;
- suffisamment sobres pour que le détail reste dans le Markdown.

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

Une évolution graphique est acceptable lorsqu'elle **réduit l'effort nécessaire pour comprendre** sans modifier le contrat fonctionnel du P5.
