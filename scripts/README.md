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

- la connexion interactive AWS lorsqu'une session doit être créée ;
- les confirmations de sécurité impossibles à vérifier automatiquement ;
- le checkpoint manuel du dashboard OpenSearch ;
- la confirmation `DETRUIRE` du nettoyage final.

## Séquence de `all`

```text
prepare
  ├─ vérification du socle Ubuntu
  ├─ bootstrap automatique si nécessaire
  ├─ authentification AWS temporaire
  ├─ détection compte / région / IPv4 / clé SSH
  ├─ tfvars + budget + AWS Ready
  ↓
ex1
  ├─ Terraform
  ├─ Ansible
  ├─ seconde exécution → changed=0
  ├─ Angular/NGINX
  └─ vrai access.log
  ↓
ex2
  ├─ Amazon OpenSearch Service
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

La session AWS est réutilisée si elle est encore valide. Si elle a expiré,
`aws-auth.sh` tente de la renouveler avant de poursuivre.

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

Chaque étape affiche sa commande, son journal et son verdict. Les nouveaux logs
utilisent `umask 077` et les `.log` sont ignorés par Git.

```bash
bash scripts/commands/p5.sh logs
```

Les journaux sont séparés de `proofs/runtime/` :

- `logs/` explique ce qui a été exécuté ;
- `proofs/runtime/` contient les preuves techniques du projet.

## Automatisations centrales

| Fichier | Rôle |
| --- | --- |
| `scripts/commands/p5.sh` | orchestration du projet |
| `scripts/lib/p5-runtime.sh` | terminal, confirmations, logs |
| `scripts/commands/aws-auth.sh` | connexion AWS temporaire et renouvellement |
| `scripts/commands/configure-lab.sh` | compte, région, IP, SSH, tfvars |
| `scripts/commands/generate-ansible-inventory.sh` | inventaire depuis Terraform |
| `scripts/tests/test-p5-orchestrator.sh` | contrat de l'orchestrateur sans AWS |
| `scripts/tests/test-aws-auth.sh` | contrat de connexion AWS sans contacter AWS |

## Préparation de la VM

| Commande | Effet |
| --- | --- |
| `bootstrap-ubuntu-server.sh` | installe le socle de la VM |
| `setup.sh --check-only` | contrôle non destructif de l'étape 0A |
| `validate.sh` | valide dépôt et intégrations locales |
| `clean-local.sh` | nettoie les caches en conservant les états Terraform |

Si des outils obligatoires manquent, `p5.sh` propose le bootstrap. Celui-ci
installe notamment Git, Python, Terraform, Docker/Compose, AWS CLI v2, Ansible,
Node.js, npm, ShellCheck, yamllint, SSH et les outils Markdown.

AWS CLI doit être au minimum en version `2.32.0`, car cette version minimale est
requise par le parcours `aws login`. Le bootstrap installe/met à jour AWS CLI v2
depuis l'archive officielle puis vérifie cette contrainte.

Une reconnexion est demandée lorsque le nouveau groupe Docker ou NVM doit être
pris en compte.

## Authentification AWS

Commande spécialisée :

```bash
bash scripts/commands/aws-auth.sh
```

Le mode par défaut est `auto` :

1. réutiliser `p5-lab` si la session est encore valide ;
2. renouveler une session console/SSO connue si elle a expiré ;
3. sinon proposer une méthode d'authentification.

### Compte console AWS — méthode recommandée sur la VM

```bash
bash scripts/commands/aws-auth.sh --mode console
```

Le script lance :

```text
aws login --remote --profile p5-signin
```

La VM affiche les instructions AWS. L'utilisateur ouvre l'URL dans son navigateur
habituel et saisit ses identifiants **directement chez AWS**. Le script ne voit
jamais le mot de passe.

AWS CLI obtient des credentials temporaires. Le script crée ensuite le profil
`p5-lab` avec :

```text
credential_process = aws configure export-credentials --profile p5-signin --format process
```

Ainsi AWS CLI, Terraform et les autres outils utilisent la même session temporaire
sans clé longue durée dans le dépôt.

Le projet refuse une identité `root`.

Pour utiliser `aws login`, l'identité console doit disposer de la politique AWS
gérée `SignInLocalDevelopmentAccess`. Elle doit aussi disposer des permissions
métier nécessaires au P5, documentées par `aws/iam/p5-lab-policy.json`.

### IAM Identity Center

```bash
bash scripts/commands/aws-auth.sh --mode sso
```

Si nécessaire, le script lance `aws configure sso`, puis `aws sso login`.

### Profil temporaire existant

```bash
bash scripts/commands/aws-auth.sh --mode existing
```

Le profil source doit fournir des credentials temporaires avec une date
d'expiration. Les clés d'accès longues durées sont rejetées par le parcours
strict.

## Configuration AWS

| Commande | Effet |
| --- | --- |
| `aws-auth.sh` | crée/renouvelle une session temporaire AWS |
| `configure-lab.sh` | authentifie AWS puis prépare la configuration locale |
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

- appelle `aws-auth.sh` ;
- exige des credentials temporaires exportables pour Terraform ;
- refuse l'identité root ;
- détecte le compte AWS ;
- détecte l'IPv4 publique et construit le `/32` ;
- utilise ou prépare la clé SSH ;
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

`p5.sh ex1` attend SSH/cloud-init puis exécute Ansible deux fois. La seconde
exécution exige :

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

Le vrai exercice utilise **Amazon OpenSearch Service** créé par Terraform. Il
n'est donc pas nécessaire d'installer Elasticsearch/OpenSearch directement sur
la VM Ubuntu. Le conteneur OpenSearch local sert uniquement aux tests de qualité.

`p5.sh ex2` utilise deux sources lorsque le log réel existe :

```text
terraform/exercice-2/samples/nginx-access.log.sample
proofs/runtime/exercice-2/nginx-access-real.log
```

Le jeu versionné garantit les tranches de 12 h nécessaires au dashboard ; le log
réel prouve la chaîne NGINX → OpenSearch.

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
| `test-aws-auth.sh` | login temporaire, credential_process et refus root |

```bash
bash scripts/tests/test-p5-orchestrator.sh
bash scripts/tests/test-aws-auth.sh
```

Ces tests utilisent des commandes factices pour les parties AWS et ne créent
aucune ressource cloud. Ils ne remplacent pas le premier vrai :

```bash
bash scripts/commands/p5.sh all
```

sur le compte AWS réel.

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

### Credentials AWS

Le dépôt ne demande ni mot de passe AWS ni clé secrète. Les sessions temporaires
restent dans les mécanismes de cache/configuration de l'AWS CLI sous le compte
utilisateur de la VM.

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
- [Préparation AWS](../docs/00b-preparation-compte-aws.md)
- [Validation et preuves](../docs/validation-preuves-nettoyage.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Preuves runtime](../proofs/README.md)
