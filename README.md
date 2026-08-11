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
- relancer le projet sans recréer ce qui est déjà conforme ;
- conserver des preuves techniques et des journaux d'exécution exploitables.

> **Périmètre évalué : 100 % AWS.** Le poste de contrôle local est désormais
> **Windows 11 Pro + WSL2 + Ubuntu 26.04 LTS**. Les infrastructures évaluées sont
> créées dans AWS.

> **Principe général :** inspecter → comparer → corriger uniquement le delta →
> vérifier → journaliser.

## Poste de contrôle local

La plateforme locale retenue est :

```text
Windows 11 Pro
└── WSL2
    ├── 6 processeurs logiques maximum
    ├── 16 Go de RAM maximum
    ├── 8 Go de swap
    ├── réseau NAT
    ├── DNS tunneling
    └── p5-devops
        └── Ubuntu 26.04 LTS + systemd
            ├── Terraform
            ├── Ansible
            ├── AWS CLI
            ├── Docker Engine
            ├── Node.js / Angular
            └── p5.sh
```

Le fichier `%UserProfile%\.wslconfig` configure la VM WSL2 globale. Si plusieurs
distributions WSL2 sont actives en même temps, elles partagent cette enveloppe de
CPU et de mémoire.

Le réseau WSL2 est volontairement en **NAT**. L'adresse privée WSL, la passerelle
et la route par défaut sont détectées dynamiquement ; aucune adresse WSL n'est
codée en dur dans le projet.

Cette adresse privée WSL ne doit pas être confondue avec `P5_PUBLIC_IP_CIDR`, qui
représente l'IPv4 publique `/32` autorisée dans les Security Groups et la policy
OpenSearch AWS.

Référence complète :
[Préparer Windows 11 + WSL2](docs/00-preparation-environnement.md).

## Installation WSL2

Depuis un clone du dépôt accessible sous Windows, ouvrir **PowerShell en tant
qu'administrateur** :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Premier lancement :

```powershell
wsl -d p5-devops
```

Après création de l'utilisateur Ubuntu, revenir dans PowerShell :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

Le contrôle attendu vérifie notamment :

- WSL2 ;
- 6 processeurs disponibles ;
- environ 16 Go de RAM ;
- `systemd` ;
- hostname `p5-devops` ;
- IPv4 WSL ;
- passerelle et route par défaut ;
- DNS ;
- accès HTTPS.

## Exploitation WSL2

Les commandes Windows dédiées au lab sont :

| Besoin | Commande PowerShell |
| --- | --- |
| Démarrer | `.\scripts\windows\start-p5.ps1` |
| Arrêter | `.\scripts\windows\stop-p5.ps1` |
| État synthétique | `.\scripts\windows\status-p5.ps1` |
| Diagnostic complet | `.\scripts\windows\check-wsl2-p5.ps1 -RequireTools` |
| Sauvegarder | `.\scripts\windows\backup-p5.ps1` |
| Restaurer | `.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>` |

Une sauvegarde WSL2 est exportée au format **VHDX** avec un fichier SHA-256. La
restauration est non destructive : elle refuse d'écraser automatiquement une
distribution existante.

Les fichiers `.vhd`, `.vhdx` et leurs sommes de contrôle sont ignorés par Git.

## Installer le socle DevOps dans Ubuntu

Le dépôt doit être cloné dans le système de fichiers Linux, par exemple :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Puis :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap converge le socle Linux sans créer de ressource AWS. Il installe ou
corrige uniquement les composants absents ou non conformes.

