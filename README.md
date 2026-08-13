# P5 OpenClassrooms — Infrastructure as Code, observabilité et haute disponibilité sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt présente un **parcours DevOps d'infrastructure, d'observabilité et d'exploitation sur AWS** : provisionner avec Terraform, configurer avec Ansible, déployer Angular derrière NGINX, exploiter des logs dans Amazon OpenSearch puis démontrer la résilience d'un service avec HAProxy.

> **Mode d'implémentation retenu dans ce dépôt : 100 % AWS.** Les variantes locales évoquées dans les consignes ne constituent pas un second parcours maintenu ici. Windows 11 et WSL2 servent uniquement de poste de contrôle.

## Projet en 30 secondes

| Exercice | Objectif | Réalisation | Preuve principale |
| --- | --- | --- | --- |
| **1 — Infrastructure et déploiement** | créer une infrastructure reproductible et y déployer une application | Terraform crée le socle AWS ; Ansible déploie Angular derrière NGINX sur EC2 | aucun delta Terraform après convergence, application accessible, second passage Ansible `changed=0` |
| **2 — Logs et observabilité** | transformer des logs HTTP en informations exploitables | Amazon OpenSearch reçoit un jeu reproductible et le vrai `access.log` NGINX | données indexées, agrégations valides, 3 visualisations et dashboard capturés |
| **3 — Haute disponibilité** | continuer à servir du trafic lorsqu'un backend tombe | HAProxy répartit les requêtes vers deux `nginxdemos/hello` | round-robin, retrait du backend défaillant, continuité du service, réintégration |

![Architecture et dépendances du P5](docs/schemas/vue-ensemble.svg)

Les exercices sont liés :

- l'exercice 1 fournit le VPC et les sous-réseaux réutilisés par l'exercice 3 ;
- l'exercice 1 produit le log NGINX réel exploitable par l'exercice 2 ;
- l'exercice 2 conserve un checkpoint humain pour OpenSearch Dashboards ;
- le nettoyage final respecte l'ordre `3 → 2 → 1`.

## Un seul point d'entrée

```bash
bash scripts/commands/p5.sh
```

L'orchestrateur applique le principe suivant :

```text
inspecter l'état réel
        ↓
calculer le delta
        ↓
aucun delta ? ── oui ──► ne rien modifier
        │
        non
        ↓
corriger uniquement ce qui diffère
        ↓
vérifier le résultat
        ↓
journaliser et conserver les preuves
```

Une relance n'implique donc pas de tout recréer.

### Commandes principales

| Commande | Rôle |
| --- | --- |
| `p5.sh` ou `p5.sh menu` | ouvrir le centre de commande |
| `p5.sh inspect` | observer l'état réel sans mutation |
| `p5.sh prepare` | préparer le runtime Ubuntu/WSL2, AWS, le budget et les `tfvars` |
| `p5.sh status` | revalider les prérequis sans déployer |
| `p5.sh ex1` | converger Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | converger OpenSearch et les données |
| `p5.sh ex3` | converger HAProxy et rejouer les tests de résilience |
| `p5.sh all` | exécuter `prepare → ex1 → ex2 → ex3 → diagnostics` |
| `p5.sh finalize` | contrôler les preuves et les livrables |
| `p5.sh cleanup` | nettoyer les ressources P5 puis auditer AWS |

Référence : [Centre de commande](docs/CENTRE_DE_COMMANDE.md).

## Installation et environnement de contrôle

