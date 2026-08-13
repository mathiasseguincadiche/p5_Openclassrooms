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

## Choisir le bon document

La documentation est organisée par **besoin**, pas seulement par sujet technique.

| Situation | Document recommandé | Rôle |
| --- | --- | --- |
| Je découvre le projet | [01-parcours-debutant.md](01-parcours-debutant.md) | comprendre le parcours sans se perdre dans tous les détails |
| Je veux exécuter le projet | [RUNBOOK_EXECUTION_GUIDEE.md](RUNBOOK_EXECUTION_GUIDEE.md) | procédure opératoire A → Z |
| Je veux utiliser le menu | [CENTRE_DE_COMMANDE.md](CENTRE_DE_COMMANDE.md) | options, risques, mutations et équivalents CLI |
| Je veux comprendre l'architecture | [architecture-et-flux.md](architecture-et-flux.md) | composants et flux |
| Je veux comprendre la convergence | [convergence-et-reexecution.md](convergence-et-reexecution.md) | reprise, idempotence et calcul de delta |
| Je suis bloqué | [troubleshooting.md](troubleshooting.md) | diagnostic et reprise |
| Je prépare les preuves | [validation-preuves-nettoyage.md](validation-preuves-nettoyage.md) | contrôles, livrables et nettoyage |
| Je veux comprendre les exigences | [02-correspondance-consignes-depot.md](02-correspondance-consignes-depot.md) | correspondance consignes ↔ dépôt |

Pour afficher cette carte depuis le terminal :

```bash
bash scripts/commands/p5.sh docs
```

Pour obtenir une recommandation selon votre situation :

```bash
bash scripts/commands/p5.sh guide
```

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

## Control Center V11

Le menu interactif est lancé par :

```bash
bash scripts/commands/p5.sh
```

Il classe les actions en cinq groupes :

```text
DÉMARRER / REPRENDRE
EXERCICES
PARCOURS COMPLET
VALIDATION / SOUTENANCE
AIDE / MAINTENANCE
```

Avant une action opérationnelle, il indique :

- si une mutation locale est possible ;
- si une mutation AWS est possible ;
- si un coût AWS est possible ;
- la commande CLI équivalente.

Le menu n'introduit aucune seconde logique d'orchestration. `p5.sh` reste la
source d'exécution.

Guide détaillé : [CENTRE_DE_COMMANDE.md](CENTRE_DE_COMMANDE.md).

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
| Diagnostic complet | `bash scripts/commands/p5.sh diagnostics` |
| Validation locale complète | `bash scripts/commands/p5.sh status --full-validation` |
| Finaliser | `bash scripts/commands/p5.sh finalize` |
| Logs | `bash scripts/commands/p5.sh logs` |
| Aide au choix | `bash scripts/commands/p5.sh guide` |
| Carte documentaire | `bash scripts/commands/p5.sh docs` |
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

### Je débute

1. [Parcours débutant](01-parcours-debutant.md)
2. [Centre de commande V11](CENTRE_DE_COMMANDE.md)
3. [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)

### Je veux exécuter le projet

1. [Préparation de l'environnement](00-preparation-environnement.md)
2. [Runbook A → Z](RUNBOOK_EXECUTION_GUIDEE.md)
3. [Préparation AWS](00b-preparation-compte-aws.md)
4. [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)

### Je veux comprendre l'architecture

- [Cadre officiel](00-cadre-officiel.md)
- [Architecture technique et flux](architecture-et-flux.md)
- [Convergence et réexécution](convergence-et-reexecution.md)

### Je dois diagnostiquer

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
bash scripts/commands/p5.sh diagnostics
```

Puis consulter [Troubleshooting](troubleshooting.md).

### Je prépare la soutenance

```bash
bash scripts/commands/p5.sh status
bash scripts/commands/p5.sh finalize
```

Puis consulter :

- [Validation, preuves et nettoyage](validation-preuves-nettoyage.md)
- [Livrables](livrables/README.md)

### Je veux comprendre les exercices

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
| Menu et aide opérateur | `scripts/commands/p5.sh` + `CENTRE_DE_COMMANDE.md` |
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
- `p5.sh diagnostics` reste non destructif côté AWS ;
- le Control Center doit rester une façade au-dessus des fonctions existantes ;
- aucune preuve fictive n'est présentée comme une exécution réelle ;
- les fichiers sensibles et runtime restent non versionnés.
