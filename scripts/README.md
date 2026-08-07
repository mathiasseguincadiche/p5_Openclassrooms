# Scripts du projet P5

Les scripts du dépôt **préparent, vérifient, testent, collectent des preuves et
nettoient** le lab. Ils ne remplacent pas les commandes pédagogiques Terraform,
Ansible ou OpenSearch qui doivent rester visibles et comprises.

Aucun script ne lance automatiquement les trois exercices AWS de bout en bout.

## Principe de sécurité

Les scripts sont répartis en trois familles :

| Type | Comportement | Exemple |
| --- | --- | --- |
| Non destructif | lecture, validation ou test local | `setup.sh`, `validate.sh` |
| Aperçu puis `--apply` | mutation seulement après option explicite | import OpenSearch, budget, failover |
| Destructif confirmé | action irréversible avec confirmation | `destroy-aws.sh` |

## Parcours minimal

```bash
# 1. Préparer la VM
./scripts/commands/bootstrap-ubuntu-server.sh
./scripts/commands/setup.sh --check-only

# 2. Préparer AWS
bash scripts/commands/sync-terraform-tfvars.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial

# 3. Construire Angular
./scripts/commands/prepare-angular-artifact.sh

# 4. Vérifier le dépôt
./scripts/commands/validate.sh

# 5. Après les exercices : livrables et nettoyage
./scripts/commands/prepare-livrables.sh
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Le runbook complet est :
[`docs/01-parcours-debutant.md`](../docs/01-parcours-debutant.md).

## `scripts/commands/` — commandes opérateur

### Préparation de la VM

| Commande | Effet |
| --- | --- |
| `bootstrap-ubuntu-server.sh` | installe le socle de la VM |
| `setup.sh --check-only` | contrôle non destructif de l’étape 0A |
| `validate.sh` | valide le dépôt et les intégrations locales disponibles |
| `clean-local.sh` | nettoie les caches sans supprimer les états Terraform |

### Configuration AWS

| Commande | Effet |
| --- | --- |
| `sync-terraform-tfvars.sh` | aperçu des tfvars générés |
| `sync-terraform-tfvars.sh --apply` | écrit les 3 tfvars en mode `600` |
| `sync-terraform-tfvars.sh --check` | vérifie la synchronisation |
| `setup-aws-guardrails.sh` | prévisualise le budget |
| `setup-aws-guardrails.sh --apply` | crée le budget du lab |
| `check-aws-readiness.sh --stage ...` | contrôle AWS strictement non destructif |
| `pre-deployment-check.sh --stage ...` | combine VM, dépôt, variables et AWS Ready |

La source de vérité est `environment/aws-readiness.env`, pas les trois tfvars.

### Exercice 1

| Commande | Effet |
| --- | --- |
| `prepare-angular-artifact.sh` | construit Angular et synchronise l’artefact Ansible |
| `verify-angular-deployment.sh` | contrôle HTTP, bundle, SPA et en-têtes |
| `generate-nginx-traffic.sh` | génère un trafic HTTP contrôlé |
| `collect-nginx-access-log.sh` | récupère le vrai `access.log` par SSH |

Verdicts utiles :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
TRAFIC NGINX GÉNÉRÉ
LOGS NGINX RÉELS COLLECTÉS
```

### Exercice 2

| Commande | Effet |
| --- | --- |
| `import-opensearch-data.sh` | valide et convertit localement les logs |
| `import-opensearch-data.sh --apply` | crée le template et importe réellement |
| `verify-opensearch-data.sh` | contrôle mappings, volume et agrégations |

Verdicts :

```text
IMPORT OPENSEARCH RÉUSSI
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

### Exercice 3

| Commande | Effet |
| --- | --- |
| `test-haproxy-roundrobin.sh` | exige au moins deux backends distincts |
| `test-haproxy-failover.sh` | simule le scénario sans arrêter de backend |
| `test-haproxy-failover.sh --apply` | arrête, teste, redémarre et réintègre un backend |

Verdicts :

```text
ROUND-ROBIN OPÉRATIONNEL
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

### Preuves et finalisation