Le poste de contrôle attendu est **Windows 11 + WSL2 + Ubuntu 26.04**. Sa construction et sa maintenance appartiennent au dépôt [`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

Le checkout P5 doit rester dans le filesystem Linux WSL2 :

```text
~/labs/p5_Openclassrooms
```

et non sous `/mnt/c` ou `/mnt/d`.

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

Le précontrôle doit atteindre le verdict :

```text
GO TERRAFORM
```

Ce verdict autorise à **lire le plan** ; il ne remplace jamais la vérification du delta et des coûts avant une mutation.

Détails : [Installation et environnement de contrôle](docs/00-preparation-environnement.md) et [Préparation du compte AWS](docs/00b-preparation-compte-aws.md).

## Exécuter les trois exercices

### Exercice 1 — Terraform + Ansible + Angular/NGINX

```bash
bash scripts/commands/p5.sh ex1
```

Résultats attendus :

```text
Terraform : aucun delta après convergence
Ansible   : changed=0 | unreachable=0 | failed=0 au second passage
HTTP      : application Angular servie par NGINX
Logs      : access.log réel collecté pour l'exercice 2
```

Guide : [Exercice 1](docs/exercices/01-terraform-ansible.md).

### Exercice 2 — Amazon OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Le dépôt automatise l'infrastructure, l'import Bulk et les contrôles techniques. La validation visuelle reste humaine :

1. donut des méthodes HTTP ;
2. somme de `bytes_sent` par tranches de 12 h ;
3. top 5 de `url_path` par tranches de 12 h ;
4. dashboard complet.

Guide : [Exercice 2](docs/exercices/02-opensearch.md).

### Exercice 3 — HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

Le test doit montrer les deux backends, le round-robin, la panne contrôlée d'un backend, la continuité du service et sa réintégration après restauration.

Guide : [Exercice 3](docs/exercices/03-haproxy.md).

## Preuves, soutenance et nettoyage

Avant remise :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Une CI verte prouve la cohérence du **dépôt** ; elle ne remplace pas les preuves d'une exécution réelle sur AWS.

Les ressources restent actives tant qu'elles sont nécessaires aux captures ou à la démonstration. Ensuite, le lab doit être fermé proprement dans l'ordre :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

Pour préparer la présentation : [Guide de soutenance](docs/05-soutenance.md).

## Sécurité et coûts

Le projet conserve notamment :

- verrouillage du compte attendu avec `allowed_account_ids` ;
- identité non root pour le lab ;
- restriction SSH et OpenSearch à l'IPv4 publique `/32` prévue ;
- IMDSv2 sur les EC2 ;
- volumes racine chiffrés ;
- HTTPS et chiffrement OpenSearch ;
- budget AWS contrôlé avant déploiement ;
- états, vrais `tfvars`, inventaires, clés et preuves brutes hors Git ;
- confirmations humaines pour les étapes qui ne doivent pas être automatisées aveuglément.

Une CI verte ne signifie ni « coût nul » ni « preuve AWS produite ».

## Documentation officielle

Le portail documentaire est [`docs/README.md`](docs/README.md).

| Besoin | Document |
| --- | --- |
| comprendre le projet | [Parcours pédagogique](docs/01-parcours-debutant.md) |
| exécuter de A à Z | [Runbook guidé](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| comprendre l'architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| comprendre une commande | [Centre de commande](docs/CENTRE_DE_COMMANDE.md) |
| reprendre après interruption | [Convergence et réexécution](docs/convergence-et-reexecution.md) |
| résoudre un blocage | [Troubleshooting](docs/troubleshooting.md) |
| préparer la soutenance | [Guide de soutenance](docs/05-soutenance.md) |
| préparer les livrables | [Livrables](docs/livrables/README.md) |
| vérifier la conformité | [Consignes → code → preuves](docs/02-correspondance-consignes-depot.md) |

## Schémas du parcours

Les six schémas versionnés correspondent au même parcours et restent référencés depuis cette page :

- [Vue d'ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

## Ce qui n'est pas le P5

Kubernetes, Helm, Prometheus, Grafana et Vault ne font pas partie des trois exercices de ce dépôt. GitHub Actions protège la qualité du dépôt mais n'est pas un quatrième exercice.

Le fil directeur reste volontairement simple :

```text
Infrastructure as Code
        +
Configuration as Code
        +
Observabilité
        +
Haute disponibilité
        +
Preuves opérationnelles
```
