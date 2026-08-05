# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)

Ce dépôt contient l’**implémentation exécutable** du projet P5 et son parcours de validation. Les trois exercices officiels sont reliés dans une même démarche : préparer l’environnement, déployer une application, exploiter ses logs, tester sa disponibilité, produire les preuves puis supprimer les ressources AWS.

> **Périmètre : 100 % AWS.** La VM Ubuntu Server 26.04 sert de poste DevOps. Terraform, Ansible, AWS CLI, Angular, Docker et les scripts de contrôle s’y exécutent ; les infrastructures évaluées sont créées dans AWS.

> **Attention aux coûts AWS.** Relisez chaque plan Terraform, activez le budget du lab et exécutez la procédure de destruction après les démonstrations.

## Ce que démontre le projet

| Domaine | Mise en pratique |
| --- | --- |
| **Infrastructure as Code** | Création reproductible des ressources AWS avec Terraform |
| **Configuration automatisée** | Installation de NGINX et livraison d’Angular avec Ansible |
| **Observabilité** | Transformation des logs NGINX et exploitation dans OpenSearch |
| **Disponibilité** | Répartition HAProxy, panne contrôlée et réintégration d’un backend |
| **Qualité et sécurité** | CI, contrôles non destructifs, preuves réelles et nettoyage AWS |

## Parcours du projet

| Phase | Objectif | Validation attendue |
| --- | --- | --- |
| **0 — Préparer** | Construire le poste DevOps et contrôler le compte AWS | `GO TERRAFORM` |
| **1 — Déployer** | Livrer la véritable application Angular sur EC2 | Application HTTP accessible |
| **2 — Observer** | Transformer les logs NGINX en visualisations OpenSearch | Dashboard exploitable |
| **3 — Valider la résilience** | Vérifier le round-robin, la panne et la reprise | Service disponible |
| **Finaliser** | Contrôler les preuves, détruire et auditer | `NETTOYAGE AWS COMPLET` |

Le chemin d’exécution reste volontairement simple :

```text
Poste DevOps
  → contrôles AWS
  → Terraform
  → Ansible et NGINX
  → application Angular
  → logs OpenSearch
  → tests HAProxy
  → preuves
  → destruction et audit
```

### Navigation

