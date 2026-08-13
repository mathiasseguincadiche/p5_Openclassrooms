# P5 — idempotence et observabilité V10

La V10 ne remplace pas les mécanismes de convergence existants du P5. Elle les rend plus explicites, observables et vérifiables lors des réexécutions.

## Source de vérité

Le P5 décide à partir des faits actuels : versions installées, configuration locale, identité AWS active, états Terraform, inventaire Ansible, artefacts et retours des commandes de validation.

Les anciens logs, marqueurs et preuves servent à l’historique ; ils ne peuvent pas déclarer une machine conforme à la place d’un contrôle réel.

## État global

```bash
bash scripts/commands/p5.sh status
```

L’inspection reste non mutante et classe le contexte :

- `FIRST_RUN` : aucune préparation persistante exploitable détectée ;
- `PARTIAL` : une partie du socle ou du lab existe, mais des écarts restent présents ;
- `READY_CANDIDATE` : outils, configuration, paire SSH et identité AWS sont actuellement vérifiables.

`READY_CANDIDATE` n’est pas une promesse que toute infrastructure AWS est déployée : chaque exercice continue à utiliser son propre `terraform plan` et ses validations réelles.

## Convergence

```bash
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh run 1
bash scripts/commands/p5.sh run 2
bash scripts/commands/p5.sh run 3
```

La règle reste :

```text
observer
  ↓
comparer
  ↓
aucun delta ? ── oui ──> DÉJÀ CONFORME / aucune mutation
  │
  non
  ↓
corriger uniquement le delta
  ↓
revalider
  ↓
journaliser + produire les preuves
```

Terraform conserve le contrat `plan -detailed-exitcode`; Ansible conserve sa preuve de seconde exécution sans changement ; les fichiers générés ne sont réécrits que lorsqu’ils divergent.

## Informations opérateur

Une valeur non détectable ou authoritative n’est jamais inventée. Le terminal indique :

- ce qui manque ;
- pourquoi la donnée est nécessaire ;
- le format attendu ;
- un exemple ;
- la manière exacte de la fournir.

En non-interactif, une donnée obligatoire absente provoque un arrêt explicite.

## Journaux

Voir `logs/README.md`.

Chaque run conserve ses étapes et son résumé, tandis que `logs/scripts/` fournit une lecture persistante par script. Les sorties et aperçus de commandes passent par la redaction commune avant journalisation.

## Contrat de non-régression

Le test `scripts/tests/test-convergence-contract.sh` verrouille notamment :

- la deuxième exécution sans réécriture des `terraform.tfvars` déjà conformes ;
- la correction ciblée d’une dérive de permissions ;
- les journaux et preuves numérotés ;
- le journal persistant par script ;
- le résumé factuel du run ;
- la redaction des arguments et sorties sensibles ;
- la présence des trois classifications machine-first.

Les autres contrats existants (opérateur, preuves, AWS, orchestrateur, documentation et runtime Ubuntu 26.04) restent inchangés et doivent tous rester verts avant fusion.
