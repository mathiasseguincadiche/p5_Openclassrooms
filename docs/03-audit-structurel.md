# 03 — Audit structurel et décisions de nettoyage

## Dysfonctionnements constatés

- Cinq exercices génériques étaient présentés alors que le P5 n’en contient que
  trois.
- Des cours et ressources étaient confondus avec des exercices évalués.
- Kubernetes, Prometheus, Grafana, Vault et de nombreux templates généralistes
  occupaient le parcours principal sans répondre aux consignes.
- Plusieurs documents utilisaient Mermaid malgré le besoin de schémas simples.
- Le playbook Ansible pointait vers des dossiers renommés et ne pouvait plus
  copier l’application.
- Des scripts calculaient une mauvaise racine du dépôt.
- Les phases 4 et 5 pouvaient être prises pour des exercices supplémentaires.
- Les automatismes de déploiement et de dashboard masquaient les commandes que
  le débutant doit comprendre.
- Le nettoyage AWS détruisait l’exercice 1 avant l’exercice 3, alors que le
  troisième réutilise le réseau du premier.

## Corrections appliquées

- Trois fiches seulement, calquées sur les trois exercices officiels.
- Séparation nette entre exercices, ressources, livrables et suivi.
- Suppression des templates et guides hors périmètre.
- Quatre schémas SVG en remplacement de Mermaid.
- Restauration des chemins `angular-app` et `nginx-angular.conf`.
- Une seule cible Ansible dans l’exercice 1, conformément au besoin minimal.
- Suppression des lanceurs automatiques volumineux et des bibliothèques Bash
  historiques.
- Conservation de scripts courts pour vérifier, préparer les livrables,
  nettoyer le poste et détruire AWS.
- Destruction Terraform dans l’ordre 3 → 2 → 1.
- Matrice explicite consigne → fichier → preuve.
- Un seul parcours technique cohérent : AWS pour les trois exercices ; les
  variantes locales restent uniquement signalées comme options officielles.

## Principe retenu

Le dépôt doit répondre immédiatement à trois questions :

1. **Que demande OpenClassrooms ?**
2. **Où se trouve l’implémentation ?**
3. **Quelle preuve réelle faut-il produire ?**

Tout contenu qui ne répond pas à l’une de ces questions est retiré du parcours
principal.