[Étape 0](#étape-0--préparer-le-lab-et-aws) ·
[Exercice 1](#exercice-1--déployer-angular-avec-terraform-et-ansible) ·
[Exercice 2](#exercice-2--exploiter-les-logs-dans-opensearch) ·
[Exercice 3](#exercice-3--tester-haproxy-et-la-reprise) ·
[Finalisation](#finalisation--prouver-détruire-et-auditer) ·
[Validation continue](#validation-continue)

---

## Étape 0 — Préparer le lab et AWS

### Objectif

Préparer un poste DevOps reproductible et bloquer les erreurs de compte, de région, de quota, de réseau ou de coût **avant** le premier déploiement.

| Élément | Contrôles réalisés | Résultat |
| --- | --- | --- |
| VM Ubuntu Server 26.04 | Terraform, Ansible, AWS CLI, Docker, Node.js et outils système | Poste DevOps prêt |
| Compte AWS | Profil, identité, région, quotas et budget | Compte autorisé |
| Accès | Clé SSH, permissions, `terraform.tfvars` et adresse `/32` | Accès prêts |

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

### Validation

**Verdict obligatoire :** `GO TERRAFORM`

Aucun `terraform apply` n’est lancé par les contrôles de préparation. La seule mutation volontaire est la création du budget avec `setup-aws-guardrails.sh --apply`.

**Guides :** [préparation de la VM](docs/00-preparation-environnement.md) · [préparation du compte AWS](docs/00b-preparation-compte-aws.md)

---

## Exercice 1 — Déployer Angular avec Terraform et Ansible

### Objectif

Construire le véritable artefact Angular, créer l’infrastructure AWS avec Terraform, puis configurer l’instance EC2 avec Ansible et NGINX.

| Étape | Outil principal | Résultat |
| --- | --- | --- |
| Construire | Angular et npm | Artefact navigateur reproductible |
| Provisionner | Terraform | Réseau, sécurité et instance EC2 |
| Configurer | Ansible | NGINX installé et application copiée |
| Vérifier | Scripts de contrôle | HTTP, bundle JavaScript, SPA et logs validés |

<details>
<summary><strong>1. Construire l’application</strong></summary>

```bash
./scripts/commands/prepare-angular-artifact.sh
```

La CI reconstruit l’application et compare exactement le résultat au contenu de `ansible/files/angular-app/`. Une simple page HTML ne peut donc pas remplacer le véritable build Angular.

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
- bundle JavaScript chargé ;
- fallback SPA assuré par NGINX ;
- seconde exécution Ansible idempotente ;
- logs NGINX réels récupérés pour l’exercice 2.

**Guide :** [Terraform, Ansible, Angular et NGINX](docs/exercices/01-terraform-ansible.md)

---

## Exercice 2 — Exploiter les logs dans OpenSearch

### Objectif

Transformer les logs NGINX en données structurées, les importer dans OpenSearch puis construire les visualisations demandées.

| Étape | Transformation | Contrôle |
| --- | --- | --- |
| Collecter | Logs NGINX au format combined | Fichier source lisible |
| Convertir | NGINX vers Bulk NDJSON | 64 événements valides |
| Indexer | Mapping strict dans OpenSearch | Champs et types vérifiés |
| Visualiser | Discover et Dashboards | Trois graphiques conformes |

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

| Visualisation | Agrégation | Ce qu’elle démontre |
| --- | --- | --- |
| Donut | `http_method` | Répartition des verbes HTTP |
| Histogramme | somme de `bytes_sent` par 12 h | Volume de données envoyé |
| Top 5 temporel | `url_path` par 12 h | Requêtes les plus fréquentes |

La création des graphiques dans OpenSearch Dashboards reste volontairement manuelle : elle fait partie de la compréhension évaluée.

### Preuves attendues

- index et champs visibles dans Discover ;
- trois visualisations conformes ;
- dashboard complet ;
- quatre captures lisibles ;
- aucune donnée sensible visible.

**Guide :** [logs NGINX et Amazon OpenSearch](docs/exercices/02-elk-opensearch.md)

---

## Exercice 3 — Tester HAProxy et la reprise

### Objectif

Vérifier que HAProxy répartit les requêtes entre deux backends et maintient le service lorsqu’un backend devient indisponible.

| État | Action | Résultat attendu |
| --- | --- | --- |
| Normal | Envoyer plusieurs requêtes | Les deux backends répondent |
| Panne | Arrêter volontairement un backend | Le service HTTP reste accessible |
| Reprise | Redémarrer le backend | Les deux backends sont réintégrés |

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

### Objectif

Constituer les preuves réelles, contrôler les trois livrables, supprimer les ressources AWS et confirmer qu’aucun coût du lab n’a été oublié.

Les sorties, journaux et captures d’exécution sont conservés sous `proofs/runtime/`. Ce dossier est ignoré par Git afin de ne pas publier d’adresses, d’identités ou de données liées au compte AWS.

| Étape | Commande ou dossier | Validation |
| --- | --- | --- |
| Collecter | `proofs/runtime/` | Sorties et captures réelles |
| Contrôler | `prepare-livrables.sh` | Trois livrables complets |
| Détruire | `destroy-aws.sh` | Ressources supprimées |
| Auditer | `check-aws-cleanup.sh` | Aucun reste du lab |

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

### Verdicts finaux

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
│   └── livrables/             # gabarits et contrôle de complétude
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
- Markdown et liens internes ;
- la structure des trois livrables ;
- l’absence de composants hors périmètre.

## Documentation complète

### Préparation et parcours

1. [Cadre officiel](docs/00-cadre-officiel.md)
2. [Préparer la VM](docs/00-preparation-environnement.md)
3. [Préparer le compte AWS](docs/00b-preparation-compte-aws.md)
4. [Parcours guidé](docs/01-parcours-debutant.md)
5. [Correspondance consignes, fichiers et preuves](docs/02-correspondance-consignes-depot.md)

### Exercices

1. [Exercice 1 — Terraform et Ansible](docs/exercices/01-terraform-ansible.md)
2. [Exercice 2 — OpenSearch](docs/exercices/02-elk-opensearch.md)
3. [Exercice 3 — HAProxy](docs/exercices/03-haproxy.md)

### Preuves et contrôle qualité

1. [Livrables et preuves](docs/livrables/README.md)
2. [Audit de non-régression](docs/04-audit-non-regression.md)

Licence : [MIT](LICENSE).

<!--
Ressources graphiques historiques conservées pour le contrat de non-régression :
docs/schemas/vue-ensemble.svg
docs/schemas/etape-0.svg
docs/schemas/exercice-1.svg
docs/schemas/exercice-2.svg
docs/schemas/exercice-3.svg
docs/schemas/finalisation/finalisation.svg
-->
