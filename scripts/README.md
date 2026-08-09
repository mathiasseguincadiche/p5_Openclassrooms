# Scripts du projet P5

Les scripts du dépôt **préparent, vérifient, testent, collectent des preuves et
nettoient** le lab. Les commandes spécialisées restent disponibles pour comprendre
et rejouer chaque opération, tandis que `p5.sh` fournit désormais un point d'entrée
unique pour l'exécution accélérée du projet.

## Mode accéléré — centre de commande P5

Le moyen recommandé pour réaliser le projet depuis le terminal est :

```bash
bash scripts/commands/p5.sh
```

Cette commande ouvre un menu interactif :

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

Pour lancer directement le parcours technique complet :

```bash
bash scripts/commands/p5.sh all
```

Pour confirmer automatiquement les mutations automatisables :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne valide jamais à la place de l'opérateur :

- les confirmations de sécurité impossibles à prouver depuis la CLI ;
- le checkpoint manuel du dashboard OpenSearch ;
- la destruction finale protégée par `destroy-aws.sh`.

L'orchestrateur affiche toujours le plan Terraform avant son application. Il
conserve donc les garde-fous pédagogiques et financiers du projet tout en évitant
le copier-coller du runbook.

### Reprise après interruption

`p5.sh` détecte les états Terraform locaux existants. Si un exercice a déjà été
créé, le script passe en mode reprise au lieu de considérer automatiquement les
ressources AWS comme des conflits.

Il est donc possible de relancer la même commande après une coupure ou une
interruption :

```bash
bash scripts/commands/p5.sh all
```

Terraform réévalue l'état, Ansible reste idempotent et les contrôles fonctionnels
sont rejoués.

### Logs opérateur

Chaque lancement de `p5.sh` crée une session privée :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Le terminal indique pour chaque étape :

```text
P5  07 — Déployer Angular et NGINX avec Ansible
       Commande : ansible-playbook ...
       Log      : .../logs/<UTC>/07-ansible-deploy.log

[ OK ] Déployer Angular et NGINX avec Ansible — 18 s
```

Les journaux opérateur sont séparés de `proofs/runtime/` :

- `logs/` explique ce que les scripts ont exécuté et permet de diagnostiquer un
  échec ;
- `proofs/runtime/` contient les preuves techniques destinées au projet et aux
  livrables.

Les fichiers `.log` sont ignorés par Git. Les sessions créées par le runtime
utilisent un `umask 077` afin que les nouveaux journaux restent privés par défaut.

Pour retrouver rapidement les journaux :

```bash
bash scripts/commands/p5.sh logs
```

## Automatisations ajoutées

| Commande | Rôle |
| --- | --- |
| `p5.sh` | orchestre le projet depuis un menu ou des sous-commandes |
| `configure-lab.sh` | détecte compte AWS, IP publique, profil, région et prépare les tfvars |
| `generate-ansible-inventory.sh` | génère l'inventaire réel depuis les outputs Terraform |
| `scripts/lib/p5-runtime.sh` | fournit affichage terminal, confirmations et journalisation |

Le bootstrap de la VM est également appelé depuis `p5.sh` lorsque les outils
obligatoires manquent. Comme l'ajout au groupe Docker et NVM nécessitent un nouveau
shell, le centre de commande indique clairement quand une reconnexion est requise.

## Principe de sécurité

Les scripts sont répartis en trois familles :

| Type | Comportement | Exemple |
| --- | --- | --- |
| Non destructif | lecture, validation ou test local | `setup.sh`, `validate.sh` |
| Aperçu puis `--apply` | mutation seulement après option explicite | import OpenSearch, budget, failover |
| Destructif confirmé | action irréversible avec confirmation | `destroy-aws.sh` |

Le centre de commande orchestre ces scripts mais ne supprime pas leurs protections.

## Parcours minimal spécialisé

Les commandes ci-dessous restent utiles pour rejouer une étape isolée sans
l'orchestrateur :

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
| `setup.sh --check-only` | contrôle non destructif de l'étape 0A |
| `validate.sh` | valide le dépôt et les intégrations locales disponibles |
| `clean-local.sh` | nettoie les caches sans supprimer les états Terraform |

### Configuration AWS

| Commande | Effet |
| --- | --- |
| `configure-lab.sh` | prépare la configuration locale avec détection automatique |
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
| `prepare-angular-artifact.sh` | construit Angular et synchronise l'artefact Ansible |
| `generate-ansible-inventory.sh` | transforme l'output Terraform en inventaire Ansible local |
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

Le dashboard reste un checkpoint humain : les données et agrégations sont
validées automatiquement, puis les trois visualisations demandées sont créées et
capturées dans OpenSearch Dashboards.

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
| `destroy-aws.sh` | détruit Terraform dans l'ordre 3 → 2 → 1 |
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

Les conteneurs temporaires sont supprimés par `trap`, y compris en cas d'échec.

OpenSearch local n'est inclus dans `validate.sh` que sur demande :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

Avec le centre de commande :

```bash
bash scripts/commands/p5.sh status --full-validation
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

Le journal complet non filtré **n'est jamais ajouté à l'archive**.

Le nettoyage automatique masque notamment les signatures détectables de :

- clés AWS ;
- secrets AWS CLI ;
- jetons de session ;
- en-têtes Authorization ;
- blocs de clé privée.

Une relecture humaine reste obligatoire.

## Règles importantes

### `p5.sh`

- conserve les plans Terraform visibles avant `apply` ;
- journalise chaque étape et indique immédiatement le fichier à consulter ;
- détecte les états Terraform pour faciliter une reprise ;
- automatise la génération de l'inventaire Ansible ;
- attend les services au lieu d'imposer des délais manuels arbitraires ;
- ne détruit jamais automatiquement les ressources à la fin de `all`.

### `configure-lab.sh`

- détecte le compte AWS actif et refuse l'identité root ;
- détecte l'IPv4 publique actuelle et la convertit en `/32` ;
- peut préparer une clé SSH dédiée ;
- n'invente jamais les confirmations de sécurité manuelles ;
- génère ensuite les trois `terraform.tfvars` depuis la source unique.

### `prepare-angular-artifact.sh`

Le build Ansible n'est remplacé qu'après un build Angular réussi et la détection
d'un unique artefact navigateur.

### `sync-terraform-tfvars.sh`

- refuse les valeurs de compte/IP d'exemple ;
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

Ne supprime pas les états Terraform afin d'éviter d'orpheliner des ressources
AWS.

### `destroy-aws.sh`

- exige le mot exact `DETRUIRE` ;
- détruit 3 → 2 → 1 ;
- signale un état Terraform absent au lieu de prétendre que le module est propre.

### `check-aws-cleanup.sh`

C'est un audit **global** du P5. Il doit être utilisé pour le verdict final après
fermeture de tous les exercices.

## CI

Les mêmes contrats sont vérifiés par GitHub Actions :

- qualité du dépôt ;
- non-régression ;
- secrets et hygiène.

Dependabot surveille chaque semaine les actions GitHub et les dépendances npm de
l'application Angular.

## Documentation associée

- [Portail documentaire](../docs/README.md)
- [Runbook](../docs/01-parcours-debutant.md)
- [Validation et preuves](../docs/validation-preuves-nettoyage.md)
- [Troubleshooting](../docs/troubleshooting.md)
- [Preuves runtime](../proofs/README.md)