Après une modification du groupe Docker ou de NVM, arrêter puis redémarrer la
distribution depuis PowerShell :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
```

Puis rouvrir Ubuntu :

```powershell
wsl -d p5-devops
```

## Démarrage du projet

Depuis Ubuntu WSL2 et la racine du dépôt :

```bash
bash scripts/commands/p5.sh inspect
```

Cette commande observe l'état réel **sans mutation**.

Pour le parcours complet :

```bash
bash scripts/commands/p5.sh all
```

Pour ouvrir le menu interactif :

```bash
bash scripts/commands/p5.sh
```

Pour automatiser uniquement les confirmations automatisables :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne contourne jamais :

- les vérifications de sécurité AWS nécessitant une validation humaine ;
- la preuve visuelle du dashboard OpenSearch ;
- la destruction finale protégée par `DETRUIRE`.

## Centre de commande

| Commande | Rôle |
| --- | --- |
| `p5.sh` | menu interactif |
| `p5.sh inspect` | observe sans mutation |
| `p5.sh prepare` | converge le socle Linux, AWS, budget et tfvars |
| `p5.sh status` | contrôle la préparation sans créer de ressource AWS |
| `p5.sh ex1` | Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | OpenSearch, imports et agrégations |
| `p5.sh ex3` | HAProxy, round-robin, panne et reprise |
| `p5.sh all` | exécute le parcours technique complet |
| `p5.sh finalize` | contrôle strict des preuves et livrables |
| `p5.sh logs` | retrouve les journaux de session |
| `p5.sh cleanup` | destruction 3 → 2 → 1 puis audit AWS |

## Portes de validation

Avant toute création d'infrastructure, le parcours doit atteindre :

```text
GO AWS
GO TERRAFORM
```

Après la destruction finale, le verdict attendu est :

```text
NETTOYAGE AWS COMPLET
```

## Architecture AWS

```text
Windows 11 Pro
└── WSL2 / p5-devops / Ubuntu 26.04
    └── Terraform + Ansible + AWS CLI + Docker + Node.js
              │
              ▼
AWS — us-east-1
│
├── Exercice 1
│   ├── VPC 10.0.0.0/16
│   ├── 2 sous-réseaux publics
│   ├── Internet Gateway + table de routage
│   ├── EC2 Ubuntu
│   └── Ansible → NGINX → Angular
│                │
│                └── access.log réel ─────► Exercice 2
│                                            Amazon OpenSearch
│                                            └── Dashboards
│
└── Exercice 3
    ├── réutilise le VPC et les sous-réseaux de l'exercice 1
    ├── EC2 HAProxy
    └── 2 EC2 → Docker → nginxdemos/hello
```

Le changement de KVM vers WSL2 concerne uniquement le **poste de contrôle
local**. Le VPC AWS `10.0.0.0/16`, les sous-réseaux, routes, Security Groups et
ressources Terraform restent indépendants du NAT WSL2.

Référence :
[Architecture et flux](docs/architecture-et-flux.md).

## Schémas du parcours

Les six schémas pédagogiques restent intégrés au parcours :

- [Vue d'ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation Windows 11, WSL2 et AWS](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

## Convergence et réexécution

Une seconde exécution de `p5.sh all` ne signifie pas « tout refaire ».

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

Exemples :

- distribution WSL2 déjà configurée : aucune réinstallation ;
- socle Ubuntu conforme : aucun paquet réinstallé ;
- session AWS valide : réutilisée ;
- `terraform.tfvars` identiques : aucune réécriture ;
- plan Terraform vide : aucun `apply` ;
- artefact Angular inchangé : aucun rebuild inutile ;
- budget conforme : aucune mutation ;
- documents OpenSearch déjà présents : pas de réimport inutile.

Les tests fonctionnels peuvent néanmoins être rejoués pour vérifier l'état réel
au moment de la démonstration.

Référence :
[Convergence et réexécution](docs/convergence-et-reexecution.md).

## Exercices

### Exercice 1 — Terraform, Ansible, NGINX et Angular

```bash
bash scripts/commands/p5.sh ex1
```

Le parcours crée l'infrastructure AWS, génère l'inventaire Ansible, déploie
Angular derrière NGINX et exige une seconde exécution Ansible avec :

```text
changed=0
unreachable=0
failed=0
```

Guide :
[Terraform + Ansible](docs/exercices/01-terraform-ansible.md).

### Exercice 2 — Amazon OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Le véritable exercice utilise **Amazon OpenSearch Service**. Aucun OpenSearch
permanent n'est requis dans WSL2 pour le lab AWS. Les conteneurs OpenSearch de la
CI et des validations locales restent éphémères.

Guide :
[OpenSearch](docs/exercices/02-elk-opensearch.md).

### Exercice 3 — HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

Terraform converge HAProxy et les deux backends. Les tests round-robin, panne et
reprise sont rejoués pour prouver le fonctionnement actuel.

Guide :
[HAProxy](docs/exercices/03-haproxy.md).

## Reprise après interruption

Si seul le terminal Linux a été fermé :

```powershell
wsl -d p5-devops
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Si la distribution a été arrêtée :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Le projet reprend à partir de l'état réellement présent. Ne supprimez jamais un
`terraform.tfstate` pour « débloquer » une reprise tant que les ressources AWS
associées existent.

