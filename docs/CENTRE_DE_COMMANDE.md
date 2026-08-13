# Centre de commande P5

## Rôle

Le point d'entrée opérateur du projet est :

```bash
bash scripts/commands/p5.sh
```

Sans argument, cette commande ouvre un menu interactif. Toutes les actions importantes sont également disponibles directement en CLI.

Le centre de commande est une **couche d'orchestration**. Terraform reste responsable de l'infrastructure, Ansible de la configuration, et les scripts spécialisés de leurs contrôles respectifs.

## Philosophie

```text
observer
  ↓
classifier
  ↓
calculer le delta
  ↓
confirmer si mutation
  ↓
appliquer
  ↓
vérifier
  ↓
journaliser
```

Le moteur distingue autant que possible :

- observation ;
- convergence ;
- déploiement ;
- test temporairement mutateur ;
- validation ;
- destruction.

## Syntaxe

```bash
bash scripts/commands/p5.sh [commande] [options]
```

Options globales :

```text
--yes
--full-validation
```

### `--yes`

Confirme automatiquement les mutations **automatisables**.

Il ne doit pas :

- valider un dashboard OpenSearch à votre place ;
- inventer une information AWS inconnue ;
- contourner la confirmation forte de destruction.

### `--full-validation`

Ajoute les contrôles d'intégration locale plus lourds, notamment le test OpenSearch local.

## `menu`

```bash
bash scripts/commands/p5.sh menu
```

Équivalent à :

```bash
bash scripts/commands/p5.sh
```

Le menu regroupe les actions par intention : démarrer/reprendre, exercices, validation, aide et maintenance.

Le menu n'implémente pas une logique différente de la CLI : il appelle les mêmes fonctions.

## `inspect`

```bash
bash scripts/commands/p5.sh inspect
```

### But

Observer l'état actuel sans chercher à « réparer » immédiatement.

### Mutation

Non.

### Quand l'utiliser

- première ouverture du projet ;
- reprise après reboot ;
- avant un diagnostic ;
- avant toute correction manuelle ;
- après un échec inattendu.

### Résultat utile

Un inventaire factuel de ce qui est présent, absent ou non vérifiable.

## `prepare`

```bash
bash scripts/commands/p5.sh prepare
```

### But

Converger les prérequis nécessaires au lab.

### Peut agir sur

- outils/version du poste WSL2 ;
- configuration AWS locale ;
- authentification ;
- clé SSH ;
- budget ;
- `terraform.tfvars` locaux ;
- garde-fous.

### Ne déploie pas

Cette commande ne signifie pas « créer les trois exercices AWS ».

### Mutation

Possible, avec confirmation selon la situation.

## `status`

```bash
bash scripts/commands/p5.sh status
```

### But

Vérifier si l'environnement est prêt **sans déployer**.

### Mutation

Non sur l'infrastructure des exercices.

### Usage

À lancer après `prepare`, ou avant de reprendre un exercice lorsqu'on veut seulement vérifier.

## `ex1`

```bash
bash scripts/commands/p5.sh ex1
```

### But

Converger l'exercice 1 :

```text
Angular build
→ Terraform exercice 1
→ inventaire Ansible
→ SSH
→ Ansible ping
→ deploy.yml
→ second passage idempotent
→ test HTTP
→ trafic NGINX
→ collecte access.log
```

### Mutation

Oui : AWS et configuration de l'EC2.

### Coût

Possible tant que les ressources AWS existent.

## `ex2`

```bash
bash scripts/commands/p5.sh ex2
```

### But

Converger :

```text
Terraform OpenSearch
→ validation du sample
→ validation éventuelle du log réel
→ import
→ vérification mapping/agrégations
→ checkpoint OpenSearch Dashboards
```

### Mutation

Oui : domaine OpenSearch et données.

### Checkpoint humain

Les trois visualisations et les captures ne sont pas déclarées « faites » automatiquement.

## `ex3`

```bash
bash scripts/commands/p5.sh ex3
```

### But

Converger :

