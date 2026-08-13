# P5 V11 — Notes d'implémentation

## Objectif

V11 améliore l'ergonomie et la documentation sans refondre la base V10.

## Périmètre modifié

- `scripts/commands/p5.sh` : Control Center enrichi ;
- `scripts/tests/test-p5-orchestrator.sh` : contrat du menu et des nouvelles routes ;
- `README.md` : entrée débutant et navigation ;
- `docs/README.md` : portail documentaire par besoin ;
- `docs/RUNBOOK_EXECUTION_GUIDEE.md` : risques, reprise et diagnostic ;
- `docs/CENTRE_DE_COMMANDE.md` : guide complet du menu ;
- `scripts/README.md` : référence synchronisée du Control Center.

## Garanties de non-refonte

V11 ne modifie pas :

- `terraform/` ;
- `ansible/` ;
- `application/` ;
- `aws/` ;
- `environment/versions.env` ;
- `scripts/lib/p5-runtime.sh` ;
- les scripts spécialisés de déploiement ;
- les workflows GitHub Actions.

Les fonctions existantes `run_inspect`, `run_prepare`, `run_status`, `run_ex1`,
`run_ex2`, `run_ex3`, `run_all`, `run_finalize` et `run_cleanup` restent le moteur
métier. V11 ajoute une façade opérateur et expose `run_diagnostics` comme commande
CLI officielle.

## Sécurité

- `0` est réservé à **Quitter** ;
- le nettoyage AWS passe en option `15` ;
- la confirmation forte `DETRUIRE` n'est pas contournée ;
- `--yes` ne contourne toujours pas les preuves humaines ;
- le menu affiche le risque de mutation et de coût avant les actions principales.

## Validation

La CI existante est réutilisée sans nouveau workflow. Le test
`scripts/tests/test-p5-orchestrator.sh` vérifie le contrat V11 sans créer de
ressource AWS.