## Logs et preuves

Chaque session `p5.sh` crée des journaux sous :

```text
logs/<UTC>/
├── p5.log
├── 01-....log
├── 02-....log
└── ...
```

Les preuves pédagogiques restent séparées :

```text
proofs/runtime/
├── diagnostics/
├── exercice-1/
├── exercice-2/
└── exercice-3/
```

```bash
bash scripts/commands/p5.sh logs
```

## Finalisation et nettoyage

Après les captures et preuves réelles :

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

Puis, uniquement quand le lab AWS n'est plus nécessaire :

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

## Validation CI

La CI vérifie notamment :

- Bash et ShellCheck ;
- contrat de l'orchestrateur ;
- convergence/réexécution ;
- contrat Windows 11 / WSL2 ;
- parsing des scripts PowerShell ;
- Terraform ;
- Ansible ;
- Angular, TypeScript et NGINX réel ;
- OpenSearch local, Bulk et agrégations ;
- HAProxy, round-robin, panne et reprise ;
- YAML ;
- Markdown et liens ;
- secrets et non-régression.

Une CI verte prouve la cohérence du dépôt et ses intégrations locales. Le test
d'intégration final reste l'exécution réelle de `p5.sh all` depuis `p5-devops`
avec une session AWS valide.

## Documentation

| Besoin | Document |
| --- | --- |
| Portail documentaire | [docs/README.md](docs/README.md) |
| Installation Windows 11 / WSL2 | [docs/00-preparation-environnement.md](docs/00-preparation-environnement.md) |
| Guide WSL2 dédié | [environment/wsl2/README.md](environment/wsl2/README.md) |
| Runbook A → Z | [docs/RUNBOOK_EXECUTION_GUIDEE.md](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| Parcours de bout en bout | [docs/01-parcours-debutant.md](docs/01-parcours-debutant.md) |
| Architecture | [docs/architecture-et-flux.md](docs/architecture-et-flux.md) |
| Convergence | [docs/convergence-et-reexecution.md](docs/convergence-et-reexecution.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Validation et nettoyage | [docs/validation-preuves-nettoyage.md](docs/validation-preuves-nettoyage.md) |
| Sécurité | [SECURITY.md](SECURITY.md) |

## Règles de sécurité

Le dépôt protège notamment contre :

- mauvais compte AWS via `allowed_account_ids` ;
- utilisation quotidienne du compte root ;
- credentials AWS longue durée dans le parcours normal ;
- SSH/OpenSearch ouverts au monde au lieu d'un `/32` ;
- EC2 sans IMDSv2 ;
- volumes racine non chiffrés ;
- tfvars désynchronisés ;
- secrets ou fichiers locaux suivis par Git ;
- destruction implicite ;
- images VHD/VHDX accidentellement versionnées.

Politique complète : [SECURITY.md](SECURITY.md).
