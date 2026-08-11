# Environnement de lab — Étapes 0A et 0B

Ce dossier définit le **socle local reproductible** et la **source de configuration
AWS** du projet P5.

Le poste de contrôle officiel du projet est désormais :

```text
Windows 11 Pro
└── WSL2 — 6 processeurs / 16 Go RAM / 8 Go swap
    └── p5-devops — Ubuntu 26.04 LTS
        └── outils DevOps du P5
```

L'infrastructure évaluée reste entièrement créée dans AWS. WSL2 remplace
l'ancien hyperviseur local ; il ne remplace ni Terraform ni les ressources AWS.

```text
environment/
├── README.md
├── apt-packages.txt
├── versions.env
├── aws-readiness.env.example
└── wsl2/
    ├── README.md
    ├── .wslconfig.example
    └── wsl.conf.example
```

Le fichier réel `environment/aws-readiness.env` est local, ignoré par Git et ne
doit contenir aucune clé d'accès AWS.

## 1. `versions.env` — versions de référence

Ce fichier fixe les versions attendues par le lab et les contrôles :

- Ubuntu Server 26.04 sous WSL2 ;
- Node.js 22.22.0 ;
- Ansible Core 2.20.1 ;
- Terraform 1.15.8 ;
- versions des images Docker utilisées par les tests locaux.

Le bootstrap et les validations lisent ce fichier. Pour modifier une version de
référence, il faut donc vérifier le script d'installation, la CI et les tests
associés dans la même évolution.

## 2. Étape 0A — construire le poste Windows 11 + WSL2

Depuis PowerShell administrateur :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Le profil `%UserProfile%\.wslconfig` est convergé vers :

```ini
[wsl2]
memory=16GB
processors=6
swap=8GB
networkingMode=nat
localhostForwarding=true
dnsTunneling=true
firewall=true
autoProxy=true
```

Après le premier lancement Ubuntu et la création de l'utilisateur Linux :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

La distribution utilise le hostname `p5-devops` et `systemd` comme PID 1.
L'adresse IPv4 WSL, la passerelle et la route sont détectées dynamiquement :
aucune IP WSL privée n'est codée en dur dans le projet.

Guide détaillé : [`environment/wsl2/README.md`](wsl2/README.md).

## 3. Installer le socle DevOps dans Ubuntu

Dans `p5-devops` :

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script installe le socle sans créer de ressource AWS ni configurer de secret.
Terraform est installé depuis l'archive HashiCorp officielle avec vérification
SHA-256. Ansible Core est installé avec `pipx`, Node.js avec NVM et Docker depuis
le dépôt Docker officiel.

Après reconnexion :

```bash
./scripts/commands/setup.sh --check-only
```

Ce contrôle valide Ubuntu et la présence des composants critiques du dépôt.
Pour contrôler également la couche Windows/WSL2 :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

Guide canonique :
[`docs/00-preparation-environnement.md`](../docs/00-preparation-environnement.md).

## 4. Exploitation, arrêt et sauvegarde WSL2

Commandes quotidiennes :

```powershell
.\scripts\windows\start-p5.ps1
.\scripts\windows\status-p5.ps1
.\scripts\windows\stop-p5.ps1
```

Sauvegarde complète VHDX avec manifeste SHA-256 :

```powershell
.\scripts\windows\backup-p5.ps1 -Destination D:\WSL-Backups
```

Restauration non destructive sous un nouveau nom :

```powershell
.\scripts\windows\restore-p5.ps1 `
  -BackupPath D:\WSL-Backups\p5-devops-YYYYMMDD-HHMMSS.vhdx `
  -NewDistroName p5-devops-restored `
  -InstallLocation D:\WSL\p5-devops-restored
```

Plusieurs distributions WSL2 peuvent fonctionner en parallèle, mais elles
partagent la VM WSL2 globale, son noyau, son réseau et l'enveloppe de ressources
6 CPU / 16 Go. Elles ne sont pas traitées comme des VM réseau indépendantes.

## 5. `aws-readiness.env` — source unique des paramètres AWS

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
| OpenSearch | moteur, type de nœud, domaine, stockage |
| Quotas | vCPU Standard requis |
| Coûts | budget, limite et e-mail de notification |
| Sécurité | confirmations MFA, clés root, IAM et facturation |

Les confirmations `..._CONFIRMED=yes` ne doivent être renseignées qu'après
vérification réelle dans la console AWS.

## 6. Génération des `terraform.tfvars`

Les trois `terraform.tfvars` sont des **sorties générées**, pas des sources de
configuration indépendantes.

Aperçu sans écriture :

```bash
bash scripts/commands/sync-terraform-tfvars.sh
```

Écriture réelle en mode `600` :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
```

Contrôle de cohérence :

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Toute modification de région, compte, IP, type d'instance ou paramètres
OpenSearch doit être faite dans `aws-readiness.env`, puis propagée avec ce
script.

L'adresse WSL privée n'est pas utilisée comme `P5_PUBLIC_IP_CIDR` : cette
variable représente l'IPv4 publique d'administration visible depuis AWS.

## 7. Étape 0B — garde-fous AWS

Prévisualiser la création du budget :

```bash
./scripts/commands/setup-aws-guardrails.sh
```

Créer explicitement le budget :

```bash
./scripts/commands/setup-aws-guardrails.sh --apply
```

Puis vérifier le compte :

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
./scripts/commands/pre-deployment-check.sh --stage initial
```

Le premier contrôle est centré sur le compte, l'identité, les quotas, les coûts
et les dépendances AWS. Le second ajoute la cohérence locale du dépôt, des
versions, de la clé SSH et des variables Terraform.

Verdicts recherchés :

```text
GO AWS
GO TERRAFORM
```

Guide canonique :
[`docs/00b-preparation-compte-aws.md`](../docs/00b-preparation-compte-aws.md).

## 8. Ce qui ne doit jamais être versionné

- `environment/aws-readiness.env` ;
- `terraform.tfvars` ;
- états et plans Terraform ;
- clés SSH privées ;
- credentials AWS ;
- sauvegardes `.vhdx` WSL ;
- preuves runtime brutes.

Ces exclusions sont protégées par `.gitignore`, `audit_secrets.py` et la CI.

## 9. Références

- [Poste Windows 11 + WSL2](wsl2/README.md)
- [Architecture et flux](../docs/architecture-et-flux.md)
- [Parcours complet](../docs/01-parcours-debutant.md)
- [Garde-fous AWS](../aws/README.md)
- [Troubleshooting](../docs/troubleshooting.md)