| Commande | Effet |
| --- | --- |
| `collect-diagnostics.sh` | produit un diagnostic partageable nettoyé |
| `prepare-livrables.sh --structure-only` | contrôle la structure des trois gabarits |
| `prepare-livrables.sh` | contrôle strict avant remise |
| `destroy-aws.sh` | détruit Terraform dans l’ordre 3 → 2 → 1 |
| `check-aws-cleanup.sh` | audit global des ressources P5 restantes |

Verdicts finaux :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

## `scripts/tests/` — intégrations locales

Ces tests utilisent Docker pour vérifier le comportement sans créer de ressource
AWS.

| Test | Vérifie |
| --- | --- |
| `test-nginx-angular.sh` | véritable build Angular derrière la vraie config NGINX |
| `test-haproxy-containers.sh` | round-robin, panne et reprise avec conteneurs |
| `test-opensearch-local.sh` | template, import Bulk et agrégations OpenSearch |

Les conteneurs temporaires sont supprimés par `trap`, y compris en cas d’échec.

OpenSearch local n’est inclus dans `validate.sh` que sur demande :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

## `scripts/tools/` — outils spécialisés

| Outil | Rôle |
| --- | --- |
| `convert-nginx-logs.py` | transforme NGINX combined en Bulk NDJSON |
| `generer-haproxy-config.sh` | génère un `haproxy.cfg` minimal |
| `audit_secrets.py` | cherche secrets et fichiers sensibles suivis par Git |
| `audit_non_regression.py` | protège les capacités et la cohérence du projet |

## Diagnostic partageable

Commande standard :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Mode complet :

```bash
bash scripts/commands/collect-diagnostics.sh --complet
```

Avec les preuves runtime existantes :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Le collecteur crée :

```text
proofs/runtime/diagnostics/
├── p5-diagnostic-<UTC>/
│   ├── diagnostic-complet.log      # privé, local uniquement
│   ├── diagnostic-partage.log      # nettoyé
│   ├── resume.txt
│   └── manifest-preuves.txt
└── p5-diagnostic-<UTC>.tar.gz      # archive partageable après relecture
```

Le journal complet non filtré **n’est jamais ajouté à l’archive**.

Le nettoyage automatique masque notamment les signatures détectables de :

- clés AWS ;
- secrets AWS CLI ;
- jetons de session ;
- en-têtes Authorization ;
- blocs de clé privée.

Une relecture humaine reste obligatoire.

## Règles importantes

### `prepare-angular-artifact.sh`

Le build Ansible n’est remplacé qu’après un build Angular réussi et la détection
d’un unique artefact navigateur.

### `sync-terraform-tfvars.sh`

- refuse les valeurs de compte/IP d’exemple ;
- écrit en mode `600` ;
- génère les trois modules depuis une seule source.

### `pre-deployment-check.sh`

- ne crée aucune ressource AWS ;
- refuse les tfvars désynchronisés ;
- adapte ses contrôles à `initial`, `exercice-2` ou `exercice-3` ;
- bloque le `GO TERRAFORM` en cas de `KO`.

### `test-haproxy-failover.sh`

- aucune panne sans `--apply` ;
- `trap` de restauration après arrêt réel ;
- vérifie avant, pendant et après la panne.

### `clean-local.sh`

Ne supprime pas les états Terraform afin d’éviter d’orpheliner des ressources
AWS.

### `destroy-aws.sh`

- exige le mot exact `DETRUIRE` ;
- détruit 3 → 2 → 1 ;
- signale un état Terraform absent au lieu de prétendre que le module est propre.

### `check-aws-cleanup.sh`

C’est un audit **global** du P5. Il doit être utilisé pour le verdict final après
fermeture de tous les exercices.

## CI

Les mêmes contrats sont vérifiés par GitHub Actions :

- qualité du dépôt ;
- non-régression ;
- secrets et hygiène.

Dependabot surveille chaque semaine les actions GitHub et les dépendances npm de
l’application Angular.

## Documentation associée

- [Portail documentaire](../docs/README.md)
- [Runbook](../docs/01-parcours-debutant.md)
- [Validation et preuves](../docs/validation-preuves-nettoyage.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Preuves runtime](../proofs/README.md)
