# Contrat des preuves automatiques P5

## Objectif

Une étape ne doit pas être considérée comme validée uniquement parce que le
terminal a affiché `OK`. L'exécution doit laisser une preuve locale identifiable,
horodatée et reliée à la commande réellement exécutée.

Le contrat est :

```text
commande réelle
    ↓
log complet de l'étape
    ↓
verdict
    ↓
copie privée de preuve
    ↓
SHA-256 + manifeste horodaté
```

Les preuves runtime restent privées et sont ignorées par Git.

## Preuve automatique de chaque étape `p5.sh`

Pour chaque appel à `p5_run_step` ou `p5_run_step_allow`, le moteur conserve :

- le log complet de l'étape ;
- son numéro ;
- sa clé technique ;
- son libellé ;
- le code retour ;
- le verdict `VALIDE` ou `ECHEC` ;
- la durée ;
- le SHA-256 du fichier de preuve.

Arborescence :

```text
proofs/runtime/steps/<UTC>/
├── manifest.tsv
├── 01-....log
├── 02-....log
└── ...
```

Le manifeste permet de relier chaque verdict à un fichier précis et de vérifier
que la preuve n'a pas été modifiée après sa collecte.

## Preuves d'état AWS

Les logs Terraform prouvent le plan, l'application et l'absence de delta. Pour
éviter de confondre « Terraform a terminé » avec « la ressource AWS est réellement
opérationnelle », le parcours ajoute une vérification AWS explicite.

Commande spécialisée :

```bash
bash scripts/commands/verify-aws-exercise-state.sh --exercise 1
bash scripts/commands/verify-aws-exercise-state.sh --exercise 2
bash scripts/commands/verify-aws-exercise-state.sh --exercise 3
```

Dans le parcours orchestré, ces preuves sont déclenchées automatiquement à la fin
des validations techniques correspondantes.

### Exercice 1

La preuve vérifie depuis AWS que l'instance correspondant à l'IP Terraform est
réellement en état :

```text
running
```

Verdict attendu :

```text
ÉTAT AWS EXERCICE 1 VALIDÉ — EC2 RUNNING
```

Cette preuve complète :

- le plan Terraform ;
- l'apply ;
- le post-plan sans delta ;
- SSH/cloud-init ;
- le ping Ansible ;
- l'idempotence ;
- HTTP/Angular/NGINX.

### Exercice 2

La preuve interroge Amazon OpenSearch Service et exige un domaine :

- créé ;
- non supprimé ;
- hors phase de traitement ;
- hors phase d'upgrade.

Verdict :

```text
ÉTAT AWS EXERCICE 2 VALIDÉ — OPENSEARCH ACTIF
```

Les mappings, documents, agrégations et captures Dashboards restent des preuves
complémentaires indispensables.

### Exercice 3

La preuve vérifie que :

- l'EC2 HAProxy est `running` ;
- le backend 1 est `running` ;
- le backend 2 est `running`.

Verdict :

```text
ÉTAT AWS EXERCICE 3 VALIDÉ — 3 EC2 RUNNING
```

Le round-robin, la panne et la réintégration restent ensuite les preuves
fonctionnelles de haute disponibilité.

## Une preuve ne remplace pas une autre

Exemple exercice 1 :

```text
EC2 running                 → preuve infrastructure AWS
SSH prêt                    → preuve de connectivité
Ansible ping OK             → preuve de gestion par Ansible
changed=0                   → preuve d'idempotence
HTTP 200                    → preuve de service
Angular + SPA + headers     → preuve applicative
access.log réel             → preuve d'observabilité
```

Le projet conserve ces niveaux séparément afin qu'une validation superficielle
ne puisse pas masquer une panne à une couche différente.

## Échec

Une étape en échec produit également une copie de son log avec le statut
`ECHEC`. Ce fichier n'est pas une preuve de réussite : il sert au diagnostic et
permet de retrouver exactement l'état qui a provoqué l'arrêt.

## Sécurité

`proofs/runtime/` est privé par défaut. Il peut contenir des IP, identifiants de
ressources, chemins ou autres données utiles au diagnostic.

Avant toute publication :

1. relire la preuve ;
2. anonymiser les informations inutiles ;
3. ne jamais publier de credentials, token, clé privée, tfvars ou state ;
4. ne copier dans le livrable que l'extrait nécessaire à la démonstration.

## Test de non-régression

Le contrat est vérifié par :

```bash
bash scripts/tests/test-proof-contract.sh
```

La CI doit échouer si :

- une étape ne crée plus sa preuve ;
- le manifeste disparaît ;
- le SHA-256 n'est plus produit ;
- les hooks AWS des trois exercices disparaissent ;
- les verdicts AWS ne sont plus présents.
