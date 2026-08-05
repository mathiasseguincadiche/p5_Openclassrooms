# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt contient l’**implémentation exécutable** du projet P5 et son parcours de validation. Les trois exercices officiels sont reliés dans une chaîne unique : préparer le lab, valider AWS, déployer, observer, tester la disponibilité, constituer les preuves, puis supprimer les ressources.

> **Périmètre : 100 % AWS.** La VM Ubuntu Server 26.04 est le poste DevOps. Terraform, Ansible, AWS CLI, Angular, Docker et les scripts de preuve s’y exécutent ; les infrastructures évaluées sont créées dans AWS.

## Le projet en une vue

<p align="center">
  <img src="docs/schemas/vue-ensemble.svg" alt="Parcours complet du projet P5, du poste DevOps local au nettoyage AWS" width="960">
</p>

| Phase | Objectif | Validation |
| --- | --- | --- |
| **0 — Préparer** | Construire le poste DevOps et contrôler le compte AWS | `GO TERRAFORM` |
| **1 — Déployer** | Livrer la véritable application Angular sur EC2 | Application HTTP accessible |
| **2 — Observer** | Transformer les logs NGINX en visualisations OpenSearch | Dashboard exploitable |
| **3 — Résister** | Vérifier le round-robin, la panne et la reprise | Service disponible |
| **Finaliser** | Contrôler les preuves, détruire et auditer | `NETTOYAGE AWS COMPLET` |

### Navigation

