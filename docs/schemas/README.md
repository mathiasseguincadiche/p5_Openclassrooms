# Schémas de référence

Les six SVG de ce dossier constituent le **langage visuel officiel du P5**. Leur priorité est la compréhension : un lecteur doit pouvoir saisir l'idée principale d'un schéma en quelques secondes, puis utiliser le Markdown pour approfondir.

## Principe directeur

```text
un schéma = une idée principale
```

Le schéma montre le **modèle mental**. Le texte explique ensuite les paramètres, commandes, versions, risques et preuves.

Un détail technique ne doit apparaître dans l'image que s'il aide réellement à comprendre le fonctionnement.

## Parcours visuel

| Schéma | Question principale |
| --- | --- |
| [Vue d'ensemble](vue-ensemble.svg) | comment les trois exercices s'enchaînent-ils ? |
| [Étape 0](etape-0.svg) | comment préparer le lab avant Terraform ? |
| [Exercice 1](exercice-1.svg) | qui crée, qui configure et qui sert l'application ? |
| [Exercice 2](exercice-2.svg) | comment un log NGINX devient-il un graphique ? |
| [Exercice 3](exercice-3.svg) | comment HAProxy répartit-il le trafic et maintient-il le service pendant une panne ? |
| [Finalisation](finalisation/finalisation.svg) | comment terminer et nettoyer proprement le lab ? |

## Lecture globale

```text
EXERCICE 1
construire + déployer
      │
      ├── logs ─────────► EXERCICE 2 : observer
      │
      └── réseau AWS ───► EXERCICE 3 : répartir + résister
```

À retenir :

```text
Ex. 1 livre l'application
Ex. 2 observe son activité
Ex. 3 démontre la disponibilité
```

## Règles de simplicité

Un schéma de soutenance doit :

1. présenter au maximum quelques composants principaux ;
2. utiliser des mots courts dans les boîtes ;
3. garder les détails techniques dans un encadré secondaire ou dans le Markdown ;
4. suivre une lecture évidente, généralement de gauche à droite ;
5. nommer les flèches seulement lorsqu'un verbe aide la compréhension : `crée`, `configure`, `sert`, `envoie`, `répartit` ;
6. terminer par une idée simple à retenir ;
7. rester compréhensible sans connaître Terraform, OpenSearch ou HAProxy à l'avance.

## Trois types de schémas

### Chaîne de responsabilités

Utilisée pour l'exercice 1 :

```text
Terraform → AWS → Ansible → NGINX → Angular
```

La question est : **qui fait quoi ?**

### Flux de données

Utilisé pour l'exercice 2 :

```text
access.log → parser → OpenSearch → Dashboard
```

La question est : **que devient la donnée ?**

### Topologie + scénario de panne

Utilisée pour l'exercice 3 :

```text
Client → HAProxy → 2 backends

2 disponibles → 1 tombe → service continue → 2 disponibles
```

La question est : **comment le service reste-t-il disponible ?**

## Langage visuel

Les couleurs sont peu nombreuses et restent secondaires par rapport au texte :

| Couleur | Usage principal |
| --- | --- |
| bleu | infrastructure AWS ou source technique |
| orange | configuration, transformation ou observabilité |
| vert | application, résultat ou service disponible |
| violet | HAProxy / répartition de charge |
| rouge | panne contrôlée uniquement |
| gris | contexte neutre |

La couleur n'est jamais la seule information permettant de comprendre un état.

## Comment accompagner un schéma dans le Markdown

Chaque grand schéma doit être suivi de trois blocs courts :

```text
COMMENT LE LIRE
→ ordre de lecture en 3 à 5 étapes

À RETENIR
→ une phrase simple

CE QUE JE DÉMONTRE
→ preuve terminal ou navigateur
```

Le handbook de soutenance applique cette structure afin que le dessin serve réellement de support oral.

## Ce qui doit rester hors du schéma principal

Sauf nécessité pédagogique, ne pas surcharger une image avec :

- tous les noms de ressources Terraform ;
- toutes les options de sécurité ;
- toutes les versions de composants ;
- toutes les commandes ;
- les chemins complets de fichiers ;
- les détails de CI ;
- l'environnement Windows/WSL2 lorsque le sujet est l'architecture AWS du projet.

Ces informations restent disponibles dans les documents techniques et dans le code.

## Règles techniques

Les SVG restent :

- autonomes ;
- accessibles avec `title`, `desc`, `role="img"` et `aria-labelledby` ;
- horizontaux et adaptés à GitHub ;
- inférieurs à la limite de poids du contrat de non-régression ;
- sans script, image encodée, ressource externe ou filtre SVG complexe ;
- lisibles avec les polices système ;
- sans Mermaid dans le contrat actuel du dépôt.

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

Une évolution graphique est réussie lorsqu'elle **réduit le temps nécessaire pour comprendre** sans modifier le fonctionnement du P5.
