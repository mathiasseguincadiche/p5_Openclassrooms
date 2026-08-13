# Documentation du projet P5

Ce portail explique **le projet P5 lui-même** : son objectif, ses trois exercices,
son architecture AWS, son automatisation, ses preuves et son exploitation.

Le projet fait partie du parcours **Expert DevOps OpenClassrooms** et travaille
quatre compétences :

1. provisionner une infrastructure avec Terraform ;
2. automatiser configuration et déploiement avec Ansible ;
3. collecter, analyser et visualiser des logs avec OpenSearch ;
4. améliorer disponibilité et performance avec HAProxy.

La réalisation de ce dépôt utilise **AWS pour les trois exercices**.

> Windows 11, WSL2 et Ubuntu constituent uniquement l'environnement de contrôle
> utilisé pour exécuter les outils. Leur installation est documentée séparément
> dans [00-preparation-environnement.md](00-preparation-environnement.md).

## Comprendre le P5 en une minute

```text
                         PROJET P5
                            │
                            ▼
                  Infrastructure AWS
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
     EXERCICE 1        EXERCICE 2        EXERCICE 3
  Terraform/Ansible     OpenSearch         HAProxy
          │                 ▲                 ▲
          ▼                 │                 │
   NGINX + Angular          │                 │
          │                 │                 │
          └─ access.log ────┘                 │
          │                                   │
          └──── réseau Ex.1 réutilisé ────────┘
                            │
                            ▼
                preuves + soutenance
                            │
                            ▼
                 nettoyage complet AWS
```

Le dépôt ne cherche pas à empiler des technologies. Il cherche à démontrer un
parcours cohérent, reproductible et vérifiable avec les outils réellement demandés
par le projet.

## Les trois exercices

### Exercice 1 — Terraform + Ansible

Objectif : créer une infrastructure AWS avec Terraform puis déployer une
application Angular derrière NGINX avec Ansible.

Points importants :

- VPC `10.0.0.0/16` ;
- deux sous-réseaux publics ;
- EC2 Ubuntu ;
- configuration NGINX ;
- déploiement Angular ;
- second passage Ansible sans changement inutile ;
- collecte du vrai `access.log`.

Guide : [Exercice 1](exercices/01-terraform-ansible.md).

### Exercice 2 — Logs + Amazon OpenSearch

Objectif : indexer et analyser des logs NGINX dans Amazon OpenSearch puis produire
les visualisations demandées.

Le dépôt automatise :

- le domaine OpenSearch ;
- la transformation des données ;
- l'import Bulk ;
- les contrôles de mapping et d'agrégation.

Les visualisations et captures Dashboards restent un checkpoint humain.

Guide : [Exercice 2](exercices/02-elk-opensearch.md).

### Exercice 3 — HAProxy + haute disponibilité

Objectif : répartir le trafic entre deux services, provoquer une panne contrôlée
et vérifier la continuité de service.

L'exercice 3 réutilise le réseau AWS créé pendant l'exercice 1.

Guide : [Exercice 3](exercices/03-haproxy.md).

## Choisir le bon document

La documentation est organisée par **intention**.

### Je veux comprendre le projet

Lire dans cet ordre :

1. [Cadre officiel et périmètre](00-cadre-officiel.md)
2. [Parcours pédagogique](01-parcours-debutant.md)
3. [Architecture et flux](architecture-et-flux.md)
4. [Correspondance consignes → implémentation → preuve](02-correspondance-consignes-depot.md)

### Je veux installer l'environnement de contrôle

Lire :

1. [Préparation Windows 11 / WSL2 / Ubuntu](00-preparation-environnement.md)
2. [Préparation du compte AWS](00b-preparation-compte-aws.md)

Cette partie est un **prérequis d'exécution**, pas le sujet principal du projet.

### Je veux exécuter le lab

Lire :