[Étape 0](#étape-0--préparer-le-lab-et-aws) ·
[Exercice 1](#exercice-1--déployer-angular-avec-terraform-et-ansible) ·
[Exercice 2](#exercice-2--exploiter-les-logs-dans-opensearch) ·
[Exercice 3](#exercice-3--tester-haproxy-et-la-reprise) ·
[Finalisation](#finalisation--prouver-détruire-et-auditer) ·
[Validation continue](#validation-continue)

---

## Étape 0 — Préparer le lab et AWS

<p align="center">
  <img src="docs/schemas/etape-0.svg" alt="Fondations locales, accès AWS, garde-fous et porte GO TERRAFORM" width="900">
</p>

Cette étape prépare un poste DevOps reproductible et bloque les erreurs de compte, de région, de quota, de réseau ou de coût **avant** le premier `terraform plan`.

| Entrée | Contrôles | Résultat |
| --- | --- | --- |
| VM Ubuntu Server 26.04 | Terraform, Ansible, AWS CLI, Docker, Node.js 22.22.0 et outils système | Poste DevOps prêt |
| Compte AWS sécurisé | Profil, identité, région, quotas, budget et paramètres Terraform | Compte autorisé |
| Accès locaux | Clé SSH, permissions, `terraform.tfvars` et adresse `/32` | Accès prêts |

<details>
<summary><strong>Commandes de préparation</strong></summary>

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
# Reconnexion nécessaire pour Docker et NVM.
./scripts/commands/setup.sh --check-only

cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env

./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

</details>

**Verdict obligatoire :** `GO TERRAFORM`

Aucun `terraform apply` n’est lancé par les contrôles de préparation. La seule mutation volontaire est la création du budget avec `setup-aws-guardrails.sh --apply`.

**Guides :** [préparation de la VM](docs/00-preparation-environnement.md) · [préparation du compte AWS](docs/00b-preparation-compte-aws.md)

---

## Exercice 1 — Déployer Angular avec Terraform et Ansible

<p align="center">
  <img src="docs/schemas/exercice-1.svg" alt="Chaîne de livraison Angular, Terraform, EC2, Ansible et NGINX" width="920">
</p>

L’exercice construit le véritable artefact Angular, crée l’infrastructure AWS avec Terraform, puis configure l’instance EC2 avec Ansible et NGINX.

<details>
<summary><strong>1. Construire l’application</strong></summary>

```bash
./scripts/commands/prepare-angular-artifact.sh
```

La CI reconstruit l’application et compare exactement le résultat au contenu de `ansible/files/angular-app/`. Une page HTML témoin ne peut donc pas remplacer le build Angular.

</details>

<details>
<summary><strong>2. Créer l’infrastructure</strong></summary>

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
terraform -chdir=terraform/exercice-1 apply tfplan
```

Le plan doit être relu avant application : compte, région, réseau, instance, volume, clé SSH et coûts.

</details>

<details>
<summary><strong>3. Déployer avec Ansible</strong></summary>

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping

ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

</details>

<details>
<summary><strong>4. Vérifier et produire des logs</strong></summary>

```bash
./scripts/commands/verify-angular-deployment.sh
./scripts/commands/generate-nginx-traffic.sh
./scripts/commands/collect-nginx-access-log.sh
```

</details>

### Preuves attendues

- application Angular accessible en HTTP ;
- bundle JavaScript chargé et fallback SPA assuré par NGINX ;
- seconde exécution Ansible idempotente ;
- logs NGINX réels récupérés pour l’exercice 2.

**Guide :** [Terraform, Ansible, Angular et NGINX](docs/exercices/01-terraform-ansible.md)

---

## Exercice 2 — Exploiter les logs dans OpenSearch

<p align="center">
  <img src="docs/schemas/exercice-2.svg" alt="Pipeline des logs NGINX vers Amazon OpenSearch et ses trois visualisations" width="920">
</p>

Les logs NGINX sont convertis en Bulk NDJSON, validés par un mapping strict, importés dans OpenSearch puis exploités dans Discover et Dashboards.

<details>
<summary><strong>1. Valider et créer le domaine</strong></summary>

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-2

terraform -chdir=terraform/exercice-2 init
terraform -chdir=terraform/exercice-2 plan -out=tfplan
terraform -chdir=terraform/exercice-2 apply tfplan
```

</details>

<details>
<summary><strong>2. Préparer, importer et vérifier les données</strong></summary>

```bash
# Aperçu local, sans écriture dans OpenSearch.
./scripts/commands/import-opensearch-data.sh

# Import réel après vérification.
./scripts/commands/import-opensearch-data.sh --apply

# Contrôle non destructif des mappings et agrégations.
./scripts/commands/verify-opensearch-data.sh
```

Le dépôt fournit un échantillon de **64 événements**, répartis sur quatre tranches de douze heures. Les logs réels de l’exercice 1 peuvent également être fournis avec `--input`.

</details>

### Visualisations obligatoires

| Visualisation | Agrégation | Démonstration |
| --- | --- | --- |
| Donut | `http_method` | Répartition des verbes HTTP |
| Histogramme | somme de `bytes_sent` par 12 h | Volume de données envoyé |
| Top 5 temporel | `url_path` par 12 h | Requêtes les plus fréquentes |

La création des graphiques dans OpenSearch Dashboards reste volontairement manuelle : elle fait partie de la compréhension évaluée.

### Preuves attendues

- index et champs visibles dans Discover ;
- trois visualisations conformes et dashboard complet ;
- quatre captures lisibles ;
- aucune donnée sensible visible.

**Guide :** [logs NGINX et Amazon OpenSearch](docs/exercices/02-elk-opensearch.md)

---

## Exercice 3 — Tester HAProxy et la reprise

<p align="center">
  <img src="docs/schemas/exercice-3.svg" alt="Topologie HAProxy avec deux backends et scénario normal, panne, reprise" width="920">
</p>

HAProxy répartit les requêtes entre deux backends. Les scripts vérifient d’abord le round-robin, puis arrêtent volontairement un backend afin de prouver la continuité du service et sa réintégration.

<details>
<summary><strong>1. Valider et déployer</strong></summary>

```bash
./scripts/commands/pre-deployment-check.sh --stage exercice-3

terraform -chdir=terraform/exercice-3 init
terraform -chdir=terraform/exercice-3 plan -out=tfplan
terraform -chdir=terraform/exercice-3 apply tfplan
```

</details>

<details>
<summary><strong>2. Vérifier la répartition</strong></summary>

```bash
./scripts/commands/test-haproxy-roundrobin.sh
```

Le test doit observer les deux noms de serveur dans plusieurs réponses successives.

</details>

<details>
<summary><strong>3. Démontrer la panne et la reprise</strong></summary>

```bash
# Simulation et vérification préalable, sans arrêt de backend.
./scripts/commands/test-haproxy-failover.sh

# Démonstration réelle.
./scripts/commands/test-haproxy-failover.sh --apply
```

Avec `--apply`, le script arrête un conteneur backend, contrôle la continuité du service, redémarre le conteneur et vérifie sa réintégration. Un piège de sortie tente toujours de restaurer le backend en cas d’interruption.

</details>

### Preuves attendues

- configuration HAProxy valide ;
- deux backends observés avant la panne ;
- service HTTP continu avec un backend indisponible ;
- retour des deux backends après la reprise.

**Guide :** [HAProxy, round-robin et failover](docs/exercices/03-haproxy.md)

---

## Finalisation — Prouver, détruire et auditer

<p align="center">
  <img src="docs/schemas/finalisation/finalisation.svg" alt="Chaîne de finalisation des preuves au verdict LAB PROPRE" width="900">
</p>

Les sorties, journaux et captures d’exécution sont conservés sous `proofs/runtime/`. Ce dossier est ignoré par Git afin de ne pas publier d’adresses, d’identités ou de données liées au compte AWS.

<details>
<summary><strong>1. Contrôler les trois livrables</strong></summary>

```bash
# Contrôle de structure utilisé par la CI.
./scripts/commands/prepare-livrables.sh --structure-only

# Contrôle strict avant remise.
./scripts/commands/prepare-livrables.sh
```

Le mode strict échoue tant qu’un marqueur tel que « preuve à insérer » subsiste. Le dépôt organise les preuves, mais n’en invente aucune.

</details>

<details>
<summary><strong>2. Détruire et auditer AWS</strong></summary>

```bash
./scripts/commands/destroy-aws.sh
./scripts/commands/check-aws-cleanup.sh
```

</details>

**Verdicts finaux :**

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
NETTOYAGE AWS COMPLET
```

Le budget AWS reste actif après la démonstration afin de signaler une ressource oubliée.

**Guides :** [livrables et preuves](docs/livrables/README.md) · [convention de collecte](proofs/README.md)

---

## Automatisation et validation humaine

| Automatisé par le dépôt | À réaliser et valider humainement |
| --- | --- |
| Installation du socle DevOps | MFA et récupération du compte root |
| Contrôles AWS Ready | Lecture et approbation des plans Terraform |
| Build Angular reproductible | Création des visualisations OpenSearch |
| Déploiement Ansible et configuration NGINX | Captures du véritable environnement |
| Conversion et import des logs | Vérification de l’absence de secrets |
| Tests HAProxy | Remise finale selon les consignes de la plateforme |
| Destruction et audit des ressources P5 | Confirmation des alertes budgétaires |

## Arborescence utile

```text
p5_Openclassrooms/
├── application/angular/       # sources Angular et verrouillage npm
├── ansible/                   # build, NGINX, inventaire et playbook
├── aws/                       # politique IAM et budget du lab
├── environment/               # versions et configuration AWS d’exemple
├── docs/
│   ├── exercices/             # trois guides d’exécution
│   ├── livrables/             # gabarits et contrôle de complétude
│   └── schemas/               # vues vectorielles du parcours
├── proofs/                    # convention ; runtime ignoré par Git
├── scripts/
│   ├── commands/              # préparation, vérifications, tests et nettoyage
│   └── tools/                 # conversion NGINX et génération HAProxy
└── terraform/                 # trois modules AWS
```

## Validation continue

```bash
./scripts/commands/validate.sh
```

La CI vérifie notamment :

- les permissions exécutables, Bash et ShellCheck ;
- Angular avec `npm ci` et l’égalité exacte du build Ansible ;
- le mapping et les données OpenSearch ;
- la configuration HAProxy ;
- JSON, YAML, Terraform, Ansible et NGINX ;
- Markdown, liens et schémas SVG ;
- la structure des trois livrables ;
- l’absence de composants hors périmètre.

## Documentation complète

1. [Cadre officiel](docs/00-cadre-officiel.md)
2. [Préparer la VM](docs/00-preparation-environnement.md)
3. [Préparer le compte AWS](docs/00b-preparation-compte-aws.md)
4. [Parcours guidé](docs/01-parcours-debutant.md)
5. [Correspondance consignes, fichiers et preuves](docs/02-correspondance-consignes-depot.md)
6. [Exercice 1 — Terraform et Ansible](docs/exercices/01-terraform-ansible.md)
7. [Exercice 2 — OpenSearch](docs/exercices/02-elk-opensearch.md)
8. [Exercice 3 — HAProxy](docs/exercices/03-haproxy.md)
9. [Livrables et preuves](docs/livrables/README.md)
10. [Audit de non-régression](docs/04-audit-non-regression.md)

Licence : [MIT](LICENSE).
