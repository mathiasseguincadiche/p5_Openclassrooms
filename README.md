# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt présente un lab DevOps reproductible permettant de provisionner une
infrastructure AWS avec Terraform, déployer une application Angular avec Ansible
et NGINX, transformer et visualiser des logs dans Amazon OpenSearch, puis tester
la disponibilité d’un service avec HAProxy et deux backends.

L’objectif n’est pas seulement de fournir du code : le dépôt documente le
**parcours complet**, les contrôles, les preuves à produire, les dépendances entre
les exercices et le nettoyage final.

> **Périmètre retenu : 100 % AWS.** La VM Ubuntu Server sert de poste de contrôle.
> Les infrastructures évaluées sont créées dans AWS.

> **Coûts :** aucune ressource ne doit être supposée gratuite. Le projet utilise
> un budget d’alerte et impose la relecture des plans puis la destruction des
> ressources après les démonstrations.

## Ce que démontre le projet

| Domaine | Réalisation |
| --- | --- |
| Infrastructure as Code | VPC, réseau, EC2 et OpenSearch avec Terraform |
| Configuration | Déploiement idempotent d’Angular/NGINX avec Ansible |
| Reproductibilité | versions fixées, verrou npm et build Angular comparé en CI |
| Observabilité | logs NGINX → Bulk NDJSON → OpenSearch → dashboard |
| Haute disponibilité | HAProxy `roundrobin`, health checks, panne et reprise |
| Sécurité | compte AWS verrouillé, accès `/32`, IMDSv2, chiffrement, audit secrets |
| Qualité | CI, tests locaux, non-régression et contrôles de structure |
| Exploitation | diagnostics, preuves, destruction ordonnée et audit AWS final |

## Architecture en un coup d’œil

```text
VM Ubuntu Server 26.04 — poste DevOps
│
├─ Terraform ───────────────────────────────────────────────┐
├─ Ansible                                                 │
├─ Angular / Node.js                                       │
├─ AWS CLI                                                 │
├─ Docker                                                  │
└─ scripts de contrôle                                     │
                                                           ▼
AWS — us-east-1
│
├─ Exercice 1
│  ├─ VPC + 2 sous-réseaux publics
│  ├─ EC2 Ubuntu
│  └─ Ansible → NGINX → Angular
│               │
│               └─ logs NGINX ──────────► Exercice 2
│                                          OpenSearch
│                                          └─ Dashboard
│
└─ Exercice 3
   ├─ réutilise le réseau de l’exercice 1
   ├─ EC2 HAProxy
   └─ 2 EC2 → Docker → nginxdemos/hello
```

La dépendance importante est :

```text
Exercice 1 ── réseau + clé EC2 ──► Exercice 3
```

Donc l’exercice 1 ne doit pas être détruit avant la fin de l’exercice 3.

Documentation d’architecture :
[`docs/architecture-et-flux.md`](docs/architecture-et-flux.md).

## Parcours du projet

| Phase | Objectif | Condition de sortie |
| --- | --- | --- |
| 0A — VM | installer et valider le poste DevOps | étape 0A validée |
| 0B — AWS | identité, sécurité, quotas, IP et budget | `GO AWS` + `GO TERRAFORM` |
| 1 — Déployer | Terraform + Ansible + NGINX + Angular | application réellement servie |
| 2 — Observer | importer les logs et créer le dashboard | données et 3 visualisations validées |
| 3 — Résister | round-robin, panne et réintégration | failover validé |
| Finaliser | preuves, livrables et destruction | `NETTOYAGE AWS COMPLET` |

Le runbook détaillé est disponible dans
[`docs/01-parcours-debutant.md`](docs/01-parcours-debutant.md).

## Démarrage

### 1. Cloner et préparer la VM

```bash
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
./scripts/commands/bootstrap-ubuntu-server.sh
```

Après reconnexion :

```bash
./scripts/commands/setup.sh --check-only
```

### 2. Préparer AWS

Créer la configuration locale :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Cette configuration est la **source unique** des paramètres AWS du lab.

Générer les trois `terraform.tfvars` :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Créer le budget puis lancer les contrôles :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
```

Ne poursuivre qu’après :

```text
GO AWS
GO TERRAFORM
```

## Les trois exercices

### 1 — Terraform + Ansible + Angular

Terraform crée le réseau et une EC2 Ubuntu. Ansible installe NGINX et déploie le
build Angular réel sous `/var/www/p5`.

```bash
./scripts/commands/prepare-angular-artifact.sh
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
terraform -chdir=terraform/exercice-1 apply tfplan
```

Après préparation de l’inventaire :

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
./scripts/commands/verify-angular-deployment.sh
```

Le contrôle valide HTTP, le bundle Angular, le fallback SPA et les en-têtes
NGINX.

**Guide :**
[`docs/exercices/01-terraform-ansible.md`](docs/exercices/01-terraform-ansible.md)

### 2 — Logs NGINX + Amazon OpenSearch

Le dépôt peut utiliser l’échantillon versionné ou les vrais logs NGINX collectés
pendant l’exercice 1.

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-2
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 apply tfplan

