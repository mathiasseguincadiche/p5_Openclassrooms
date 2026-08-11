# Documentation du projet P5

Cette documentation décrit le parcours automatisé recommandé, les procédures
manuelles de compréhension et les règles de reprise du projet.

Le périmètre évalué reste **100 % AWS**. Le poste de contrôle local est :

```text
Windows 11 Pro
└── WSL2
    └── p5-devops
        └── Ubuntu 26.04 LTS + systemd
```

La VM WSL2 globale est configurée avec **6 processeurs logiques, 16 Go de RAM,
8 Go de swap, NAT, DNS tunneling et firewall WSL/Hyper-V**.

Le changement de KVM vers WSL2 ne modifie pas l'architecture AWS : le VPC
`10.0.0.0/16`, ses sous-réseaux, ses routes et les ressources Terraform restent
indépendants du réseau local WSL2.

## Par où commencer ?

Pour une nouvelle machine Windows 11 :

1. [Préparer Windows 11 + WSL2](00-preparation-environnement.md)
2. [Guide WSL2 du dépôt](../environment/wsl2/README.md)
3. [Préparer le compte AWS](00b-preparation-compte-aws.md)
4. [Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md)

Pour comprendre le projet avant exécution :

1. [Cadre officiel et périmètre](00-cadre-officiel.md)
2. [Architecture technique et flux](architecture-et-flux.md)
3. [Convergence et réexécution intelligente](convergence-et-reexecution.md)
4. [Parcours d'exécution de bout en bout](01-parcours-debutant.md)

## Étape locale Windows 11 / WSL2

Depuis PowerShell administrateur :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Après la création initiale de l'utilisateur Ubuntu :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

Commandes d'exploitation :

| Besoin | Commande PowerShell |
| --- | --- |
| Démarrer `p5-devops` | `.\scripts\windows\start-p5.ps1` |
| Arrêter `p5-devops` | `.\scripts\windows\stop-p5.ps1` |
| État synthétique | `.\scripts\windows\status-p5.ps1` |
| Diagnostic complet | `.\scripts\windows\check-wsl2-p5.ps1 -RequireTools` |
| Sauvegarde VHDX | `.\scripts\windows\backup-p5.ps1` |
| Restauration | `.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>` |

L'IPv4 privée WSL, sa passerelle et la route par défaut sont détectées
dynamiquement. Le projet ne dépend pas d'une adresse WSL codée en dur.

## Centre de commande Linux

Une fois dans `p5-devops`, le point d'entrée principal est :

```bash
bash scripts/commands/p5.sh
```

Pour observer sans mutation :

```bash
bash scripts/commands/p5.sh inspect
```

Pour exécuter ou réexécuter le parcours complet :

```bash
bash scripts/commands/p5.sh all
```

Le centre de commande prend en charge :

1. inspection du socle Ubuntu WSL2 ;
2. convergence des outils Linux ;
3. configuration et authentification AWS ;
4. synchronisation des tfvars et budget ;
5. exercice 1 — Terraform, Ansible, Angular et NGINX ;
6. preuve d'idempotence Ansible ;
7. génération et collecte des logs NGINX réels ;
8. exercice 2 — OpenSearch et dashboard ;
9. exercice 3 — HAProxy, round-robin, panne et reprise ;
10. diagnostics, preuves, finalisation et nettoyage.

## Commandes principales

| Besoin | Commande Linux |
| --- | --- |
| Menu | `bash scripts/commands/p5.sh` |
| Inspecter sans modifier | `bash scripts/commands/p5.sh inspect` |
| Préparer / converger | `bash scripts/commands/p5.sh prepare` |
| Vérifier l'état | `bash scripts/commands/p5.sh status` |
| Exercice 1 | `bash scripts/commands/p5.sh ex1` |
| Exercice 2 | `bash scripts/commands/p5.sh ex2` |
| Exercice 3 | `bash scripts/commands/p5.sh ex3` |
| Tout exécuter | `bash scripts/commands/p5.sh all` |
| Validation complète | `bash scripts/commands/p5.sh status --full-validation` |
| Finaliser | `bash scripts/commands/p5.sh finalize` |
| Voir les logs | `bash scripts/commands/p5.sh logs` |
| Nettoyer AWS | `bash scripts/commands/p5.sh cleanup` |

Le mode `--yes` ne contourne ni les validations de sécurité nécessitant une
confirmation humaine, ni le checkpoint OpenSearch Dashboards, ni la confirmation
`DETRUIRE`.

## Parcours global

```text
Windows 11 + WSL2
        │
        ▼
p5-devops / Ubuntu 26.04
        │
        ▼
Inspection + convergence locale
        │
        ▼
AWS Ready + tfvars + budget
        │
        ▼
GO AWS + GO TERRAFORM
        │
        ▼
Exercice 1
Terraform → EC2 → Ansible → NGINX → Angular
        │                    │
        │                    ├─ second passage → changed=0
        │                    └─ logs NGINX réels
        │
        ├──────────────────────────► Exercice 2
        │                            Amazon OpenSearch
        │                            ├─ jeu reproductible
        │                            ├─ logs réels
        │                            └─ dashboard manuel
        │
        └──────────────────────────► Exercice 3
                                     HAProxy → 2 backends
                                     round-robin → panne → reprise
        │
        ▼
Diagnostics + preuves + livrables
        │
        ▼
Destruction 3 → 2 → 1
        │
        ▼
NETTOYAGE AWS COMPLET
```

![Vue d'ensemble](schemas/vue-ensemble.svg)

## Réexécution et reprise

Le modèle du dépôt est :

```text
inspecter → comparer → corriger uniquement le delta → vérifier → journaliser
```

Une distribution WSL2 arrêtée n'est pas perdue. Pour reprendre :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Puis dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Terraform réévalue l'état AWS existant. Il ne faut jamais supprimer un
`terraform.tfstate` pour forcer la reprise.

## Sauvegarde et restauration WSL2

Avant une étape importante, une sauvegarde complète peut être créée :

```powershell
.\scripts\windows\backup-p5.ps1
```

Le script arrête proprement la distribution, exporte un VHDX et calcule son
SHA-256.

Une restauration s'effectue sous un nouveau nom pour éviter l'écrasement d'un
environnement existant :

```powershell
.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>
```

## Guides par sujet

### Environnement et AWS

- [Étape 0A — Windows 11 + WSL2](00-preparation-environnement.md)
- [Guide WSL2](../environment/wsl2/README.md)
- [Étape 0B — AWS Ready](00b-preparation-compte-aws.md)
- [Architecture et flux](architecture-et-flux.md)

### Exercices

- [Exercice 1 — Terraform, Ansible, NGINX et Angular](exercices/01-terraform-ansible.md)
- [Exercice 2 — Logs NGINX et OpenSearch](exercices/02-elk-opensearch.md)
- [Exercice 3 — HAProxy](exercices/03-haproxy.md)

### Exploitation

- [Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
- [Parcours automatisé et reprise](01-parcours-debutant.md)
- [Convergence et réexécution](convergence-et-reexecution.md)
- [Troubleshooting](troubleshooting.md)
- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Scripts et commandes](../scripts/README.md)

### Remise et sécurité

- [Correspondance consignes → code → preuves](02-correspondance-consignes-depot.md)
- [Livrables et preuves](livrables/README.md)
- [Politique de sécurité](../SECURITY.md)

## Sources de vérité

| Sujet | Source de vérité |
| --- | --- |
| Configuration WSL2 | `environment/wsl2/.wslconfig.example` |
| Configuration Ubuntu WSL | `environment/wsl2/wsl.conf.example` |
| Scripts Windows | `scripts/windows/` |
| Point d'entrée Linux | `scripts/commands/p5.sh` |
| Versions Linux | `environment/versions.env` |
| Configuration AWS locale | `environment/aws-readiness.env` local |
| Architecture | `docs/architecture-et-flux.md` |
| Infrastructure | `terraform/exercice-*/` |
| Déploiement | `ansible/playbooks/deploy.yml` |
| Application | `application/angular/` |
| Preuves | `proofs/runtime/` local |
| Journaux | `logs/` local |
| Sécurité | `SECURITY.md` |

## Validation

Validation Linux :

```bash
bash scripts/commands/p5.sh status --full-validation
```

Validation WSL2 depuis Windows :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

La CI contrôle également le contrat **Windows 11 / WSL2**, le parsing des
scripts PowerShell, Terraform, Ansible, Angular, OpenSearch, HAProxy, Bash, YAML,
Markdown, les liens, les secrets et la non-régression.

Une CI verte ne remplace pas l'exécution réelle sur le compte AWS de l'opérateur.
