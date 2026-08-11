# Environnement de lab — Étapes 0A et 0B

Ce dossier définit les **prérequis P5** et la **source de configuration AWS**.

La plateforme Windows/WSL2 n'est plus provisionnée par ce dépôt. Elle est fournie
et maintenue par le dépôt amont :

- `mathiasseguincadiche/Windows_11_Pro_Custom`
- <https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom>

## 1. Séparation des responsabilités

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
            └── outils qualité DevOps

p5_Openclassrooms
└── consomme l'Ubuntu WSL2 existant
    ├── vérifie les prérequis du P5
    ├── converge uniquement les écarts propres au projet
    ├── prépare AWS et les terraform.tfvars
    └── exécute les exercices P5
```

P5 **ne possède plus** :

- l'installation de WSL2 ;
- la création de la distribution Ubuntu ;
- `%UserProfile%\.wslconfig` ;
- `/etc/wsl.conf` ;
- les profils `standard`, `lab-heavy` et `nat-fallback` ;
- le stockage du VHDX ;
- le swap WSL ;
- la sauvegarde/restauration Windows ou WSL2.

Ces éléments restent la responsabilité de `Windows_11_Pro_Custom` afin d'éviter
deux sources de vérité concurrentes.

## 2. Plateforme amont attendue

Le dépôt Windows fournit actuellement les profils suivants :

| Profil | CPU | RAM | Swap | Réseau |
| --- | ---: | ---: | ---: | --- |
| `standard` | 8 threads | 20 Go | 8 Go | `mirrored` |
| `lab-heavy` | 12 threads | 28 Go | 12 Go | `mirrored` |
| `nat-fallback` | 8 threads | 20 Go | 8 Go | `nat` |

Pour le P5, `standard` est le profil quotidien recommandé. `lab-heavy` peut être
utilisé pour les validations locales lourdes. `nat-fallback` reste accepté en cas
d'incompatibilité réseau.

La distribution attendue par le poste Windows est nommée :

```text
Ubuntu
```

Elle est stockée sous :

```text
D:\WSL\Ubuntu-DevOps
```

## 3. Préparer la workstation avant P5

Dans le dépôt `Windows_11_Pro_Custom`, depuis PowerShell administrateur :

```powershell
.\install.ps1 -Mode Apply
```

Après le premier lancement Ubuntu et la création de l'utilisateur Linux :

```powershell
.\install.ps1 -Mode Apply -InstallDevOps
wsl --shutdown
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Les verdicts amont recherchés sont notamment :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Une fois ces contrôles verts, **ne relancez pas une installation WSL depuis P5**.

## 4. Entrer dans l'environnement P5

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Dans Ubuntu, conserver le dépôt sur le filesystem Linux :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Éviter `/mnt/c` et `/mnt/d` pour le checkout de travail Linux.

## 5. Convergence spécifique P5

Le dépôt Windows fournit déjà la stack DevOps générale. Le bootstrap P5 doit donc
être vu comme un **contrôle de compatibilité et de delta projet**, pas comme un
installateur de workstation.

Commencer sans mutation :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si le verdict indique que tout est conforme, aucune installation n'est faite.
Si un écart propre au P5 existe — par exemple une version Node.js de référence —
le bootstrap normal peut converger uniquement cet écart :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Puis :

```bash
bash scripts/commands/p5.sh inspect
```

## 6. `versions.env` — contrat du projet

`environment/versions.env` fixe les versions ou minima utilisés par les scripts
et la CI du **P5**. Ces contraintes restent dans ce dépôt car elles font partie de
la reproductibilité du projet, même lorsque les outils sont déjà installés par la
workstation amont.

Le principe reste :

```text
outil amont déjà compatible
        ↓
aucune mutation

outil absent ou incompatible avec le contrat P5
        ↓
correction du delta uniquement
```

## 7. `aws-readiness.env` — source unique des paramètres AWS

Créer la configuration locale :

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
```

Ce fichier centralise notamment :

| Catégorie | Variables principales |
| --- | --- |
| Session | `AWS_PROFILE`, `AWS_REGION` |
| Compte | `P5_EXPECTED_ACCOUNT_ID` |
| Réseau d'administration | `P5_PUBLIC_IP_CIDR` |
| EC2 | AMI optionnelle, type d'instance, clé SSH |
| OpenSearch | moteur, nœud, domaine, stockage |
| Quotas | vCPU Standard requis |
| Coûts | budget, limite et e-mail de notification |
| Sécurité | confirmations MFA, root, IAM et facturation |

`P5_PUBLIC_IP_CIDR` représente l'IPv4 publique d'administration visible depuis
AWS. Ce n'est pas une adresse privée WSL2, quel que soit le profil réseau actif.

## 8. Générer les `terraform.tfvars`

Aperçu :

```bash
bash scripts/commands/sync-terraform-tfvars.sh
```

Écriture :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Contrôle :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

## 9. Garde-fous AWS

Préparer puis vérifier :

```bash
bash scripts/commands/setup-aws-guardrails.sh --apply
bash scripts/commands/check-aws-readiness.sh --stage initial
bash scripts/commands/pre-deployment-check.sh --stage initial
```

Verdicts recherchés :

```text
GO AWS
GO TERRAFORM
```

## 10. Sauvegarde et restauration

La sauvegarde de la workstation et de WSL2 appartient au dépôt Windows. Le P5 ne
fournit pas de système VHDX concurrent.

Dans `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

La V7 du dépôt amont protège l'image Windows et exporte également Ubuntu en VHDX
avec SHA-256.

## 11. Ce qui ne doit jamais être versionné

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- sauvegardes VHD/VHDX ;
- preuves runtime brutes.

## Références

- [Contrat workstation WSL2](wsl2/README.md)
- [Préparation de l'environnement](../docs/00-preparation-environnement.md)
- [Architecture et flux](../docs/architecture-et-flux.md)
- [Parcours complet](../docs/01-parcours-debutant.md)
- [Troubleshooting](../docs/troubleshooting.md)