./scripts/commands/import-opensearch-data.sh
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/verify-opensearch-data.sh
```

Les trois visualisations à construire manuellement dans OpenSearch Dashboards :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 des `url_path` par tranches de 12 h.

**Guide :**
[`docs/exercices/02-elk-opensearch.md`](docs/exercices/02-elk-opensearch.md)

### 3 — HAProxy + deux backends

L’exercice 3 réutilise le VPC et les sous-réseaux de l’exercice 1. Terraform
déploie une EC2 HAProxy et deux EC2 exécutant `nginxdemos/hello` dans Docker.

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-3
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 apply tfplan

./scripts/commands/test-haproxy-roundrobin.sh --requests 10
./scripts/commands/test-haproxy-failover.sh
./scripts/commands/test-haproxy-failover.sh --apply
```

HAProxy utilise :

```text
roundrobin
health check GET /
inter 3s
fall 3
rise 2
```

Le test réel arrête un backend, vérifie la continuité du service, redémarre le
backend puis confirme sa réintégration.

**Guide :**
[`docs/exercices/03-haproxy.md`](docs/exercices/03-haproxy.md)

## Preuves et livrables

Les sorties techniques sont conservées localement sous :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

Ce dossier est ignoré par Git et **privé par défaut**.

Les trois livrables sont structurés sous `docs/livrables/`. Le dépôt contrôle
leur structure mais n’invente aucune preuve d’exécution.

```bash
./scripts/commands/prepare-livrables.sh --structure-only
./scripts/commands/prepare-livrables.sh
```

Documentation :

- [preuves et publication](docs/validation-preuves-nettoyage.md) ;
- [gabarits des livrables](docs/livrables/README.md) ;
- [convention runtime](proofs/README.md).

## Sécurité et garde-fous

Le dépôt protège notamment contre :

- déploiement dans le mauvais compte AWS avec `allowed_account_ids` ;
- ouverture SSH/OpenSearch au monde entier avec l’accès `/32` ;
- EC2 sans IMDSv2 ;
- volumes racine non chiffrés ;
- endpoint OpenSearch sans HTTPS/TLS ;
- `terraform.tfvars` désynchronisés ;
- valeurs d’exemple non remplacées ;
- secrets ou fichiers locaux suivis par Git ;
- mutation implicite dans les scripts sensibles.

Plusieurs commandes utilisent un mode aperçu avant `--apply` :

```text
setup-aws-guardrails.sh
import-opensearch-data.sh
test-haproxy-failover.sh
```

Politique complète : [`SECURITY.md`](SECURITY.md).

## Validation

Validation locale :

```bash
./scripts/commands/validate.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

Avec OpenSearch local :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

GitHub Actions contrôle notamment :

- Angular, TypeScript et dépendances ;
- NGINX ;
- HAProxy ;
- OpenSearch local ;
- Terraform ;
- Ansible ;
- Bash, YAML, JSON et Markdown ;
- liens documentaires ;
- secrets ;
- contrat de non-régression.

## Nettoyage AWS

Le nettoyage suit obligatoirement :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Commande :

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

Le script de destruction exige la confirmation exacte `DETRUIRE`.

Le projet n’est considéré fermé qu’après :

```text
NETTOYAGE AWS COMPLET
```

Le budget reste volontairement actif pour détecter une ressource oubliée.

## Documentation

Pour comprendre le projet sans parcourir les fichiers au hasard :

| Besoin | Document |
| --- | --- |
| Point d’entrée complet | [Documentation](docs/README.md) |
| Comprendre l’architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| Exécuter de A à Z | [Runbook](docs/01-parcours-debutant.md) |
| Relier consignes, code et preuves | [Traçabilité](docs/02-correspondance-consignes-depot.md) |
| Préparer la VM | [Étape 0A](docs/00-preparation-environnement.md) |
| Préparer AWS | [Étape 0B](docs/00b-preparation-compte-aws.md) |
| Préparer la remise | [Preuves et nettoyage](docs/validation-preuves-nettoyage.md) |
| Diagnostiquer | [Troubleshooting](docs/troubleshooting.md) |
| Comprendre les scripts | [Scripts](scripts/README.md) |
| Comprendre Terraform | [Terraform](terraform/README.md) |

## Structure du dépôt

```text
p5_Openclassrooms/
├── .github/                 # CI, sécurité, non-régression, Dependabot
├── application/angular/     # véritable application Angular
├── ansible/                 # inventaire exemple, artefact, NGINX, playbook
├── aws/                     # politique IAM et budget du lab
├── environment/             # versions et configuration AWS d’exemple
├── docs/                    # documentation principale et livrables
├── proofs/                  # convention des preuves ; runtime ignoré
├── scripts/
│   ├── commands/            # commandes opérateur
│   ├── tests/               # intégrations locales Docker
│   └── tools/               # conversion, génération et audits
└── terraform/
    ├── exercice-1/          # réseau + cible Angular
    ├── exercice-2/          # Amazon OpenSearch
    └── exercice-3/          # HAProxy + 2 backends
```

## Schémas

Les six SVG du projet sont autonomes, légers et sans Mermaid :

- [Vue d’ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

## État des livrables

Le code, les configurations et les contrôles sont versionnés. Les documents de
`docs/livrables/` restent des **gabarits** tant que les preuves du véritable lab
n’y ont pas été insérées, relues et anonymisées.

## Licence

Ce dépôt est distribué sous licence [MIT](LICENSE).
