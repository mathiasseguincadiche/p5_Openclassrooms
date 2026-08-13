# P5 OpenClassrooms — Infrastructure as Code et exploitation sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Ce dépôt est un **lab DevOps AWS reproductible et convergent**. Il met en pratique
quatre compétences centrales : provisionner une infrastructure avec Terraform,
automatiser un déploiement avec Ansible, exploiter des logs dans Amazon
OpenSearch et démontrer la haute disponibilité avec HAProxy.

La réalisation choisie utilise **AWS pour les trois exercices**.

> **L'essence du projet :** partir d'un environnement vide, construire les
> ressources nécessaires, déployer une application réelle, observer son activité,
> tester sa disponibilité, produire des preuves puis nettoyer proprement AWS.

> **Périmètre évalué : 100 % AWS.** Windows 11 et WSL2 servent uniquement de poste
> de contrôle pour exécuter les outils DevOps. Ils ne constituent pas le projet
> évalué.

## Ce que le projet démontre

Le P5 ne consiste pas seulement à lancer quelques commandes Terraform. Le dépôt
assemble un parcours complet et vérifiable :

1. **Infrastructure as Code** — Terraform crée et fait converger l'infrastructure
   AWS ;
2. **Configuration as Code** — Ansible configure l'instance cible et déploie
   Angular derrière NGINX ;
3. **Observabilité** — les logs NGINX alimentent Amazon OpenSearch et des
   visualisations dans OpenSearch Dashboards ;
4. **Haute disponibilité** — HAProxy répartit le trafic entre deux backends et le
   lab vérifie le comportement pendant une panne contrôlée ;
5. **Exploitation** — l'orchestrateur sait inspecter, reprendre, journaliser,
   vérifier les preuves et nettoyer les ressources AWS.

Le principe directeur est :

```text
inspecter
   ↓
comparer l'état réel à l'état attendu
   ↓
aucun delta ? ── oui ──► aucune mutation inutile
   │
   non
   ↓
corriger uniquement le delta
   ↓
vérifier
   ↓
journaliser et conserver les preuves
```

## Le projet en un schéma

```text
                         OPÉRATEUR
                            │
                            ▼
                 scripts/commands/p5.sh
                            │
            ┌───────────────┼───────────────┐
            │               │               │
            ▼               ▼               ▼
       EXERCICE 1       EXERCICE 2       EXERCICE 3
   Terraform + Ansible   OpenSearch        HAProxy
            │               ▲               ▲
            │               │               │
            ▼               │               │
      VPC + EC2             │               │
            │               │               │
            ▼               │               │
    NGINX + Angular         │               │
            │               │               │
            └─ access.log ──┘               │
            │                               │
            └──── réseau AWS réutilisé ─────┘
                            │
                            ▼
              preuves + validation finale
                            │
                            ▼
            destruction 3 → 2 → 1 + audit
```

L'exercice 2 est techniquement indépendant du réseau de l'exercice 1, mais il
peut utiliser son vrai `access.log`. L'exercice 3 réutilise directement le VPC,
les sous-réseaux et la paire de clés de l'exercice 1.

## Les trois exercices

| Exercice | Objectif | Technologies principales | Preuve importante |
| --- | --- | --- | --- |
| 1 — Terraform + Ansible | créer l'infrastructure et déployer Angular | AWS, Terraform, EC2, Ansible, NGINX, Angular | second passage Ansible avec `changed=0` |
| 2 — Logs et OpenSearch | collecter, indexer, analyser et visualiser des logs | Amazon OpenSearch, Bulk API, Dashboards | données réelles + visualisations vérifiées |
| 3 — Haute disponibilité | répartir le trafic et survivre à la panne d'un backend | EC2, Docker, HAProxy | round-robin, panne puis réintégration |

Le cadre officiel et la correspondance exacte entre consignes, code et preuves
sont documentés dans :

- [Cadre officiel et périmètre](docs/00-cadre-officiel.md)
- [Correspondance consignes → implémentation → preuve](docs/02-correspondance-consignes-depot.md)

## Exercice 1 — Terraform, Ansible, NGINX et Angular

L'exercice 1 construit le socle AWS du lab :

```text
AWS
└── VPC 10.0.0.0/16
    ├── 2 sous-réseaux publics
    ├── Internet Gateway + routes
    ├── Security Group
    ├── paire de clés EC2
    └── EC2 Ubuntu
         ↓
       Ansible
         ↓
       NGINX
         ↓
       Angular
```

Commande :

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours construit l'artefact Angular si nécessaire, fait converger Terraform,
génère l'inventaire Ansible, attend que la cible soit prête, déploie l'application
puis rejoue le playbook.

Le second passage doit prouver l'idempotence :

```text
changed=0
unreachable=0
failed=0
```

Le véritable `access.log` NGINX peut ensuite être collecté pour l'exercice 2.

Guide détaillé :
[Exercice 1 — Terraform et Ansible](docs/exercices/01-terraform-ansible.md).

