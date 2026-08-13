# Journaux P5 — contrat d’observabilité

Ce dossier est créé et alimenté au runtime. Les fichiers `*.log` sont volontairement ignorés par Git ; ce `README.md` documente leur contrat.

## Principe

La source de vérité reste **l’état observé de la VM, d’AWS, de Terraform, d’Ansible et des artefacts**. Un ancien journal ne rend jamais une étape conforme à lui seul.

À chaque exécution orchestrée :

1. le P5 observe l’état réel ;
2. il calcule le delta ;
3. il n’applique que ce qui est nécessaire ;
4. il revalide le résultat ;
5. il journalise les faits et le verdict.

## Structure

```text
logs/
├── README.md
├── <RunId>/
│   ├── <session>.log
│   ├── 01-<étape>.log
│   ├── 02-<étape>.log
│   ├── events.log
│   └── summary.log
└── scripts/
    ├── commands/
    │   └── <script>.log
    ├── tools/
    │   └── <outil>.log
    └── external/
        └── <étape>.log
```

- `logs/<RunId>/` conserve la chronologie d’une exécution précise.
- `logs/scripts/...` regroupe l’historique lisible par script réel.
- `events.log` enregistre les résultats d’étape (`VALIDE` / `ECHEC`) avec code retour et durée.
- `summary.log` donne le bilan factuel du run courant.
- `proofs/runtime/steps/<RunId>/` reste le mécanisme de preuve horodatée et SHA-256 déjà utilisé par le projet.

## Secrets

Avant écriture dans les journaux d’étape, les sorties passent par le filtre commun de redaction. Les paramètres dont le nom évoque un mot de passe, secret, token, credential ou clé API sont masqués dans l’aperçu de commande.

Les motifs de secrets connus (AWS, OpenRouter, GitHub/GitLab, Bearer) sont remplacés par :

```text
<REDACTED>
```

Un secret ne doit jamais être ajouté volontairement au dépôt ou utilisé comme donnée de diagnostic.

## Réexécution

Une deuxième exécution ne doit pas réécrire ou recréer ce qui est déjà conforme. Les mécanismes existants de convergence (Terraform plan, Ansible idempotence, synchronisation de fichiers, garde-fous AWS) restent responsables de cette décision.

Les journaux expliquent **ce qui a réellement été observé et exécuté** ; ils ne remplacent jamais les contrôles live.
