# Scripts du projet P5

Les scripts du dépôt préparent, vérifient, déploient, testent, collectent des
preuves et nettoient le lab. Le point d'entrée recommandé est `p5.sh`; les
commandes spécialisées restent disponibles pour comprendre ou rejouer une étape.

## Centre de commande P5

```bash
bash scripts/commands/p5.sh
```

Menu :

```text
1  Préparer le lab
2  Exercice 1 — Terraform / Ansible / Angular
3  Exercice 2 — OpenSearch / dashboard
4  Exercice 3 — HAProxy
5  Tout exécuter de A à Z
6  Statut / contrôles
7  Finaliser les livrables
8  Afficher les logs
9  Nettoyer AWS
q  Quitter
```

Parcours complet :

```bash
bash scripts/commands/p5.sh all
```

Mode accéléré :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne contourne jamais :

- les confirmations de sécurité impossibles à vérifier automatiquement ;
- le checkpoint manuel du dashboard OpenSearch ;
- la confirmation `DETRUIRE` du nettoyage final.

## Séquence de `all`

```text
prepare
  ↓
ex1
  ├─ Terraform
  ├─ Ansible
  ├─ seconde exécution → changed=0
  ├─ Angular/NGINX
  └─ vrai access.log
  ↓
ex2
  ├─ OpenSearch
  ├─ échantillon reproductible
  ├─ vrai access.log
  ├─ mappings/agrégations
  └─ dashboard manuel
  ↓
ex3
  ├─ HAProxy
  ├─ round-robin
  ├─ panne réelle
  └─ reprise
  ↓
diagnostics + structure des livrables
```

`all` ne détruit pas AWS automatiquement.

## Reprise après interruption

`p5.sh` détecte les états Terraform locaux. Si le lab existe déjà, il passe en
mode reprise au lieu de traiter automatiquement les ressources gérées comme des
collisions.

Après une interruption :

```bash
bash scripts/commands/p5.sh all
```

Ne jamais supprimer un état Terraform pour forcer une reprise.

## Logs opérateur

Chaque lancement crée une session :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Chaque étape affiche :

```text
P5  07 — Déployer Angular et NGINX avec Ansible
       Commande : ...
       Log      : .../07-ansible-deploy.log

[ OK ] Déployer Angular et NGINX avec Ansible — 18 s
```

Les journaux sont séparés de `proofs/runtime/` :

- `logs/` explique ce qui a été exécuté ;
- `proofs/runtime/` contient les preuves techniques du projet.

Les nouveaux logs utilisent `umask 077` et les `.log` sont ignorés par Git.

```bash
bash scripts/commands/p5.sh logs
```

## Automatisations centrales

| Fichier | Rôle |
| --- | --- |
| `scripts/commands/p5.sh` | orchestration du projet |
| `scripts/lib/p5-runtime.sh` | terminal, confirmations, logs |
| `scripts/commands/configure-lab.sh` | profil AWS, compte, IP, SSH, tfvars |
| `scripts/commands/generate-ansible-inventory.sh` | inventaire depuis Terraform |
| `scripts/tests/test-p5-orchestrator.sh` | contrat de l'orchestrateur sans AWS |

## Préparation de la VM

| Commande | Effet |
| --- | --- |
| `bootstrap-ubuntu-server.sh` | installe le socle de la VM |
| `setup.sh --check-only` | contrôle non destructif de l'étape 0A |
| `validate.sh` | valide dépôt et intégrations locales |
| `clean-local.sh` | nettoie les caches en conservant les états Terraform |

Si des outils obligatoires manquent, `p5.sh` peut proposer le bootstrap. Une
reconnexion est ensuite demandée lorsque le nouveau groupe Docker ou NVM doit
être pris en compte.

## Configuration AWS

| Commande | Effet |
| --- | --- |
| `configure-lab.sh` | prépare la configuration locale |
| `sync-terraform-tfvars.sh` | prévisualise les tfvars |
| `sync-terraform-tfvars.sh --apply` | écrit les trois tfvars |
| `sync-terraform-tfvars.sh --check` | vérifie leur cohérence |
| `setup-aws-guardrails.sh` | prévisualise le budget |
| `setup-aws-guardrails.sh --apply` | crée le budget |
| `check-aws-readiness.sh --stage ...` | contrôle AWS non destructif |
| `pre-deployment-check.sh --stage ...` | combine dépôt, VM, tfvars et AWS |

La source de vérité est `environment/aws-readiness.env`.

### `configure-lab.sh`

Le script :

- refuse l'identité root ;
- détecte le compte AWS ;
- détecte l'IPv4 publique et construit le `/32` ;
- utilise ou prépare la clé SSH ;
- peut déclencher `aws configure sso` / `aws sso login` ;
- demande les validations de sécurité manuelles ;
- synchronise les trois tfvars.

Le mode `--yes` ne fabrique aucune confirmation de sécurité.

## Exercice 1

