# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt fournit un lab DevOps reproductible permettant de provisionner une
infrastructure AWS avec Terraform, déployer une application Angular avec Ansible
et NGINX, exploiter des logs dans Amazon OpenSearch, puis démontrer la haute
disponibilité avec HAProxy et deux backends.

Le projet peut être exécuté depuis un **centre de commande unique** sans recopier
manuellement toutes les commandes du runbook. Les commandes détaillées restent
documentées pour comprendre, diagnostiquer ou rejouer une étape isolée.

> **Périmètre : 100 % AWS.** La VM Ubuntu Server est le poste de contrôle DevOps.
> Les infrastructures évaluées sont réellement créées dans AWS.

> **Coûts :** aucune ressource n'est supposée gratuite. Le parcours prépare un
> budget d'alerte, affiche les plans Terraform avant `apply` et impose un
> nettoyage contrôlé après la démonstration.

## Démarrage recommandé

Après avoir cloné le dépôt :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/p5.sh all
```

C'est le **parcours recommandé**.

Sur une VM neuve, `p5.sh` détecte les outils manquants et propose le bootstrap.
Si Docker/NVM nécessitent un nouveau shell, le script demande une reconnexion puis
il suffit de relancer exactement la même commande :

```bash
bash scripts/commands/p5.sh all
```

Pour ouvrir le menu :

```bash
bash scripts/commands/p5.sh
```

Pour automatiser les confirmations qui peuvent l'être sans supprimer les
protections humaines :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne valide jamais à la place de l'opérateur :

- les vérifications de sécurité du compte AWS ;
- la preuve visuelle du dashboard OpenSearch ;
- la destruction finale protégée par `DETRUIRE`.

## Ce que fait `p5.sh all`

```text
Préparation VM / AWS
        ↓
configuration locale + tfvars + budget
        ↓
GO AWS + GO TERRAFORM
        ↓
Exercice 1
Terraform → EC2 → Ansible → NGINX → Angular
                     ↓
             seconde exécution Ansible
                     ↓
             idempotence changed=0
                     ↓
             logs NGINX réels
        ↓
Exercice 2
Terraform → OpenSearch
        ↓
échantillon reproductible + logs NGINX réels
        ↓
mappings + agrégations
        ↓
dashboard manuel et captures
        ↓
Exercice 3
Terraform → HAProxy → 2 backends
        ↓
round-robin → panne réelle → reprise
        ↓
diagnostics + structure des livrables
```

Le mode `all` **ne détruit pas** automatiquement AWS. Les ressources restent
disponibles pour la démonstration, les captures et la soutenance.

## Centre de commande

| Commande | Rôle |
| --- | --- |
| `p5.sh` | menu interactif |
| `p5.sh prepare` | prépare VM, AWS, budget, tfvars et précontrôles |
| `p5.sh status` | contrôles sans création de ressource AWS |
| `p5.sh ex1` | Terraform + Ansible + Angular/NGINX + idempotence + logs |
| `p5.sh ex2` | OpenSearch + imports + agrégations + checkpoint dashboard |
| `p5.sh ex3` | HAProxy + round-robin + panne + réintégration |
| `p5.sh all` | exécute le parcours technique complet |
| `p5.sh finalize` | diagnostics et contrôle strict des livrables |
| `p5.sh logs` | retrouve les journaux de session |
| `p5.sh cleanup` | destruction 3 → 2 → 1 puis audit AWS |

Exemple :

```bash
bash scripts/commands/p5.sh status --full-validation
```

## Architecture

```text
VM Ubuntu Server — poste DevOps
│
├─ Terraform
├─ Ansible
├─ Angular / Node.js
├─ AWS CLI
├─ Docker
└─ p5.sh + scripts spécialisés
          │
          ▼
