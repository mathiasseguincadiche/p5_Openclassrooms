# P5 OpenClassrooms — Infrastructure as Code, observabilité et haute disponibilité sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt constitue un lab DevOps AWS reproductible. Il ne se limite pas à stocker des fichiers Terraform : il fournit un **plan de contrôle**, des garde-fous, des procédures de vérification et une documentation permettant de comprendre **quoi faire, comment le faire et pourquoi**.

Le projet couvre exactement trois exercices :

1. **Terraform + Ansible + Angular/NGINX** — créer une infrastructure AWS puis configurer une EC2 de manière idempotente ;
2. **Amazon OpenSearch** — transformer des logs NGINX en données exploitables puis construire les visualisations demandées ;
3. **HAProxy** — démontrer la répartition de charge et la continuité de service pendant la panne contrôlée d'un backend.

> **Important — coûts AWS**  
> Une CI verte ne signifie ni déploiement AWS effectué ni coût nul. Toute ressource AWS active doit être considérée comme potentiellement facturable jusqu'au verdict final `NETTOYAGE AWS COMPLET`.

![Architecture et dépendances du P5](docs/schemas/vue-ensemble.svg)

## À qui s'adresse ce dépôt ?

| Profil | Commencer par | Objectif |
| --- | --- | --- |
| je découvre Terraform, Ansible ou AWS | [`docs/01-parcours-debutant.md`](docs/01-parcours-debutant.md) | construire le modèle mental avant d'exécuter |
| je veux réaliser le projet de A à Z | [`docs/RUNBOOK_EXECUTION_GUIDEE.md`](docs/RUNBOOK_EXECUTION_GUIDEE.md) | suivre une procédure opératoire vérifiable |
| je veux comprendre l'architecture | [`docs/architecture-et-flux.md`](docs/architecture-et-flux.md) | comprendre responsabilités, réseau, données et dépendances |
| je reprends un lab existant | [`docs/convergence-et-reexecution.md`](docs/convergence-et-reexecution.md) | réutiliser l'état existant sans recréer inutilement |
| j'ai une erreur | [`docs/troubleshooting.md`](docs/troubleshooting.md) | diagnostiquer par couche avant de modifier |
| je prépare les preuves ou la soutenance | [`docs/livrables/README.md`](docs/livrables/README.md) | transformer les résultats réels en preuves exploitables |
| je ne connais pas un terme | [`docs/GLOSSAIRE.md`](docs/GLOSSAIRE.md) | retrouver une définition appliquée au P5 |

Le portail complet se trouve dans [`docs/README.md`](docs/README.md).

## Le projet en 30 secondes

| Exercice | Question à laquelle il répond | Réalisation | Preuve principale |
| --- | --- | --- | --- |
| **1 — Infrastructure et déploiement** | peut-on créer puis configurer une cible de manière reproductible ? | Terraform crée le socle AWS ; Ansible déploie Angular derrière NGINX sur EC2 | plan Terraform convergé, application accessible, second passage Ansible `changed=0` |
| **2 — Logs et observabilité** | peut-on transformer des logs HTTP en informations utiles ? | Amazon OpenSearch reçoit un sample reproductible et le vrai `access.log` NGINX | données indexées, agrégations valides, trois visualisations et un dashboard |
| **3 — Haute disponibilité** | le service continue-t-il lorsque l'un des backends tombe ? | HAProxy répartit les requêtes vers deux backends `nginxdemos/hello` | round-robin, retrait du backend défaillant, continuité puis réintégration |

Dépendances importantes :

