# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt fournit un lab DevOps reproductible et **convergent** permettant de :

- provisionner une infrastructure AWS avec Terraform ;
- déployer une application Angular avec Ansible et NGINX ;
- exploiter des logs dans Amazon OpenSearch ;
- démontrer la haute disponibilité avec HAProxy et deux backends ;
- relancer le projet sans réinstaller, recréer ou réécrire inutilement ce qui est déjà conforme.

> **Périmètre : 100 % AWS.** La VM Ubuntu Server est le poste de contrôle DevOps.
> Les infrastructures évaluées sont créées dans AWS.

> **Principe général :** inspecter → comparer → corriger uniquement le delta → vérifier → journaliser.

## Démarrage recommandé

Après avoir cloné le dépôt :

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Pour observer l'état réel **sans aucune mutation** :

```bash
bash scripts/commands/p5.sh inspect
```

Pour exécuter le parcours complet :

```bash
bash scripts/commands/p5.sh all
```

Pour suivre l'exécution **pas à pas**, avec les résultats attendus, les checkpoints,
la reprise et la procédure de diagnostic par logs :
[Runbook d'exécution guidée A → Z](docs/RUNBOOK_EXECUTION_GUIDEE.md).

Sur une VM neuve, `p5.sh` vérifie d'abord ce qui est déjà présent. Le bootstrap ne corrige que les outils, paquets ou versions manquants ou incorrects. Si l'ajout au groupe Docker impose une nouvelle session, le script demande une reconnexion puis il suffit de relancer la même commande.

Pour ouvrir le menu :

```bash
bash scripts/commands/p5.sh
```

Pour automatiser uniquement les confirmations automatisables :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne valide jamais à la place de l'opérateur :

- les vérifications de sécurité du compte AWS ;
- la preuve visuelle du dashboard OpenSearch ;
- la destruction finale protégée par `DETRUIRE`.

## Convergence et réexécution

Le projet est conçu pour être relancé plusieurs fois sans repartir aveuglément de zéro.

```text
État réel
   ↓
Inspection
   ↓
Comparaison état réel ↔ état attendu
   ↓
Conforme ? ── oui ──► aucune mutation
   │
   non
   ↓
Correction du delta uniquement
   ↓
Nouvelle vérification
   ↓
Verdict + log
```

Concrètement :

- une VM déjà conforme n'est pas réinstallée ;
- une session AWS encore valide est réutilisée ;
- les `terraform.tfvars` identiques ne sont pas réécrits ;
- l'inventaire Ansible identique n'est pas réécrit ;
- l'artefact Angular peut être réutilisé si les sources et dépendances n'ont pas changé ;
- un budget AWS déjà conforme n'est pas recréé ;
- les documents OpenSearch déjà présents ne sont pas réimportés inutilement ;
- un état Terraform déjà vide n'est pas détruit une seconde fois.

Les **tests fonctionnels**, eux, peuvent être rejoués volontairement : HTTP, Ansible, agrégations OpenSearch, round-robin, failover et diagnostics servent à vérifier l'état réel actuel et non à supposer qu'un ancien `OK` est encore vrai.

Référence complète : [Convergence et réexécution](docs/convergence-et-reexecution.md).

## Terraform : aucune mutation sur plan vide

Pour chaque exercice, l'orchestrateur initialise Terraform puis lance un plan différentiel avec rafraîchissement de l'état AWS.

```text
terraform init
      ↓
terraform plan -detailed-exitcode
      ↓
0 = aucun delta  ──► aucun apply
2 = delta réel   ──► affichage du plan → confirmation → apply
1 = erreur       ──► arrêt
```

Après un `apply`, un nouveau plan est exécuté pour vérifier que l'infrastructure a réellement convergé.

Cela signifie qu'une relance de `p5.sh all` ne doit pas recréer un VPC, une EC2, OpenSearch ou HAProxy lorsque Terraform constate que l'état réel correspond déjà à la configuration.

## Authentification AWS automatisée

Le projet utilise le profil final `p5-lab` et privilégie des credentials temporaires.

Le parcours d'authentification peut :

- réutiliser une session existante ;
- renouveler une session connue ;
- utiliser `aws login --remote` depuis une VM sans navigateur ;
- utiliser IAM Identity Center / SSO ;
- encapsuler un profil temporaire existant via `credential_process` pour Terraform.

Le projet refuse volontairement l'utilisation quotidienne du compte AWS root et ne stocke aucun mot de passe AWS dans le dépôt.

## Ce que fait `p5.sh all`

```text
Inspection / convergence VM
        ↓
Authentification AWS
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
Terraform → Amazon OpenSearch
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

Le mode `all` **ne détruit pas** automatiquement AWS. Les ressources restent disponibles pour la démonstration, les captures et la soutenance.

## Centre de commande

| Commande | Rôle |
| --- | --- |
| `p5.sh` | menu interactif |
| `p5.sh inspect` | observe l'état réel sans mutation |
| `p5.sh prepare` | inspecte puis converge VM, AWS, budget, tfvars et garde-fous |
| `p5.sh status` | contrôles de préparation sans création de ressource AWS |
| `p5.sh ex1` | converge Terraform + Ansible + Angular/NGINX puis vérifie |
| `p5.sh ex2` | converge OpenSearch et les données puis vérifie les agrégations |
| `p5.sh ex3` | converge HAProxy + backends puis teste round-robin et failover |
| `p5.sh all` | exécute le parcours technique complet |
| `p5.sh finalize` | diagnostics et contrôle strict des livrables |
| `p5.sh logs` | retrouve les journaux de session |
| `p5.sh cleanup` | destruction 3 → 2 → 1 puis audit AWS |

Exemples :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh status --full-validation
bash scripts/commands/p5.sh all
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

La dépendance critique reste :

```text
Exercice 1 ── VPC + sous-réseaux + clé EC2 ──► Exercice 3
```

L'exercice 1 ne doit donc pas être détruit avant la fin de l'exercice 3.

Référence : [Architecture et flux](docs/architecture-et-flux.md).

## Exercice 1 — Terraform, Ansible, NGINX et Angular

L'orchestrateur :

1. vérifie si l'artefact Angular doit réellement être reconstruit ;
2. initialise Terraform et calcule le delta réel ;
3. n'applique rien si le plan est vide ;
4. applique uniquement le delta après confirmation ;
5. génère l'inventaire Ansible uniquement s'il diffère ;
6. attend SSH et cloud-init ;
7. teste Ansible ;
8. converge Angular/NGINX ;
9. rejoue le playbook et exige `changed=0`, `unreachable=0`, `failed=0` ;
10. vérifie HTTP, bundle, SPA et en-têtes ;
11. génère le trafic puis récupère le vrai `access.log` NGINX.

```bash
bash scripts/commands/p5.sh ex1
```

Guide : [Terraform + Ansible](docs/exercices/01-terraform-ansible.md).

## Exercice 2 — NGINX et Amazon OpenSearch

Le véritable exercice utilise **Amazon OpenSearch Service** créé par Terraform. Aucun Elasticsearch/OpenSearch permanent n'est requis sur la VM Ubuntu pour le lab AWS.

Le parcours utilise deux sources :

- un échantillon versionné pour garantir la distribution temporelle des visualisations ;
- le vrai log NGINX collecté dans l'exercice 1 pour prouver la chaîne `NGINX → Bulk → OpenSearch`.

Le script compare le template OpenSearch attendu et les identifiants déterministes des documents avant mutation afin d'éviter les réimportations inutiles.

```bash
bash scripts/commands/p5.sh ex2
```

La création des visualisations et les captures restent manuelles, car elles font partie de la preuve pédagogique.

Guide : [OpenSearch](docs/exercices/02-elk-opensearch.md).

## Exercice 3 — HAProxy, panne et reprise

Terraform converge HAProxy et les deux backends. Une infrastructure déjà conforme n'est pas recréée. Les tests round-robin et panne/reprise sont ensuite rejoués pour vérifier le fonctionnement actuel.

```bash
bash scripts/commands/p5.sh ex3
```

Guide : [HAProxy](docs/exercices/03-haproxy.md).

## Reprise après interruption

Après une interruption ou une fermeture de terminal :

```bash
bash scripts/commands/p5.sh all
```

Le projet reprend à partir de l'état réellement présent : Terraform rafraîchit AWS, Ansible reste idempotent et les contrôles fonctionnels sont rejoués.

Il ne faut jamais supprimer manuellement les états Terraform tant que les ressources AWS associées existent.

## Logs et preuves

Chaque exécution crée un journal principal et un journal complet par étape :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Les preuves pédagogiques sont séparées :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Les logs et preuves runtime sont ignorés par Git par défaut.

```bash
bash scripts/commands/p5.sh logs
```

## Finalisation

Après les captures et l'insertion des preuves réelles :

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

Un état Terraform déjà vide est ignoré. La destruction réelle exige toujours la saisie exacte `DETRUIRE`.

Le projet n'est considéré fermé qu'après :

```text
NETTOYAGE AWS COMPLET
```

## Validation et niveau de preuve

La CI GitHub vérifie notamment :

- Bash et ShellCheck ;
- contrat de l'orchestrateur ;
- contrat de convergence/réexécution ;
- authentification AWS simulée sans mutation réelle ;
- Angular et TypeScript ;
- vrai NGINX avec le build Angular ;
- OpenSearch local, Bulk et agrégations ;
- HAProxy local, round-robin, panne et reprise ;
- Terraform `fmt`, `init -backend=false` et `validate` ;
- Ansible ;
- YAML ;
- Markdown et liens ;
- secrets et non-régression.

Une CI verte prouve la cohérence du dépôt et les intégrations locales, **pas un déploiement réel sur le compte AWS de l'opérateur**. Le test d'intégration final reste l'exécution de `p5.sh all` sur la VM avec une session AWS réelle.

## Sécurité

Le dépôt protège notamment contre :

- mauvais compte AWS via `allowed_account_ids` ;
- utilisation du compte root ;
- credentials AWS longue durée dans le parcours normal ;
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

Les six schémas pédagogiques restent intégrés au README :

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
| Runbook guidé pas à pas | [Guide d'exécution A → Z](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| Convergence et réexécution | [docs/convergence-et-reexecution.md](docs/convergence-et-reexecution.md) |
| Exécuter de A à Z | [Runbook](docs/01-parcours-debutant.md) |
| Préparer la VM | [Préparation environnement](docs/00-preparation-environnement.md) |
| Préparer AWS | [Préparation compte AWS](docs/00b-preparation-compte-aws.md) |
| Architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| Exercice 1 | [Terraform + Ansible](docs/exercices/01-terraform-ansible.md) |
| Exercice 2 | [OpenSearch](docs/exercices/02-elk-opensearch.md) |
| Exercice 3 | [HAProxy](docs/exercices/03-haproxy.md) |
| Validation/finalisation | [Preuves et nettoyage](docs/validation-preuves-nettoyage.md) |
| Scripts et logs | [scripts/README.md](scripts/README.md) |
| Dépannage | [Troubleshooting](docs/troubleshooting.md) |
| Terraform | [terraform/README.md](terraform/README.md) |

## Structure du dépôt

```text
p5_Openclassrooms/
├── .github/                 # CI, sécurité, non-régression, Dependabot
├── .p5/                     # état local de convergence, ignoré par Git
├── application/angular/     # application Angular réelle
├── ansible/                 # artefact, NGINX, inventaire exemple, playbook
├── aws/                     # politique IAM et budget
├── environment/             # versions et configuration AWS d'exemple
├── docs/                    # documentation et livrables
├── proofs/                  # convention ; runtime ignoré
├── logs/                    # journaux opérateur locaux, ignorés
├── scripts/
│   ├── commands/            # p5.sh, inspect-state.sh et commandes spécialisées
│   ├── lib/                 # runtime du centre de commande
│   ├── tests/               # intégrations locales et contrats CI
│   └── tools/               # conversion, génération et audits
└── terraform/
    ├── exercice-1/
    ├── exercice-2/
    └── exercice-3/
```

## État des livrables

Le code, les configurations, l'automatisation et les contrôles sont versionnés. Les fichiers de `docs/livrables/` restent des gabarits tant que les preuves du véritable lab AWS n'y ont pas été insérées, relues et anonymisées.

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