## Exercice 2 — Amazon OpenSearch

L'exercice 2 utilise **Amazon OpenSearch Service** comme solution Cloud retenue
pour le projet.

```text
sample reproductible
        +
access.log réel de NGINX
        ↓
conversion / validation
        ↓
Amazon OpenSearch
        ↓
index + agrégations
        ↓
OpenSearch Dashboards
```

Commande :

```bash
bash scripts/commands/p5.sh ex2
```

Le dépôt automatise la création/convergence du domaine, la préparation des
données, l'import Bulk et les contrôles techniques. Les visualisations et leurs
captures restent volontairement un **checkpoint humain**, car elles font partie
de la compréhension attendue pendant le projet.

Guide détaillé :
[Exercice 2 — Logs et OpenSearch](docs/exercices/02-elk-opensearch.md).

## Exercice 3 — HAProxy et haute disponibilité

L'exercice 3 réutilise le réseau créé par l'exercice 1 et ajoute :

```text
                    HAProxy
                  /         \
                 /           \
          backend 1       backend 2
             │                │
           Docker           Docker
             │                │
     nginxdemos/hello  nginxdemos/hello
```

Commande :

```bash
bash scripts/commands/p5.sh ex3
```

Le test vérifie :

- la présence des deux backends ;
- le round-robin ;
- l'arrêt contrôlé d'un backend ;
- la continuité du service ;
- la réintégration du backend après restauration.

Guide détaillé :
[Exercice 3 — HAProxy](docs/exercices/03-haproxy.md).

## Un seul point d'entrée : `p5.sh`

Le dépôt dispose d'un orchestrateur unique :

```bash
bash scripts/commands/p5.sh
```

Le **Control Center V11** est une interface interactive au-dessus des fonctions
existantes. Il ne remplace ni Terraform, ni Ansible, ni les scripts spécialisés.

Commandes principales :

| Commande | Rôle |
| --- | --- |
| `p5.sh` / `p5.sh menu` | ouvrir le menu interactif |
| `p5.sh inspect` | observer l'état réel sans mutation |
| `p5.sh prepare` | préparer le contrat P5, AWS, budget et `tfvars` |
| `p5.sh status` | vérifier l'état sans déployer |
| `p5.sh ex1` | converger l'exercice 1 |
| `p5.sh ex2` | converger l'exercice 2 |
| `p5.sh ex3` | converger l'exercice 3 |
| `p5.sh all` | exécuter le parcours complet |
| `p5.sh diagnostics` | collecter les diagnostics et l'état des preuves |
| `p5.sh finalize` | contrôler les preuves et livrables |
| `p5.sh logs` | consulter les journaux |
| `p5.sh guide` | obtenir une aide au choix du parcours |
| `p5.sh docs` | afficher la carte documentaire |
| `p5.sh cleanup` | détruire AWS dans l'ordre prévu puis auditer |

Documentation du menu :
[Centre de commande V11](docs/CENTRE_DE_COMMANDE.md).

## Parcours complet

Une fois l'environnement de contrôle prêt :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Le parcours `all` enchaîne :

```text
inspect / prepare
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
```

Il **ne détruit pas automatiquement AWS**.

Pour automatiser les confirmations qui peuvent l'être :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne contourne jamais :

- une validation humaine de sécurité ;
- le checkpoint OpenSearch Dashboards ;
- la confirmation forte `DETRUIRE` du nettoyage.

## Installation et environnement de contrôle

Le projet est actuellement exploité depuis **Windows 11 Pro + WSL2 + Ubuntu**.
Cette couche sert à fournir Bash, Terraform, Ansible, AWS CLI, Docker et Node.js.
Elle n'est pas le sujet principal du P5.

La workstation est maintenue dans un dépôt séparé :

`mathiasseguincadiche/Windows_11_Pro_Custom`

P5 ne réimplémente ni l'installation WSL2, ni `.wslconfig`, ni la gestion du VHDX,
ni la sauvegarde de Windows.

Pour installer ou qualifier le poste de contrôle, utiliser le guide dédié :

