# Preuves d’exécution et diagnostics du P5

Ce dossier documente la gestion des **preuves techniques locales**. Les fichiers
réels sont écrits sous `proofs/runtime/`, volontairement ignoré par Git.

Le contrat détaillé « une étape validée = une preuve identifiable » est décrit
dans [`docs/contrat-preuves-automatiques.md`](../docs/contrat-preuves-automatiques.md).

## Principe

```text
Exécution réelle
    ↓
proofs/runtime/         # privé par défaut
    ↓
sélection + relecture
    ↓
anonymisation
    ↓
docs/livrables/        # preuve contextualisée
```

Une sortie runtime brute n’est pas automatiquement publiable.

## Arborescence locale

```text
proofs/
├── README.md
└── runtime/                     # créé localement, ignoré par Git
    ├── steps/<UTC>/             # preuve de chaque étape + manifest.tsv
    ├── diagnostics/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

Chaque étape exécutée via l'orchestrateur conserve une copie privée de son log
avec verdict, code retour, durée et SHA-256 dans `steps/<UTC>/manifest.tsv`.

## Diagnostic global

Commande standard :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Avec OpenSearch local :

```bash
bash scripts/commands/collect-diagnostics.sh --complet
```

Après les exercices, pour joindre aussi les preuves runtime existantes :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Le script produit :

```text
proofs/runtime/diagnostics/
├── p5-diagnostic-<UTC>/
│   ├── diagnostic-complet.log
│   ├── diagnostic-partage.log
│   ├── resume.txt
│   └── manifest-preuves.txt
└── p5-diagnostic-<UTC>.tar.gz
```

### Journal complet

`diagnostic-complet.log` reste local avec des permissions restrictives.

Il **n’est jamais placé dans l’archive partageable**.

### Journal nettoyé

Le collecteur tente de masquer notamment :

- clés d’accès AWS détectables ;
- secrets AWS CLI ;
- jetons de session ;
- en-têtes Authorization ;
- blocs de clé privée.

Cela réduit le risque mais ne remplace pas une relecture humaine.

## Exercice 1

Commandes principales :

```bash
./scripts/commands/verify-angular-deployment.sh
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh
```

Preuves typiques :

- état AWS réel de l'EC2 Angular/NGINX : `running` ;
- en-têtes HTTP ;
- page Angular reçue ;
- résultat du fallback SPA ;
- journal de vérification ;
- trafic généré ;
- log NGINX réel collecté.

Verdicts utiles :

```text
ÉTAT AWS EXERCICE 1 VALIDÉ — EC2 RUNNING
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
TRAFIC NGINX GÉNÉRÉ
LOGS NGINX RÉELS COLLECTÉS
```

Les preuves Terraform et Ansible sont également conservées automatiquement par
l'orchestrateur : plan, apply ou absence de delta, outputs, ping, playbook et
idempotence.

## Exercice 2

Commandes :

```bash
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/verify-opensearch-data.sh
```

Preuves techniques typiques :

- état Amazon OpenSearch créé, actif et stable ;
- réponse du template ;
- réponse Bulk ;
- comptage des documents ;
- mapping ;
- agrégations ;
- journaux d’import et de vérification.

Verdicts :

```text
ÉTAT AWS EXERCICE 2 VALIDÉ — OPENSEARCH ACTIF
IMPORT OPENSEARCH RÉUSSI
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

Les captures de Discover, des trois visualisations et du dashboard doivent être
produites manuellement dans OpenSearch Dashboards.

## Exercice 3

Commandes :

```bash
./scripts/commands/test-haproxy-roundrobin.sh
./scripts/commands/test-haproxy-failover.sh
./scripts/commands/test-haproxy-failover.sh --apply
```

Preuves :

- état AWS réel de HAProxy et des deux backends : trois EC2 `running` ;
- deux backends en round-robin ;
- état avant la panne ;
- un backend pendant la panne ;
- continuité HTTP ;
- retour des deux backends après reprise.

Verdicts :

```text
ÉTAT AWS EXERCICE 3 VALIDÉ — 3 EC2 RUNNING
ROUND-ROBIN OPÉRATIONNEL
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## États de publication

| Type | Versionné ? | Publication |
| --- | --- | --- |
| `proofs/runtime/` brut | non | interdite sans relecture |
| archive diagnostic nettoyée | non | partage privé après relecture |
| capture anonymisée | selon le livrable | autorisée |
| extrait CLI contextualisé | selon le livrable | autorisé |
| gabarit non complété | oui | ce n’est pas une preuve |

## Avant toute publication

Vérifier qu’aucun élément ne contient :

- clé AWS ;
- token ;
- clé privée SSH ;
- identifiant sensible inutile ;
- `terraform.tfvars` ;
- état Terraform ;
- inventaire Ansible réel ;
- URL ou IP complète lorsqu’elle n’apporte rien à la démonstration.

Audit du dépôt :

```bash
python3 scripts/tools/audit_secrets.py
```

## Passage des preuves vers les livrables

1. exécuter réellement l’exercice ;
2. conserver les sorties sous `proofs/runtime/` ;
3. sélectionner les éléments qui démontrent une exigence ;
4. anonymiser ;
5. ajouter la commande ou le contexte ;
6. expliquer le résultat ;
7. compléter le gabarit associé ;
8. exécuter le contrôle strict.

```bash
./scripts/commands/prepare-livrables.sh
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Nettoyage

Une preuve doit être conservée **avant** la destruction de la ressource qu’elle
démontre.

Fermeture globale :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Verdict :

```text
NETTOYAGE AWS COMPLET
```

L’audit de nettoyage est global : il est normal qu’il signale encore les
ressources des exercices 1 ou 3 tant qu’elles sont volontairement conservées.

## Documentation associée

- [Contrat des preuves automatiques](../docs/contrat-preuves-automatiques.md)
- [Validation, preuves et nettoyage](../docs/validation-preuves-nettoyage.md)
- [Livrables](../docs/livrables/README.md)
- [Traçabilité](../docs/02-correspondance-consignes-depot.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Sécurité](../SECURITY.md)