| Commande | Effet |
| --- | --- |
| `prepare-angular-artifact.sh` | build Angular + synchronisation Ansible |
| `generate-ansible-inventory.sh` | inventaire réel depuis `web_public_ip` |
| `verify-angular-deployment.sh` | HTTP, bundle, SPA, en-têtes |
| `generate-nginx-traffic.sh` | trafic HTTP contrôlé |
| `collect-nginx-access-log.sh` | récupération du vrai `access.log` |

`p5.sh ex1` ajoute deux comportements importants :

1. attente de SSH/cloud-init au lieu d'un délai arbitraire ;
2. seconde exécution du playbook Ansible avec vérification stricte :

```text
changed=0
unreachable=0
failed=0
```

Verdict final attendu :

```text
APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX
```

## Exercice 2

| Commande | Effet |
| --- | --- |
| `import-opensearch-data.sh` | valide et convertit les logs |
| `import-opensearch-data.sh --apply` | template + import Bulk |
| `verify-opensearch-data.sh` | mappings, volume, agrégations |

`p5.sh ex2` utilise deux sources lorsque le log réel existe :

```text
terraform/exercice-2/samples/nginx-access.log.sample
proofs/runtime/exercice-2/nginx-access-real.log
```

Le jeu versionné garantit les tranches de 12 h nécessaires au dashboard ; le log
réel prouve la chaîne NGINX → OpenSearch.

Le convertisseur génère des IDs déterministes, ce qui rend la réimportation d'une
même ligne idempotente côté document.

Verdicts :

```text
IMPORT OPENSEARCH RÉUSSI
DONNÉES OPENSEARCH PRÊTES POUR LE DASHBOARD
```

La création des visualisations reste manuelle et `p5.sh` exige `OK` après la
capture réelle des preuves.

## Exercice 3

| Commande | Effet |
| --- | --- |
| `test-haproxy-roundrobin.sh` | exige deux backends distincts |
| `test-haproxy-failover.sh` | prévisualise le scénario |
| `test-haproxy-failover.sh --apply` | arrêt, continuité, reprise |

`p5.sh ex3` attend que HAProxy réponde réellement avant les tests.

Verdicts :

```text
ROUND-ROBIN OPÉRATIONNEL
BASCULE ET RÉINTÉGRATION HAPROXY VALIDÉES
```

## Preuves et finalisation

| Commande | Effet |
| --- | --- |
| `collect-diagnostics.sh` | diagnostic partageable |
| `prepare-livrables.sh --structure-only` | structure des livrables |
| `prepare-livrables.sh` | contrôle strict |
| `destroy-aws.sh` | destruction 3 → 2 → 1 |
| `check-aws-cleanup.sh` | audit final AWS |

Via le centre de commande :

```bash
bash scripts/commands/p5.sh finalize
bash scripts/commands/p5.sh cleanup
```

Verdicts :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

## Tests locaux

| Test | Vérifie |
| --- | --- |
| `test-nginx-angular.sh` | build Angular derrière la vraie config NGINX |
| `test-opensearch-local.sh` | template, Bulk et agrégations |
| `test-haproxy-containers.sh` | round-robin, panne et reprise |
| `test-p5-orchestrator.sh` | contrat du centre de commande sans AWS |

### Test de l'orchestrateur

```bash
bash scripts/tests/test-p5-orchestrator.sh
```

Le test crée un environnement temporaire avec commandes factices. Il vérifie le
séquencement sans appeler AWS réellement et contrôle notamment que `--yes` ne peut
pas valider le checkpoint OpenSearch en environnement non interactif.

Ce test ne remplace pas le premier :

```bash
bash scripts/commands/p5.sh all
```

sur le vrai compte AWS.

## Validation complète locale

```bash
bash scripts/commands/p5.sh status --full-validation
```

Équivalent spécialisé :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

## Outils

| Outil | Rôle |
| --- | --- |
| `convert-nginx-logs.py` | NGINX combined → Bulk NDJSON |
| `generer-haproxy-config.sh` | génération HAProxy |
| `audit_secrets.py` | secrets et fichiers sensibles |
| `audit_non_regression.py` | contrat fonctionnel/documentaire |

## Règles de sécurité importantes

### Plans Terraform

Le plan reste visible avant tout `apply` piloté par `p5.sh`.

### Preuves humaines

Le dashboard OpenSearch n'est jamais validé automatiquement.

### Failover

Aucune panne réelle sans `--apply`. Un `trap` tente de restaurer le backend si
l'exécution est interrompue.

### Nettoyage local

`clean-local.sh` ne supprime pas les états Terraform.

### Destruction AWS

`destroy-aws.sh` exige `DETRUIRE` et détruit 3 → 2 → 1.

### Audit final

`check-aws-cleanup.sh` est global. Le verdict `NETTOYAGE AWS COMPLET` n'est
attendu qu'une fois tous les exercices fermés.

## Documentation associée

- [README principal](../README.md)
- [Portail documentaire](../docs/README.md)
- [Runbook](../docs/01-parcours-debutant.md)
- [Validation et preuves](../docs/validation-preuves-nettoyage.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Preuves runtime](../proofs/README.md)