[Étape 0A — Préparer l'environnement de contrôle](docs/00-preparation-environnement.md).

Une fois Ubuntu prêt, le dépôt P5 doit vivre sur le filesystem Linux :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Le contrat de versions P5 est versionné dans `environment/versions.env`.

## Convergence et reprise

Une réexécution de `p5.sh all` ne signifie pas « tout refaire ».

Terraform utilise `plan -detailed-exitcode` pour distinguer :

```text
aucun delta  → aucun apply
un delta     → afficher, confirmer, appliquer, revérifier
une erreur   → arrêter et diagnostiquer
```

Le même principe s'applique aux outils du lab, à la configuration AWS, aux
artefacts et aux données qui peuvent être vérifiés.

Après fermeture du terminal ou redémarrage de la machine :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

**Ne jamais supprimer un `terraform.tfstate` pour forcer une reprise** tant que
les ressources AWS correspondantes existent.

Documentation :
[Convergence et réexécution](docs/convergence-et-reexecution.md).

## Preuves, journaux et soutenance

Le projet distingue le code versionné des preuves d'une exécution réelle.

Les journaux runtime sont écrits sous :

```text
logs/<UTC>/
```

Les preuves de lab sont organisées sous :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

La présence d'un fichier Terraform ou Ansible dans Git **ne prouve pas** que la
ressource AWS a réellement été créée. Les preuves réelles doivent provenir de
l'exécution du lab.

Avant la soutenance :

```bash
bash scripts/commands/p5.sh diagnostics
bash scripts/commands/p5.sh finalize
```

Verdict de finalisation attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Guide :
[Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md).

## Sécurité et coûts

Le dépôt contient plusieurs garde-fous :

- verrouillage du compte AWS attendu via `allowed_account_ids` ;
- refus d'un compte root pour le parcours normal ;
- SSH limité à l'IPv4 publique `/32` configurée ;
- IMDSv2 obligatoire sur les EC2 du lab ;
- volumes racine EC2 chiffrés ;
- chiffrement et HTTPS pour OpenSearch ;
- budget AWS contrôlé avant déploiement ;
- secrets, `terraform.tfvars`, états, logs et preuves runtime exclus de Git selon
  leur nature ;
- confirmations humaines conservées pour les actions sensibles.

Une CI verte ne signifie pas que les ressources AWS sont gratuites. Le plan
Terraform et le budget doivent être relus avant création.

Politique : [SECURITY.md](SECURITY.md).

## Nettoyage AWS

Quand les preuves sont terminées et que le lab n'est plus nécessaire :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

L'exercice 3 doit être détruit avant l'exercice 1 puisqu'il réutilise son réseau.

Verdict final attendu :

```text
NETTOYAGE AWS COMPLET
```

Tant que ce verdict n'est pas obtenu, il ne faut pas supposer que tous les coûts
P5 ont cessé.

## Ce que la CI vérifie

Les workflows du dépôt contrôlent notamment :

- Bash et ShellCheck ;
- contrat de l'orchestrateur ;
- Terraform ;
- Ansible ;
- Angular et TypeScript ;
- configuration NGINX réelle ;
- OpenSearch local, Bulk API et agrégations ;
- HAProxy, round-robin, panne et reprise ;
- YAML ;
- Markdown et liens ;
- secrets et non-régression ;
- compatibilité du contrat d'exécution Ubuntu/WSL2.

La CI valide le **dépôt**. Elle ne remplace pas l'exécution réelle sur le compte
AWS de l'opérateur.

## Ce qui est hors périmètre

Ce P5 ne cherche pas à ajouter des technologies pour « faire plus DevOps ».
Sont volontairement hors périmètre des exercices :

- Kubernetes ;
- Helm ;
- Prometheus ;
- Grafana ;
- Vault ;
- GitHub Actions comme exercice autonome.

La CI sert à protéger le dépôt, pas à créer un quatrième exercice.

## Documentation

### Comprendre le projet

- [Portail documentaire](docs/README.md)
- [Cadre officiel et périmètre](docs/00-cadre-officiel.md)
- [Parcours pédagogique](docs/01-parcours-debutant.md)
- [Architecture et flux](docs/architecture-et-flux.md)
- [Correspondance consignes → code → preuves](docs/02-correspondance-consignes-depot.md)

### Installer et exécuter

- [Préparation de l'environnement](docs/00-preparation-environnement.md)
- [Préparation du compte AWS](docs/00b-preparation-compte-aws.md)
- [Runbook d'exécution A → Z](docs/RUNBOOK_EXECUTION_GUIDEE.md)
- [Centre de commande V11](docs/CENTRE_DE_COMMANDE.md)

### Exploiter et diagnostiquer

- [Convergence et réexécution](docs/convergence-et-reexecution.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md)
- [Scripts et commandes](scripts/README.md)

### Préparer la soutenance

- [Livrables](docs/livrables/README.md)
- [Correspondance consignes → code → preuves](docs/02-correspondance-consignes-depot.md)
- [Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md)

## Sources de vérité

| Sujet | Source de vérité |
| --- | --- |
| cadre et exigences | `docs/00-cadre-officiel.md` |
| orchestration P5 | `scripts/commands/p5.sh` |
| versions du lab | `environment/versions.env` |
| configuration AWS locale | `environment/aws-readiness.env` |
| infrastructure | `terraform/exercice-*/` |
| déploiement | `ansible/playbooks/deploy.yml` |
| application | `application/angular/` |
| données OpenSearch | `terraform/exercice-2/` |
| preuves runtime | `proofs/runtime/` |
| journaux runtime | `logs/` |
| sécurité | `SECURITY.md` |
| installation Windows/WSL2 | `Windows_11_Pro_Custom` + `docs/00-preparation-environnement.md` |