1. [Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
2. [Centre de commande V11](CENTRE_DE_COMMANDE.md)
3. [Convergence et réexécution](convergence-et-reexecution.md)

Point d'entrée :

```bash
bash scripts/commands/p5.sh
```

### Je suis bloqué

Commencer par :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis lire [Troubleshooting](troubleshooting.md).

### Je prépare la soutenance

Lire :

1. [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)
2. [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
3. [Livrables](livrables/README.md)

Puis lancer :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

## Parcours opérationnel

```text
installation du poste de contrôle
           ↓
contrat P5 vérifié
           ↓
inspect
           ↓
prepare
           ↓
GO AWS + GO TERRAFORM
           ↓
exercice 1
           ↓
exercice 2
           ↓
exercice 3
           ↓
diagnostics
           ↓
finalize
           ↓
cleanup
           ↓
NETTOYAGE AWS COMPLET
```

Le mode `all` exécute le parcours technique jusqu'aux diagnostics, mais **ne
détruit jamais automatiquement AWS**.

## Point d'entrée unique

Le centre de commande est :

```bash
bash scripts/commands/p5.sh
```

Commandes :

| Besoin | Commande |
| --- | --- |
| menu interactif | `bash scripts/commands/p5.sh` |
| observation sans mutation | `bash scripts/commands/p5.sh inspect` |
| préparation | `bash scripts/commands/p5.sh prepare` |
| vérification | `bash scripts/commands/p5.sh status` |
| exercice 1 | `bash scripts/commands/p5.sh ex1` |
| exercice 2 | `bash scripts/commands/p5.sh ex2` |
| exercice 3 | `bash scripts/commands/p5.sh ex3` |
| parcours complet | `bash scripts/commands/p5.sh all` |
| diagnostic | `bash scripts/commands/p5.sh diagnostics` |
| finalisation | `bash scripts/commands/p5.sh finalize` |
| journaux | `bash scripts/commands/p5.sh logs` |
| aide au choix | `bash scripts/commands/p5.sh guide` |
| carte documentaire | `bash scripts/commands/p5.sh docs` |
| nettoyage AWS | `bash scripts/commands/p5.sh cleanup` |

Le Control Center V11 n'ajoute pas un second moteur. Il reste une façade au-dessus
de l'orchestrateur existant.

## Architecture du projet

Le P5 peut être lu en trois couches.

### 1. Plan de contrôle local

Le dépôt contient :

- `scripts/commands/p5.sh` ;
- les scripts spécialisés ;
- la configuration locale du lab ;
- les validateurs ;
- les journaux et preuves runtime.

Cette couche pilote les outils, mais n'est pas la cible évaluée.

### 2. Infrastructure AWS évaluée

```text
AWS — us-east-1
│
├── Exercice 1
│   ├── VPC
│   ├── 2 subnets publics
│   ├── Internet Gateway
│   ├── Security Group
│   └── EC2 → NGINX → Angular
│
├── Exercice 2
│   └── Amazon OpenSearch Service
│
└── Exercice 3
    ├── HAProxy EC2
    └── 2 backends EC2 → Docker → nginxdemos/hello
```

### 3. Preuves et validation

Le projet distingue :

- **implémentation** : fichiers versionnés ;
- **automatisation** : scripts et tests reproductibles ;
- **preuve réelle** : résultat provenant d'une exécution AWS ;
- **checkpoint humain** : visualisation, capture ou décision qui ne doit pas être
  simulée par un script.

Cette distinction est fondamentale pour la soutenance.

## Convergence et réexécution

La logique commune est :

```text
état réel
   ↓
inspection
   ↓
comparaison
   ↓
delta ?
├── non → aucune mutation
└── oui → correction ciblée
   ↓
vérification
   ↓
preuve / log
```

Terraform utilise un plan détaillé : un plan vide ne déclenche aucun `apply`.
L'orchestrateur réutilise également les composants déjà conformes au contrat P5.

La reprise ne doit jamais passer par la suppression improvisée d'un
`terraform.tfstate`.

Guide : [Convergence et réexécution](convergence-et-reexecution.md).

## Preuves et livrables

Les preuves réelles sont locales tant qu'elles n'ont pas été relues et préparées
pour la remise.

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Les journaux sont conservés séparément :

```text
logs/<UTC>/
```

La matrice de traçabilité indique précisément ce qui doit être démontré :
[02-correspondance-consignes-depot.md](02-correspondance-consignes-depot.md).

## Sécurité et coûts

Le projet protège notamment :

- le compte AWS attendu ;
- l'accès SSH limité au `/32` de l'opérateur ;
- les métadonnées EC2 avec IMDSv2 ;
- les volumes EC2 chiffrés ;
- OpenSearch avec HTTPS et chiffrement ;
- les secrets et états locaux hors Git ;
- le budget AWS ;
- les actions destructives par confirmation explicite.

La CI peut prouver la cohérence du code, mais elle ne peut pas garantir qu'un
lab AWS réel est gratuit ou qu'une preuve de soutenance a réellement été produite.

## Installation Windows 11 / WSL2

Le poste de contrôle utilisé actuellement est fourni par :

`mathiasseguincadiche/Windows_11_Pro_Custom`

Il fournit Windows 11, WSL2, Ubuntu et la stack DevOps générale. P5 consomme cet
environnement et ne doit pas dupliquer sa configuration.

Toutes les informations d'installation et de qualification sont volontairement
centralisées dans :

[00-preparation-environnement.md](00-preparation-environnement.md).

Le contrat de versions spécifique au P5 reste versionné dans :

```text
environment/versions.env
```

## Documentation complète

### Cadre et compréhension

- [00 — Cadre officiel](00-cadre-officiel.md)
- [01 — Parcours pédagogique](01-parcours-debutant.md)
- [02 — Correspondance consignes → dépôt → preuves](02-correspondance-consignes-depot.md)
- [Architecture et flux](architecture-et-flux.md)

### Installation et préparation

- [Préparation de l'environnement de contrôle](00-preparation-environnement.md)
- [Préparation du compte AWS](00b-preparation-compte-aws.md)
- [Contrat WSL2 consommé par P5](../environment/wsl2/README.md)

### Exécution et exploitation

- [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
- [Centre de commande V11](CENTRE_DE_COMMANDE.md)
- [Convergence et réexécution](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
- [Scripts et commandes](../scripts/README.md)

### Exercices

- [Exercice 1 — Terraform + Ansible](exercices/01-terraform-ansible.md)
- [Exercice 2 — OpenSearch](exercices/02-elk-opensearch.md)
- [Exercice 3 — HAProxy](exercices/03-haproxy.md)

### Validation et soutenance

- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Livrables](livrables/README.md)
- [Audit de non-régression](04-audit-non-regression.md)

## Sources de vérité

| Sujet | Source de vérité |
| --- | --- |
| exigences du projet | `docs/00-cadre-officiel.md` |
| orchestration | `scripts/commands/p5.sh` |
| versions P5 | `environment/versions.env` |
| configuration AWS locale | `environment/aws-readiness.env` |
| infrastructure | `terraform/exercice-*/` |
| déploiement | `ansible/playbooks/deploy.yml` |
| application | `application/angular/` |
| OpenSearch | `terraform/exercice-2/` |
| preuves | `proofs/runtime/` |
| logs | `logs/` |
| sécurité | `SECURITY.md` |
| workstation | `Windows_11_Pro_Custom` |

## Règle documentaire

Une documentation P5 doit répondre dans cet ordre :

1. **qu'est-ce que le projet doit démontrer ?**
2. **comment les trois exercices fonctionnent-ils ?**
3. **comment l'exécuter et le vérifier ?**
4. **comment préparer l'environnement nécessaire ?**

L'installation Windows/WSL2 reste donc un support d'exécution, jamais l'identité
du projet.