```text
Exercice 1
├── fournit le log NGINX réel ─────────► Exercice 2
└── fournit le VPC et les subnets ─────► Exercice 3

Nettoyage : Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

## Deux Ubuntu différents : ne pas les confondre

Le projet utilise deux contextes Linux distincts.

| Contexte | Version | Rôle |
| --- | --- | --- |
| **plan de contrôle local** | Ubuntu 26.04 LTS `resolute` sous WSL2 | exécuter `p5.sh`, Terraform, Ansible, AWS CLI, Node.js et les validations |
| **instances EC2 des exercices 1 et 3** | Ubuntu 24.04 LTS `noble` par défaut | héberger la cible Ansible, HAProxy et les backends de démonstration |

La plateforme Windows/WSL2 est fournie par [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom). Le dépôt P5 **ne crée, ne déplace et ne détruit pas** la distribution WSL2 ni son VHDX.

Le checkout P5 doit vivre sur le filesystem Linux de WSL2, par exemple :

```text
~/labs/p5_Openclassrooms
```

Les racines `/mnt/c` et `/mnt/d` ne sont pas utilisées comme workspace DevOps de référence.

Référence : [`environment/wsl2/README.md`](environment/wsl2/README.md).

## Première prise en main

![Étape 0 — préparation du plan de contrôle P5](docs/schemas/etape-0.svg)

Dans la distribution WSL2 `Ubuntu` :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

### 1. Observer avant de modifier

```bash
bash scripts/commands/p5.sh inspect
```

`inspect` collecte l'état disponible sans chercher à corriger immédiatement.

### 2. Préparer le runtime et le lab

```bash
bash scripts/commands/p5.sh prepare
```

`prepare` peut converger les dépendances propres au P5, la configuration locale AWS, la clé SSH, le budget et les `terraform.tfvars`. Cette commande **ne signifie pas** « déployer les trois exercices ».

### 3. Revalider avant Terraform

```bash
bash scripts/commands/p5.sh status
```

Le précontrôle doit pouvoir atteindre :

```text
GO TERRAFORM
```

Ce verdict signifie : **le lab est suffisamment qualifié pour lire un plan Terraform**. Il ne signifie pas qu'un `apply` doit être accepté automatiquement.

Guide détaillé : [`docs/00-preparation-environnement.md`](docs/00-preparation-environnement.md).

## Le centre de commande `p5.sh`

Point d'entrée principal :

```bash
bash scripts/commands/p5.sh
```

Sans argument, un menu s'ouvre. Les mêmes actions sont disponibles directement en CLI.

| Commande | Mutation possible ? | Rôle |
| --- | --- | --- |
| `p5.sh inspect` | non | observer l'état réel |
| `p5.sh prepare` | oui, préparation contrôlée | converger runtime P5, configuration AWS et garde-fous |
| `p5.sh status` | non sur les exercices | vérifier que le lab est prêt |
| `p5.sh ex1` | oui | converger Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | oui | converger OpenSearch, importer et vérifier les données |
| `p5.sh ex3` | oui | converger HAProxy et tester panne/reprise |
| `p5.sh all` | oui | exécuter `prepare → ex1 → ex2 → ex3 → diagnostics` |
| `p5.sh diagnostics` | localement | collecter l'état technique et les preuves |
| `p5.sh finalize` | localement | contrôler les livrables et preuves attendus |
| `p5.sh cleanup` | **destructif AWS** | détruire `3 → 2 → 1` puis auditer AWS |
| `p5.sh logs` | non sur AWS | afficher les journaux disponibles |
| `p5.sh guide` | non | choisir le parcours adapté à la situation |
| `p5.sh docs` | non | afficher la carte documentaire |

Référence exhaustive : [`docs/CENTRE_DE_COMMANDE.md`](docs/CENTRE_DE_COMMANDE.md).

### Le principe de convergence

```text
observer l'état réel
        ↓
calculer le delta
        ↓
aucun delta ? ── oui ──► ne rien modifier
        │
        non
        ↓
présenter le changement
        ↓
confirmer la mutation
        ↓
appliquer uniquement le delta
        ↓
vérifier le résultat
        ↓
journaliser et conserver les preuves utiles
```

Une automatisation sûre doit pouvoir être relancée sans supposer que « tout est vide ».

## Exercice 1 — Terraform, Ansible et Angular/NGINX

![Exercice 1 — infrastructure et déploiement](docs/schemas/exercice-1.svg)

```bash
bash scripts/commands/p5.sh ex1
```

### Responsabilités

```text
application/angular/
      │ npm build
      ▼
artefact Angular
      │
      ├──────────────────────────────┐
      │                              │
terraform/exercice-1/                │
      │ VPC + réseau + SG + EC2      │
      ▼                              ▼
outputs Terraform ───────────────► Ansible
                                     │
                                     ▼
                             NGINX + Angular
```

**Terraform** crée l'infrastructure. **Ansible** configure l'EC2 et déploie l'application. Cette frontière est volontaire : Terraform n'est pas utilisé pour copier les fichiers Angular sur le serveur.

Résultats attendus :

```text
Terraform : aucun delta après convergence
Ansible   : changed=0 | unreachable=0 | failed=0 au second passage
HTTP      : application Angular servie par NGINX
Logs      : access.log réel collecté pour l'exercice 2
```

Guide : [`docs/exercices/01-terraform-ansible.md`](docs/exercices/01-terraform-ansible.md).

## Exercice 2 — Amazon OpenSearch

![Exercice 2 — logs vers OpenSearch](docs/schemas/exercice-2.svg)

```bash
bash scripts/commands/p5.sh ex2
```

Le pipeline est :

```text
sample versionné ──────────────┐
                               ├──► parsing / typage → Bulk API → Amazon OpenSearch
access.log réel de l'ex. 1 ────┘                              │
                                                             ▼
                                                   OpenSearch Dashboards
```

Le dépôt automatise la préparation des données, l'import et les contrôles techniques. La construction et la vérification visuelle des trois visualisations et du dashboard restent un **checkpoint humain** : `--yes` ne crée pas une preuve à la place de l'opérateur.

Guide : [`docs/exercices/02-opensearch.md`](docs/exercices/02-opensearch.md).

## Exercice 3 — HAProxy et résilience

![Exercice 3 — HAProxy et résilience](docs/schemas/exercice-3.svg)

```bash
bash scripts/commands/p5.sh ex3
```

L'exercice 3 réutilise le réseau de l'exercice 1.

```text
Internet
   │
   ▼
