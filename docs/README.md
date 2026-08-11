# Documentation du projet P5

Cette documentation décrit le parcours automatisé recommandé, les procédures de
reprise et les règles de validation du P5.

Le périmètre évalué reste **100 % AWS**. La workstation locale est fournie par le
dépôt amont :

- `mathiasseguincadiche/Windows_11_Pro_Custom`
- <https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom>

```text
Windows_11_Pro_Custom
└── Windows 11 Pro
    └── WSL2
        └── Ubuntu — D:\WSL\Ubuntu-DevOps
            └── stack DevOps générale
                    │
                    ▼
p5_Openclassrooms
└── contrat P5 + AWS + exercices + preuves
```

Le P5 ne provisionne plus WSL2, ne maintient plus de `.wslconfig` et ne possède
plus de scripts VHDX concurrents.

## Plateforme amont

Les profils WSL2 de référence sont gérés uniquement dans
`Windows_11_Pro_Custom` :

| Profil | Threads | RAM | Swap | Réseau |
| --- | ---: | ---: | ---: | --- |
| `standard` | 8 | 20 Go | 8 Go | `mirrored` |
| `lab-heavy` | 12 | 28 Go | 12 Go | `mirrored` |
| `nat-fallback` | 8 | 20 Go | 8 Go | `nat` |

La distribution utilisée par le P5 est :

```text
Ubuntu
```

## Avant de lancer P5

Depuis le dépôt `Windows_11_Pro_Custom`, qualifier la workstation :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Verdicts attendus :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Puis ouvrir Ubuntu :

```powershell
wsl -d Ubuntu
```

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le bootstrap P5 ne sert plus à construire la workstation. Il contrôle uniquement
les exigences spécifiques au projet et ne corrige un composant que s'il est
absent ou incompatible.

## Exécution recommandée

```bash
bash scripts/commands/p5.sh all
```

Le parcours est :

```text
workstation amont déjà qualifiée
        ↓
contrat P5 local
        ↓
prepare
        ↓
GO AWS + GO TERRAFORM
        ↓
ex1
Terraform → EC2 → Ansible → NGINX → Angular
        ↓
ex2
Amazon OpenSearch + données + dashboard
        ↓
ex3
HAProxy → round-robin → panne → reprise
        ↓
diagnostics + preuves + livrables
```

Le mode `all` ne détruit pas automatiquement AWS.

## Commandes principales

| Besoin | Commande |
| --- | --- |
| Menu | `bash scripts/commands/p5.sh` |
| Inspecter sans modifier | `bash scripts/commands/p5.sh inspect` |
| Préparer | `bash scripts/commands/p5.sh prepare` |
| Vérifier | `bash scripts/commands/p5.sh status` |
| Exercice 1 | `bash scripts/commands/p5.sh ex1` |
| Exercice 2 | `bash scripts/commands/p5.sh ex2` |
| Exercice 3 | `bash scripts/commands/p5.sh ex3` |
| Tout exécuter | `bash scripts/commands/p5.sh all` |
| Validation locale complète | `bash scripts/commands/p5.sh status --full-validation` |
| Finaliser | `bash scripts/commands/p5.sh finalize` |
| Logs | `bash scripts/commands/p5.sh logs` |
| Nettoyer AWS | `bash scripts/commands/p5.sh cleanup` |

## Sauvegarde de la workstation

La sauvegarde Windows/WSL2 appartient exclusivement au dépôt amont.

Depuis `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

La V7 couvre l'image Windows et l'export Ubuntu VHDX avec SHA-256.

## Réseau

Le choix `mirrored` ou `nat-fallback` concerne uniquement la workstation locale.
Le VPC AWS `10.0.0.0/16` et ses sous-réseaux ne changent pas.

`P5_PUBLIC_IP_CIDR` représente toujours l'IPv4 publique `/32` d'administration
vue depuis AWS, jamais une IP WSL2.

## Par où commencer ?

### Exécuter le projet

1. [Préparation de l'environnement](00-preparation-environnement.md)
2. [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
3. [Parcours synthétique](01-parcours-debutant.md)
4. [Préparation AWS](00b-preparation-compte-aws.md)
5. [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)

### Comprendre l'architecture

- [Cadre officiel](00-cadre-officiel.md)
- [Architecture technique et flux](architecture-et-flux.md)
- [Convergence et réexécution](convergence-et-reexecution.md)

### Diagnostiquer

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Puis consulter [Troubleshooting](troubleshooting.md).

### Comprendre les exercices

- [Exercice 1 — Terraform, Ansible, NGINX et Angular](exercices/01-terraform-ansible.md)
- [Exercice 2 — Logs NGINX et OpenSearch](exercices/02-elk-opensearch.md)
- [Exercice 3 — HAProxy](exercices/03-haproxy.md)

## Sources de vérité

| Sujet | Source de vérité |
| --- | --- |
| Windows / WSL2 / profils / VHDX | `Windows_11_Pro_Custom` |
| Distribution locale | `Ubuntu` du dépôt amont |
| Contrat P5 | `environment/versions.env` + scripts P5 |
| Point d'entrée P5 | `scripts/commands/p5.sh` |
| Configuration AWS locale | `environment/aws-readiness.env` |
| Infrastructure | `terraform/exercice-*/` |
| Déploiement | `ansible/playbooks/deploy.yml` |
| Application | `application/angular/` |
| Preuves | `proofs/runtime/` local |
| Logs | `logs/` local |
| Sécurité | `SECURITY.md` |

## Règles documentaires

- une seule source de vérité pour la workstation : `Windows_11_Pro_Custom` ;
- P5 ne doit pas réintroduire un installateur WSL2 ou une copie de `.wslconfig` ;
- `Ubuntu` est le nom de distribution utilisé dans les procédures P5 ;
- `p5.sh` reste la voie normale d'exécution ;
- `p5.sh inspect` reste la voie normale d'observation ;
- aucune preuve fictive n'est présentée comme une exécution réelle ;
- les fichiers sensibles et runtime restent non versionnés.
