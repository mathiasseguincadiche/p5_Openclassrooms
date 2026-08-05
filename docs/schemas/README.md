# Schémas pédagogiques

Les schémas sont conçus pour rester lisibles directement dans un README, un
fichier Markdown, un navigateur et un export PDF.

## Principe directeur

La cohérence visuelle ne signifie pas que tous les schémas doivent partager le
même gabarit. Chaque vue adopte la composition la plus adaptée à ce qu’elle doit
faire comprendre, tout en conservant une grammaire commune.

### Repères communs

- même typographie système et même niveau de contraste ;
- mêmes couleurs sémantiques : gris pour le lab, bleu pour l’application et les
  données, violet pour l’orchestration, orange pour l’observation, vert pour un
  résultat valide et rouge pour une interruption ou une destruction ;
- flèches réservées aux flux ou transitions réels ;
- titres courts, libellés autonomes et descriptions accessibles dans chaque SVG ;
- aucun Mermaid, moteur externe, filtre, ombre ou illustration décorative ;
- lisibilité préservée dans GitHub, un navigateur et un export PDF.

### Identité de chaque schéma

| Schéma | Composition choisie | Message principal |
| --- | --- | --- |
| [Vue d’ensemble](vue-ensemble.svg) | carte du parcours local → AWS → finalisation | comprendre la chaîne de bout en bout |
| [Étape 0](etape-0.svg) | fondations empilées et porte de validation | vérifier que le socle est prêt avant Terraform |
| [Exercice 1](exercice-1.svg) | couloirs local, AWS et validation | distinguer build, provisionnement, configuration et contrôle |
| [Exercice 2](exercice-2.svg) | pipeline de données terminé par un dashboard | suivre la transformation des logs en visualisations |
| [Exercice 3](exercice-3.svg) | topologie réseau et chronologie des états | montrer la répartition, la panne et la reprise |
| [Finalisation](finalisation/finalisation.svg) | procédure de sortie et audit | prouver, détruire puis confirmer l’absence de résidu |

Un schéma ne reproduit pas toute la documentation. Il doit permettre de
comprendre en quelques secondes le système, la transformation ou le
comportement qu’il illustre.

Le README principal utilise ces six vues comme un parcours continu. Les
commandes, preuves détaillées et précautions restent dans les guides
correspondants.