HAProxy EC2
   │ round-robin + health checks
   ├───────────────┐
   ▼               ▼
backend 1       backend 2
Docker          Docker
nginxdemos      nginxdemos
```

La preuve doit montrer l'état sain, la panne contrôlée d'un backend, le maintien du service et la réintégration après restauration.

Guide : [`docs/exercices/03-haproxy.md`](docs/exercices/03-haproxy.md).

## Preuves, CI et réalité AWS

Trois niveaux ne doivent pas être confondus :

| Élément | Ce qu'il prouve | Ce qu'il ne prouve pas |
| --- | --- | --- |
| code Terraform/Ansible | l'intention d'automatisation | que les ressources ont réellement convergé sur AWS |
| CI verte | cohérence, syntaxe, tests et contrats du dépôt | qu'un lab AWS réel a été exécuté |
| preuve runtime AWS | résultat réellement observé | qu'elle est automatiquement prête à être publiée |

Les traces runtime restent locales sous `logs/` et `proofs/runtime/`. Avant publication, sélectionner les éléments utiles, les contextualiser et retirer les informations sensibles inutiles.

Référence : [`docs/contrat-preuves-automatiques.md`](docs/contrat-preuves-automatiques.md).

## Finaliser puis fermer le lab AWS

![Finalisation, preuves et nettoyage AWS](docs/schemas/finalisation/finalisation.svg)

Avant toute destruction :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Une fois les preuves relues et les livrables validés :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre de fermeture :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, ne pas conclure que les ressources facturables ont toutes disparu.

## Sources de vérité techniques

La documentation explique le projet ; les fichiers ci-dessous définissent son comportement réel.

| Sujet | Source de vérité |
| --- | --- |
| environnement WSL2 attendu | `environment/wsl2/README.md` + contrôles de `bootstrap-wsl2.sh` |
| versions du runtime P5 | `environment/versions.env` |
| orchestration et commandes | `scripts/commands/p5.sh` |
| infrastructure exercice 1 | `terraform/exercice-1/` |
| configuration NGINX/Angular | `ansible/playbooks/deploy.yml` + `ansible/files/` |
| sources applicatives | `application/angular/` |
| infrastructure OpenSearch | `terraform/exercice-2/` |
| pipeline de logs | `convert-nginx-logs.py`, `import-opensearch-data.sh`, `verify-opensearch-data.sh` |
| infrastructure HAProxy | `terraform/exercice-3/` + `haproxy.cfg.tpl` |
| non-régression | `scripts/tools/audit_non_regression.py` + `.github/workflows/` |

La matrice détaillée documentation ↔ code est maintenue dans [`docs/MATRICE_TRACABILITE.md`](docs/MATRICE_TRACABILITE.md).

## Documentation

Portail : [`docs/README.md`](docs/README.md).

| Besoin | Document |
| --- | --- |
| comprendre le projet sans prérequis implicite | [Parcours débutant](docs/01-parcours-debutant.md) |
| exécuter de A à Z | [Runbook d'exécution](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| choisir le bon runbook | [Catalogue des runbooks](docs/runbooks/README.md) |
| comprendre l'architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| comprendre une commande | [Centre de commande](docs/CENTRE_DE_COMMANDE.md) |
| reprendre après interruption | [Convergence et réexécution](docs/convergence-et-reexecution.md) |
| diagnostiquer | [Troubleshooting](docs/troubleshooting.md) |
| comprendre le vocabulaire | [Glossaire](docs/GLOSSAIRE.md) |
| préparer les preuves | [Livrables](docs/livrables/README.md) |
| préparer la soutenance | [Soutenance](docs/05-soutenance.md) |
| vérifier la fidélité documentation/code | [Matrice de traçabilité](docs/MATRICE_TRACABILITE.md) |
| connaître les règles éditoriales | [Conventions documentaires](docs/CONVENTIONS_DOCUMENTAIRES.md) |

## Sécurité

Le projet applique notamment :

- `allowed_account_ids` pour verrouiller le compte AWS attendu ;
- une identité AWS non root pour le lab ;
- SSH et OpenSearch limités à l'IPv4 publique d'administration `/32` ;
- IMDSv2 obligatoire sur les EC2 ;
- volumes racine chiffrés ;
- HTTPS, TLS et chiffrement OpenSearch ;
- budget AWS contrôlé avant déploiement ;
- exclusion Git des states, vrais `tfvars`, clés, inventaires et preuves runtime ;
- sauvegarde locale confidentielle du state avant les mutations Terraform orchestrées ;
- confirmations humaines pour les changements sensibles.

Voir [`SECURITY.md`](SECURITY.md).

## Périmètre

Le P5 couvre **exactement trois exercices** : Terraform/Ansible, OpenSearch et HAProxy.

Kubernetes, Helm, Prometheus, Grafana et Vault ne font pas partie du projet. GitHub Actions est un mécanisme de qualité et de non-régression, pas un quatrième exercice.
