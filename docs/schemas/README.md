# Schémas pédagogiques

Les schémas sont conçus pour rester lisibles directement dans un README, un
fichier Markdown, un navigateur et un export PDF.

## Charte visuelle

- canevas uniforme de `960 × 300` pixels ;
- fond neutre, cartes blanches et bordures arrondies ;
- palette stable : gris pour le lab, bleu pour l’application et les données,
  violet pour l’orchestration, orange pour l’observation, vert pour le résultat ;
- flèches uniquement lorsqu’elles expliquent un flux réel ;
- pictogrammes vectoriels simples pour reconnaître les composants sans lire
  chaque ligne ;
- une idée principale et un résultat attendu par schéma ;
- texte court, contrasté et compréhensible sans légende externe ;
- bandeau inférieur réservé à la méthode, aux preuves ou au comportement testé ;
- aucun Mermaid, moteur externe, filtre, ombre ou illustration décorative.

Un schéma ne doit pas reproduire toute la documentation. Il doit permettre de
comprendre en quelques secondes **ce qui entre, ce qui se passe et ce qui doit
être obtenu ou prouvé**.

## Schémas du projet

- [Étape 0 — VM de lab](etape-0.svg) : installation, socle DevOps, accès et
  validation de l’environnement.
- [Vue d’ensemble](vue-ensemble.svg) : chaîne globale du lab aux trois exercices
  AWS.
- [Exercice 1](exercice-1.svg) : source Angular, Terraform, Ansible et résultat
  servi par NGINX sur EC2.
- [Exercice 2](exercice-2.svg) : logs, OpenSearch, trois visualisations et
  dashboard attendu.
- [Exercice 3](exercice-3.svg) : répartition HAProxy, état des backends, panne et
  reprise automatique.
- [Finalisation](finalisation/finalisation.svg) : collecte des preuves, contrôle
  des trois livrables, destruction des ressources et audit du nettoyage AWS.

Le README principal utilise ces six vues comme un parcours continu. Chaque
schéma introduit une étape ; les commandes et preuves détaillées restent dans
les guides correspondants.
