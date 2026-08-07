# Modèle de journal de session du P5

Ce document est un support facultatif de prise de notes. Il ne représente pas l’état d’avancement officiel du dépôt et ne remplace aucune preuve demandée dans les trois livrables.

Pour une utilisation réelle, copier ce modèle dans un emplacement local ignoré par Git, par exemple `proofs/runtime/journal-de-session.md`.

## Tableau de suivi

| Date UTC | Exercice | Action exécutée | Résultat observé | Preuve conservée | Suite |
| --- | --- | --- | --- | --- | --- |
| Exemple | 1 | `terraform plan` | Plan relu sans ressource inattendue | `proofs/runtime/exercice-1/plan.txt` | Exécuter `apply` après validation |

Supprimer la ligne d’exemple puis consigner uniquement des exécutions réelles.

## Points à préparer avec le mentor

- difficultés rencontrées et diagnostic réalisé ;
- décisions techniques prises ;
- contrôles et tests effectivement exécutés ;
- preuves encore manquantes ;
- ressources AWS créées puis détruites ;
- actions à mener avant la remise.

## Règles

- ne jamais copier de clé, jeton, mot de passe ou identifiant sensible ;
- anonymiser les adresses et identifiants lorsque leur valeur exacte n’est pas nécessaire ;
- distinguer une commande prévue d’une commande réellement exécutée ;
- associer chaque conclusion à une sortie ou une capture vérifiable.
