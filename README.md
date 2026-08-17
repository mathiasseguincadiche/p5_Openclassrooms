# P5 OpenClassrooms — Infrastructure as Code, observabilité et haute disponibilité sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Le dépôt met en œuvre un parcours DevOps **100 % AWS** autour de trois objectifs :

1. provisionner une infrastructure avec Terraform et déployer Angular/NGINX avec Ansible ;
2. exploiter des logs HTTP avec Amazon OpenSearch ;
3. démontrer la haute disponibilité d'un service avec HAProxy.

Le plan de contrôle P5 s'exécute en CLI dans la distribution WSL2 **`Ubuntu`**, Ubuntu 26.04 LTS (`resolute`).

## Projet en 30 secondes

| Exercice | Objectif | Réalisation | Preuve principale |
| --- | --- | --- | --- |
| **1 — Infrastructure et déploiement** | créer une infrastructure reproductible et y déployer une application | Terraform crée le socle AWS ; Ansible déploie Angular derrière NGINX sur EC2 | aucun delta Terraform après convergence, application accessible, second passage Ansible `changed=0` |
| **2 — Logs et observabilité** | transformer des logs HTTP en informations exploitables | Amazon OpenSearch reçoit un jeu reproductible et le vrai `access.log` NGINX | données indexées, agrégations valides, trois visualisations et dashboard capturés |
| **3 — Haute disponibilité** | continuer à servir du trafic lorsqu'un backend tombe | HAProxy répartit les requêtes vers deux `nginxdemos/hello` | round-robin, retrait du backend défaillant, continuité du service, réintégration |

![Architecture et dépendances du P5](docs/schemas/vue-ensemble.svg)

Dépendances principales :

- l'exercice 1 fournit le VPC et les sous-réseaux réutilisés par l'exercice 3 ;
- l'exercice 1 produit le log NGINX réel exploitable par l'exercice 2 ;
- l'exercice 2 conserve un checkpoint humain pour OpenSearch Dashboards ;
- le nettoyage respecte l'ordre `3 → 2 → 1`.

## Préparer le plan de contrôle