```text
Terraform HAProxy + backends
→ attente HTTP
→ round-robin
→ prévisualisation panne
→ confirmation
→ panne réelle
→ continuité
→ restauration
→ réintégration
```

### Mutation

Oui. Le test de panne est une mutation temporaire volontaire.

## `all`

```bash
bash scripts/commands/p5.sh all
```

### Enchaînement

```text
prepare
→ ex1
→ ex2
→ ex3
→ diagnostics
```

### Important

`all` **ne détruit pas AWS** à la fin.

Il est adapté :

- à un parcours complet ;
- à une reprise convergente lorsque les states existent déjà.

Il ne faut pas l'interpréter comme « recréer tout depuis zéro ».

## `diagnostics`

```bash
bash scripts/commands/p5.sh diagnostics
```

### But

Collecter un état technique détaillé et vérifier la structure des preuves/livrables.

### Mutation AWS

Non.

### Mutation locale

Oui : création de journaux et de preuves de diagnostic.

## `finalize`

```bash
bash scripts/commands/p5.sh finalize
```

### But

- lancer les diagnostics ;
- exécuter le contrôle strict des livrables ;
- signaler les preuves/captures encore manquantes.

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## `cleanup`

```bash
bash scripts/commands/p5.sh cleanup
```

### But

Détruire les ressources P5 suivies par Terraform puis auditer les résidus AWS.

### Niveau de risque

Destructif.

### Ordre

```text
Exercice 3
    ↓
Exercice 2
    ↓
Exercice 1
    ↓
audit AWS
```

### Confirmation

La destruction finale conserve une confirmation forte. Le mode `--yes` n'a pas vocation à transformer la fermeture du lab en destruction silencieuse.

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

## `logs`

```bash
bash scripts/commands/p5.sh logs
```

Affiche les journaux les plus récents disponibles.

Les logs détaillés sont organisés par run sous :

```text
logs/<UTC>/
```

et par script sous :

```text
logs/scripts/
```

## `guide`

```bash
bash scripts/commands/p5.sh guide
```

Aide interactive pour choisir le parcours selon la situation :

- première exécution ;
- reprise ;
- contrôle seulement ;
- exercice ciblé ;
- préparation de soutenance ;
- incident ;
- nettoyage.

## `docs`

```bash
bash scripts/commands/p5.sh docs
```

Affiche la carte de navigation documentaire dans le terminal.

Le portail Markdown complet reste [`README.md`](README.md) dans ce dossier.

## `help`

```bash
bash scripts/commands/p5.sh --help
```

ou :

```bash
bash scripts/commands/p5.sh help
```

Affiche la syntaxe supportée.

## Matrice de décision

| Situation | Première commande | Suite typique |
| --- | --- | --- |
| je découvre le lab | `inspect` | `prepare` puis `status` |
| je veux tout réaliser | `status` | `all` |
| je reprends après interruption | `inspect` | `all` ou exercice ciblé |
| je veux seulement vérifier | `status` | aucune mutation si tout est correct |
| ex. 1 uniquement | `ex1` | preuves puis ex. 2/3 |
| ex. 2 uniquement | `ex2` | checkpoint dashboard |
| ex. 3 uniquement | `ex3` | failover puis preuves |
| je prépare la remise | `finalize` | relecture livrables |
| j'ai un échec | `inspect` | `logs` puis `diagnostics` |
| j'ai terminé | `cleanup` | vérifier `NETTOYAGE AWS COMPLET` |

## Pourquoi utiliser `p5.sh` plutôt que tout lancer à la main ?

Parce que l'orchestrateur ajoute :

- ordre des dépendances ;
- lecture de l'état réel ;
- gestion des codes `terraform plan -detailed-exitcode` ;
- confirmations ;
- validation des outputs ;
- logs centralisés ;
- redaction de secrets ;
- preuves par étape ;
- checkpoints humains ;
- ordre de destruction.

Les commandes directes Terraform/Ansible restent documentées pour comprendre les outils et diagnostiquer, mais le parcours normal doit rester aligné sur le moteur du dépôt.
