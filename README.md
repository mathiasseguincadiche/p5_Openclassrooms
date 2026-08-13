# P5 OpenClassrooms — Infrastructure as Code sur AWS

[![CI](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/ci.yml)
[![Non-régression](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/non-regression.yml)
[![Sécurité](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml/badge.svg)](https://github.com/mathiasseguincadiche/p5_Openclassrooms/actions/workflows/security.yml)

Projet réalisé dans le cadre du parcours **Expert DevOps OpenClassrooms**.

Le dépôt automatise un lab AWS reproductible autour de Terraform, Ansible,
Angular/NGINX, Amazon OpenSearch et HAProxy.

> **Périmètre évalué : 100 % AWS.** La workstation Windows/WSL2 est un poste de
> contrôle local ; les ressources évaluées sont créées dans AWS.

## Démarrage rapide — quel document ouvrir ?

Le dépôt conserve plusieurs documents parce qu'ils répondent à des besoins
différents. Pour un débutant, utiliser cette règle simple :

| Je veux... | Commencer par |
| --- | --- |
| comprendre le projet | [Parcours débutant](docs/01-parcours-debutant.md) |
| lancer le projet | [Runbook A → Z](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| utiliser le menu | [Centre de commande V11](docs/CENTRE_DE_COMMANDE.md) |
| comprendre l'architecture | [Architecture et flux](docs/architecture-et-flux.md) |
| résoudre un problème | [Troubleshooting](docs/troubleshooting.md) |
| préparer les preuves | [Validation, preuves et nettoyage](docs/validation-preuves-nettoyage.md) |
| parcourir toute la documentation | [Portail documentaire](docs/README.md) |

Le point d'entrée opérationnel reste unique :

```bash
bash scripts/commands/p5.sh
```

Le **Control Center V11** est une amélioration ergonomique du menu existant. Il
ne remplace ni Terraform, ni Ansible, ni les scripts P5 et n'introduit pas de
deuxième logique d'orchestration.

## Workstation utilisée

Le P5 ne construit plus sa propre plateforme WSL2. Il consomme la workstation
maintenue par :

- `mathiasseguincadiche/Windows_11_Pro_Custom`
- <https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom>

La séparation de responsabilités est volontaire :

```text
Windows_11_Pro_Custom
└── Windows 11 Pro
    └── WSL2
        └── Ubuntu — D:\WSL\Ubuntu-DevOps
            ├── systemd
            ├── Docker Engine
            ├── Terraform
            ├── Ansible Core
            ├── AWS CLI
            ├── kubectl / Helm
            ├── Minikube / kind
            └── outils DevOps

p5_Openclassrooms
└── utilise cette plateforme existante
    ├── vérifie le contrat P5
    ├── corrige uniquement les écarts spécifiques au projet
    ├── prépare AWS
    ├── exécute Terraform / Ansible / Angular
    ├── exploite OpenSearch
    └── teste HAProxy
```

P5 ne possède donc plus de copie de `.wslconfig`, de `/etc/wsl.conf`, de script
d'installation WSL2 ni de procédure VHDX concurrente.

## Profils WSL2 acceptés

La source de vérité reste `Windows_11_Pro_Custom` :

| Profil | CPU | RAM | Swap | Réseau |
| --- | ---: | ---: | ---: | --- |
| `standard` | 8 threads | 20 Go | 8 Go | `mirrored` |
| `lab-heavy` | 12 threads | 28 Go | 12 Go | `mirrored` |
| `nat-fallback` | 8 threads | 20 Go | 8 Go | `nat` |

`standard` est recommandé pour le P5. `lab-heavy` peut être utilisé pour les
validations locales plus lourdes et `nat-fallback` reste un mode de secours.

La distribution utilisée est nommée :

```text
Ubuntu
```

## Préparation avant P5

Dans le dépôt `Windows_11_Pro_Custom`, qualifier d'abord la workstation :

```powershell
.\install.ps1 -Mode Apply
```

Après le premier lancement Ubuntu et la création de l'utilisateur :

```powershell
.\install.ps1 -Mode Apply -InstallDevOps
wsl --shutdown
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Verdicts amont attendus :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Le backup Windows/WSL2 appartient également à ce dépôt amont via sa V7.

## Installer le projet dans Ubuntu

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Puis dans Ubuntu :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Le checkout de travail doit rester sur le filesystem Linux, pas sous `/mnt/c` ou
`/mnt/d`.

## Contrôler le delta P5

La workstation contient déjà la stack DevOps générale. Commencer par un contrôle
sans mutation :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si tout est compatible avec le contrat P5, rien n'est réinstallé.

Si un écart propre au projet existe, par exemple une version Node.js attendue :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap reste convergent : il inspecte avant de modifier et ne corrige que
les composants nécessaires au P5.

## Démarrage recommandé

Pour ouvrir le menu interactif :

```bash
bash scripts/commands/p5.sh
```

Le Control Center V11 distingue clairement observation, convergence, déploiement,
diagnostic, finalisation, aide et destruction. Avant une action opérationnelle,
il rappelle si elle peut modifier la machine, AWS ou générer des coûts.

Pour démarrer directement en CLI :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

`inspect` observe l'état actuel sans mutation. `all` exécute le parcours
technique complet sans détruire automatiquement les ressources AWS.

Pour automatiser uniquement les confirmations automatisables :

```bash
bash scripts/commands/p5.sh all --yes
```

`--yes` ne contourne jamais les validations humaines de sécurité, le checkpoint
OpenSearch Dashboards ni la confirmation `DETRUIRE`.

## Centre de commande

| Commande | Rôle |
| --- | --- |
| `p5.sh` / `p5.sh menu` | Control Center interactif V11 |
| `p5.sh inspect` | observation sans mutation |
| `p5.sh prepare` | convergence P5 + AWS + budget + tfvars |
| `p5.sh status` | contrôles de préparation |
| `p5.sh ex1` | Terraform + Ansible + Angular/NGINX |
| `p5.sh ex2` | Amazon OpenSearch et données |
| `p5.sh ex3` | HAProxy, round-robin, panne et reprise |
| `p5.sh all` | parcours technique complet |
| `p5.sh diagnostics` | diagnostics et structure des preuves |
| `p5.sh finalize` | validation stricte des preuves/livrables |
| `p5.sh logs` | journaux d'exécution |
| `p5.sh guide` | aide au choix du parcours |
| `p5.sh docs` | carte de la documentation |
| `p5.sh cleanup` | destruction 3 → 2 → 1 puis audit AWS |

Le détail complet de chaque option est dans
[docs/CENTRE_DE_COMMANDE.md](docs/CENTRE_DE_COMMANDE.md).

## Architecture AWS

```text
Windows 11 Pro
└── WSL2 / Ubuntu
    └── Terraform + Ansible + AWS CLI + Docker + Node.js
              │
              ▼
AWS — us-east-1
│
├── Exercice 1
│   ├── VPC 10.0.0.0/16
│   ├── 2 sous-réseaux publics
│   ├── Internet Gateway + routes
│   ├── EC2 Ubuntu
│   └── Ansible → NGINX → Angular
│                │
│                └── access.log réel ─────► Exercice 2
│                                            Amazon OpenSearch
│                                            └── Dashboards
│
└── Exercice 3
    ├── réutilise le réseau de l'exercice 1
    ├── EC2 HAProxy
    └── 2 EC2 → Docker → nginxdemos/hello
```

Le réseau WSL2, qu'il soit `mirrored` ou `nat-fallback`, n'altère pas le VPC AWS.
`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration vue depuis AWS,
pas une adresse privée WSL.

## Portes de validation

Avant Terraform :

```text
GO AWS
GO TERRAFORM
```

Après le nettoyage final :

```text
NETTOYAGE AWS COMPLET
```

## Convergence

Le principe du dépôt reste :

```text
inspecter
   ↓
comparer état réel ↔ état attendu
   ↓
aucun delta ? ── oui ──► aucune mutation
   │
   non
   ↓
corriger uniquement le delta
   ↓
vérifier
   ↓
journaliser
```

Cela s'applique également à la workstation : si Docker, Terraform, Ansible ou
AWS CLI fournis par le dépôt Windows satisfont déjà le contrat P5, ils sont
réutilisés.

## Exercice 1 — Terraform, Ansible, NGINX et Angular

```bash
bash scripts/commands/p5.sh ex1
```

Le second passage Ansible doit prouver :

```text
changed=0
unreachable=0
failed=0
```

Guide : [Terraform + Ansible](docs/exercices/01-terraform-ansible.md).

## Exercice 2 — Amazon OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Le véritable exercice utilise Amazon OpenSearch Service. Les conteneurs locaux
servent uniquement aux validations reproductibles.

Guide : [OpenSearch](docs/exercices/02-elk-opensearch.md).

## Exercice 3 — HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

Le test vérifie le round-robin, une panne réelle contrôlée et la réintégration du
backend.

Guide : [HAProxy](docs/exercices/03-haproxy.md).

## Reprise

Après fermeture d'un terminal ou redémarrage Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh all
```

Ne supprimez jamais un `terraform.tfstate` pour forcer une reprise tant que les
ressources AWS associées existent.

## Diagnostic

Le parcours recommandé avant toute correction manuelle est :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consulter [Troubleshooting](docs/troubleshooting.md).

## Sauvegarde de la workstation

P5 ne fournit plus de backup VHDX. Depuis `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

La V7 protège Windows et exporte Ubuntu en VHDX avec SHA-256.

## Schémas du parcours

- [Vue d'ensemble](docs/schemas/vue-ensemble.svg)
- [Préparation workstation et AWS](docs/schemas/etape-0.svg)
- [Exercice 1](docs/schemas/exercice-1.svg)
- [Exercice 2](docs/schemas/exercice-2.svg)
- [Exercice 3](docs/schemas/exercice-3.svg)
- [Finalisation](docs/schemas/finalisation/finalisation.svg)

## Documentation

| Besoin | Document |
| --- | --- |
| Portail | [docs/README.md](docs/README.md) |
| Control Center V11 | [docs/CENTRE_DE_COMMANDE.md](docs/CENTRE_DE_COMMANDE.md) |
| Préparation | [docs/00-preparation-environnement.md](docs/00-preparation-environnement.md) |
| Contrat WSL2 | [environment/wsl2/README.md](environment/wsl2/README.md) |
| Runbook A → Z | [docs/RUNBOOK_EXECUTION_GUIDEE.md](docs/RUNBOOK_EXECUTION_GUIDEE.md) |
| Parcours débutant | [docs/01-parcours-debutant.md](docs/01-parcours-debutant.md) |
| Architecture | [docs/architecture-et-flux.md](docs/architecture-et-flux.md) |
| Convergence | [docs/convergence-et-reexecution.md](docs/convergence-et-reexecution.md) |
| Troubleshooting | [docs/troubleshooting.md](docs/troubleshooting.md) |
| Sécurité | [SECURITY.md](SECURITY.md) |