La plateforme Windows/WSL2 est fournie par
[`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).
Le P5 possède son runtime logiciel dans `Ubuntu` sous WSL2 et l'ensemble des exercices AWS.

![Étape 0 — préparation de l'environnement](docs/schemas/etape-0.svg)

Dans `Ubuntu` sous WSL2 :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh status
```

Le précontrôle doit pouvoir atteindre :

```text
GO TERRAFORM
```

Ce verdict autorise la lecture d'un plan Terraform. Le delta doit être compris avant toute mutation.

Contrats :

- [Contrat WSL2](environment/wsl2/README.md) ;
- [versions P5](environment/versions.env) ;
- [préparation de l'environnement](docs/00-preparation-environnement.md).

## Point d'entrée et commandes

```bash
bash scripts/commands/p5.sh
```

Principe d'exécution :

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

| Commande | Rôle |
| --- | --- |
| `p5.sh` ou `p5.sh menu` | ouvrir le centre de commande |
| `p5.sh inspect` | observer l'état réel sans mutation |
| `p5.sh prepare` | préparer le runtime P5, AWS, le budget et les `tfvars` |
| `p5.sh status` | revalider les prérequis sans déployer |
| `p5.sh ex1` | converger Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | converger OpenSearch et les données |
| `p5.sh ex3` | converger HAProxy et rejouer les tests de résilience |
| `p5.sh all` | exécuter `prepare → ex1 → ex2 → ex3 → diagnostics` |
| `p5.sh finalize` | contrôler les preuves et les livrables |
| `p5.sh cleanup` | nettoyer les ressources P5 puis auditer AWS |

Référence : [Centre de commande](docs/CENTRE_DE_COMMANDE.md).

## Exercice 1 — Terraform + Ansible + Angular/NGINX

![Exercice 1 — infrastructure et déploiement](docs/schemas/exercice-1.svg)

Les flux Terraform et Angular sont indépendants : Terraform fournit l'infrastructure AWS, le build
Angular fournit l'artefact, puis Ansible utilise les deux pour configurer l'EC2 et servir l'application.

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

## Exercice 2 — Amazon OpenSearch

![Exercice 2 — logs vers OpenSearch](docs/schemas/exercice-2.svg)

Le sample versionné et le vrai `access.log` convergent vers le même pipeline de transformation et
d'import. La validation des trois visualisations et du dashboard reste un checkpoint humain.

```bash
bash scripts/commands/p5.sh ex2
```

Le checkpoint OpenSearch Dashboards demande :

1. un donut des méthodes HTTP ;
2. la somme de `bytes_sent` par tranches de 12 h ;
3. le top 5 de `url_path` par tranches de 12 h ;
4. le dashboard complet.

Guide : [Exercice 2](docs/exercices/02-opensearch.md).

## Exercice 3 — HAProxy

![Exercice 3 — HAProxy et résilience](docs/schemas/exercice-3.svg)

L'exercice réutilise le réseau de l'exercice 1. Le trafic public atteint HAProxy ; les backends
acceptent le trafic HTTP depuis le Security Group HAProxy, puis les health checks pilotent le retrait
et la réintégration d'un backend.

```bash
bash scripts/commands/p5.sh ex3
```

La preuve doit montrer les deux backends, le round-robin, la panne contrôlée d'un backend,
la continuité du service et sa réintégration après restauration.

Guide : [Exercice 3](docs/exercices/03-haproxy.md).

## Preuves, livrables et nettoyage AWS

![Finalisation et nettoyage](docs/schemas/finalisation/finalisation.svg)

Collecter puis contrôler les preuves avant toute destruction :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Une CI verte prouve la cohérence du dépôt ; elle ne remplace pas les preuves d'une exécution réelle
sur AWS. Les traces runtime restent locales sous `proofs/runtime/` et les preuves publiées doivent
être sélectionnées, contextualisées et anonymisées.

Après validation des livrables :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre de fermeture :

```text
Exercice 3 → Exercice 2 → Exercice 1 → audit AWS
```

Verdict attendu :

```text
NETTOYAGE AWS COMPLET
```

## Sécurité et coûts

Le projet applique notamment :

- `allowed_account_ids` pour verrouiller le compte AWS attendu ;
- une identité non root pour le lab ;
- une restriction SSH/OpenSearch à l'IPv4 publique `/32` ;
- IMDSv2 sur les EC2 ;
- des volumes racine chiffrés ;
- HTTPS et chiffrement OpenSearch ;
- un budget AWS contrôlé avant déploiement ;
- l'exclusion Git des states, vrais `tfvars`, clés, inventaires et preuves runtime ;
- des confirmations humaines avant les mutations sensibles.

Une CI verte ne signifie ni coût nul ni déploiement AWS effectif.

## Documentation

Portail : [`docs/README.md`](docs/README.md).

| Besoin | Document |
| --- | --- |
| comprendre le projet | [Parcours pédagogique](docs/01-parcours-debutant.md) |
| exécuter de A à Z | [Runbook guidé](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| préparer l'environnement | [Préparation](docs/00-preparation-environnement.md) |
| comprendre l'architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| comprendre une commande | [Centre de commande](docs/CENTRE_DE_COMMANDE.md) |
| reprendre après interruption | [Convergence et réexécution](docs/convergence-et-reexecution.md) |
| résoudre un blocage | [Troubleshooting](docs/troubleshooting.md) |
| préparer la soutenance | [Guide de soutenance](docs/05-soutenance.md) |
| préparer les livrables | [Livrables](docs/livrables/README.md) |
| vérifier la conformité | [Consignes → code → preuves](docs/02-correspondance-consignes-depot.md) |

## Schémas de référence

- [Vue d'ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation de l'environnement](docs/schemas/etape-0.svg)
- [Exercice 1 — Terraform, Ansible et NGINX](docs/schemas/exercice-1.svg)
- [Exercice 2 — OpenSearch](docs/schemas/exercice-2.svg)
- [Exercice 3 — HAProxy](docs/schemas/exercice-3.svg)
- [Finalisation et nettoyage](docs/schemas/finalisation/finalisation.svg)

Règles graphiques : [`docs/schemas/README.md`](docs/schemas/README.md).

## Périmètre

Le P5 couvre exactement trois exercices : Terraform/Ansible, OpenSearch et HAProxy.

Kubernetes, Helm, Prometheus, Grafana et Vault ne font pas partie du projet. GitHub Actions est
un mécanisme de qualité et de non-régression, pas un quatrième exercice.