AWS — us-east-1 par défaut
│
├─ Exercice 1
│  ├─ VPC + 2 sous-réseaux publics
│  ├─ EC2 Ubuntu
│  └─ Ansible → NGINX → Angular
│               │
│               └─ access.log réel ─────► Exercice 2
│                                          Amazon OpenSearch
│                                          └─ Dashboards
│
└─ Exercice 3
   ├─ réutilise le réseau de l'exercice 1
   ├─ EC2 HAProxy
   └─ 2 EC2 → Docker → nginxdemos/hello
```

La dépendance critique est :

```text
Exercice 1 ── VPC + sous-réseaux + clé EC2 ──► Exercice 3
```

L'exercice 1 ne doit donc pas être détruit avant la fin de l'exercice 3.

Référence : [architecture et flux](docs/architecture-et-flux.md).

## Les trois exercices

### Exercice 1 — Terraform, Ansible, NGINX et Angular

L'orchestrateur :

1. construit le véritable artefact Angular ;
2. initialise et planifie Terraform ;
3. affiche le plan ;
4. applique après confirmation ;
5. génère automatiquement l'inventaire Ansible depuis `web_public_ip` ;
6. attend que SSH et cloud-init soient prêts ;
7. teste Ansible ;
8. déploie Angular/NGINX ;
9. rejoue le playbook et exige `changed=0`, `unreachable=0`, `failed=0` ;
10. vérifie HTTP, bundle, SPA et en-têtes ;
11. génère le trafic puis récupère le vrai `access.log` NGINX.

Commande :

```bash
bash scripts/commands/p5.sh ex1
```

Guide détaillé :
[Terraform + Ansible](docs/exercices/01-terraform-ansible.md).

### Exercice 2 — NGINX et Amazon OpenSearch

Le parcours utilise deux sources complémentaires :

- l'échantillon versionné garantit la distribution temporelle nécessaire aux
  visualisations sur 12 heures ;
- le log NGINX réel collecté dans l'exercice 1 prouve la chaîne technique
  `NGINX → conversion Bulk → OpenSearch`.

Les documents utilisent des identifiants déterministes lors de la conversion,
ce qui permet de rejouer les mêmes imports sans créer de doublons pour une même
ligne de source.

Commande :

```bash
bash scripts/commands/p5.sh ex2
```

La création des trois visualisations et les captures restent manuelles, car elles
font partie de la preuve pédagogique.

Guide détaillé :
[OpenSearch](docs/exercices/02-elk-opensearch.md).

### Exercice 3 — HAProxy, panne et reprise

L'orchestrateur déploie HAProxy et deux backends, attend le service HTTP, vérifie
le round-robin puis réalise un arrêt contrôlé d'un backend avant sa
réintégration.

Commande :

```bash
bash scripts/commands/p5.sh ex3
```

Guide détaillé :
[HAProxy](docs/exercices/03-haproxy.md).

## Reprise après interruption

`p5.sh` détecte les états Terraform locaux existants. Une relance ne repart donc
pas aveuglément de zéro : Terraform réévalue l'état, Ansible reste idempotent et
les contrôles fonctionnels sont rejoués.

Après une interruption :

```bash
bash scripts/commands/p5.sh all
```

Il ne faut jamais supprimer manuellement les états Terraform tant que les
ressources AWS associées existent.

## Logs et preuves

Deux familles sont volontairement séparées.

### Logs opérateur

Chaque exécution crée :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Chaque étape affiche sa commande, son journal et son verdict. Les nouveaux logs
sont créés avec un `umask 077` et les `.log` sont ignorés par Git.

```bash
bash scripts/commands/p5.sh logs
```

### Preuves pédagogiques

Les preuves techniques restent sous :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Elles sont privées par défaut et doivent être relues/anonymisées avant toute
publication.

## Finalisation

Après les captures et l'insertion des preuves réelles dans les trois livrables :

```bash
bash scripts/commands/p5.sh finalize
```

Le contrôle strict doit aboutir à :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## Nettoyage AWS

Lorsque la démonstration est terminée :

```bash
bash scripts/commands/p5.sh cleanup
```

L'ordre reste obligatoirement :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Le script spécialisé de destruction exige la saisie exacte `DETRUIRE`.

Le projet n'est considéré fermé qu'après :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste volontairement actif afin de détecter une éventuelle ressource
oubliée.

## Validation et niveau de preuve

La CI GitHub valide notamment :

- Bash et ShellCheck ;
- contrat de l'orchestrateur sans mutation AWS ;
- Angular et TypeScript ;
- vrai NGINX avec le build Angular ;
- OpenSearch local, Bulk et agrégations ;
- HAProxy local, round-robin, panne et reprise ;
- Terraform `fmt`, `init -backend=false` et `validate` ;
- Ansible ;
- YAML ;
- Markdown et liens ;
- secrets et non-régression.

Cette CI prouve la cohérence du dépôt et des intégrations locales. Elle **ne peut
pas prouver à elle seule un déploiement réel sur le compte AWS de l'opérateur**.
Le test d'intégration final reste l'exécution de `p5.sh all` sur la VM avec une
session AWS valide.

Validation locale complète :

```bash
bash scripts/commands/p5.sh status --full-validation
```

## Sécurité

Le dépôt protège notamment contre :

- mauvais compte AWS via `allowed_account_ids` ;
- utilisation du compte root ;
- SSH/OpenSearch ouverts au monde au lieu d'un `/32` ;
- EC2 sans IMDSv2 ;
- volumes racine non chiffrés ;
- OpenSearch sans HTTPS/TLS ;
- tfvars désynchronisés ;
- secrets ou fichiers locaux suivis par Git ;
- destruction implicite ;
- validation automatique d'une preuve humaine.

Politique complète : [SECURITY.md](SECURITY.md).

## Schémas du parcours

Les six schémas pédagogiques restent référencés depuis le point d'entrée du
projet :

- [Vue d'ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation VM et AWS](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

## Documentation

| Besoin | Document |
| --- | --- |
| Portail documentaire | [docs/README.md](docs/README.md) |
| Exécuter de A à Z | [Runbook](docs/01-parcours-debutant.md) |
| Architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| Exercice 1 | [Terraform + Ansible](docs/exercices/01-terraform-ansible.md) |
| Exercice 2 | [OpenSearch](docs/exercices/02-elk-opensearch.md) |
| Exercice 3 | [HAProxy](docs/exercices/03-haproxy.md) |
| Validation/finalisation | [Preuves et nettoyage](docs/validation-preuves-nettoyage.md) |
| Scripts et logs | [scripts/README.md](scripts/README.md) |
| Dépannage | [Troubleshooting](docs/troubleshooting.md) |
| Terraform | [terraform/README.md](terraform/README.md) |

Les procédures manuelles détaillées restent disponibles dans les guides afin de
comprendre chaque technologie et de pouvoir rejouer une opération isolée. Elles
sont désormais la **voie de référence détaillée**, tandis que `p5.sh` est la voie
d'exécution normale.

## Structure du dépôt

```text
p5_Openclassrooms/
├── .github/                 # CI, sécurité, non-régression, Dependabot
├── application/angular/     # application Angular réelle
├── ansible/                 # artefact, NGINX, inventaire exemple, playbook
├── aws/                     # politique IAM et budget
├── environment/             # versions et configuration AWS d'exemple
├── docs/                    # documentation et livrables
├── proofs/                  # convention ; runtime ignoré
├── logs/                    # journaux opérateur locaux, ignorés
├── scripts/
│   ├── commands/            # p5.sh et commandes spécialisées
│   ├── lib/                 # runtime du centre de commande
│   ├── tests/               # intégrations locales et contrat orchestrateur
│   └── tools/               # conversion, génération et audits
└── terraform/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## État des livrables

Le code, les configurations, l'automatisation et les contrôles sont versionnés.
Les fichiers de `docs/livrables/` restent des gabarits tant que les preuves du
véritable lab AWS n'y ont pas été insérées, relues et anonymisées.

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
