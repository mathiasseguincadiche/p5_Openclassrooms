# Poste de contrôle P5 — Windows 11 Pro + WSL2

Ce dossier définit le poste de contrôle local retenu pour le projet P5.
L'infrastructure évaluée reste créée dans AWS ; WSL2 fournit uniquement
l'environnement Linux local depuis lequel Terraform, Ansible, AWS CLI, Docker,
Node.js et les scripts du dépôt sont exécutés.

## Architecture locale

```text
Windows 11 Pro
└── WSL2
    └── p5-devops — Ubuntu 26.04 LTS
        ├── Terraform
        ├── Ansible Core
        ├── AWS CLI v2
        ├── Docker Engine + Compose
        ├── Node.js
        └── dépôt p5_Openclassrooms
```

## Ressources WSL2

Le profil de référence est `environment/wsl2/.wslconfig.example` :

- 6 processeurs logiques ;
- 16 Go de mémoire ;
- 8 Go de swap ;
- réseau WSL2 en mode NAT ;
- transfert `localhost` activé ;
- DNS tunneling activé ;
- pare-feu WSL/Hyper-V activé ;
- proxy Windows transmis automatiquement à WSL.

Ces limites s'appliquent à la VM WSL2 globale. Si plusieurs distributions WSL2
fonctionnent simultanément, elles partagent cette enveloppe CPU/RAM.

## Réseau

Le projet n'impose pas une IPv4 WSL codée en dur. En mode NAT, l'adresse de la
VM WSL2 peut changer après un arrêt complet de WSL ou un redémarrage Windows.
Les scripts détectent donc dynamiquement :

- l'adresse IPv4 WSL ;
- la passerelle par défaut ;
- la route par défaut ;
- la résolution DNS ;
- l'accès Internet.

Le plan AWS reste indépendant et inchangé : le VPC du projet conserve son
adressage `10.0.0.0/16` et ses routes Terraform.

## Installation

Depuis PowerShell administrateur :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Au premier démarrage d'Ubuntu, créer l'utilisateur Linux demandé par Ubuntu.
Puis, depuis le dépôt sous Windows :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
```

Après le redémarrage WSL déclenché par le script :

```powershell
.\scripts\windows\check-wsl2-p5.ps1
```

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
./scripts/commands/bootstrap-ubuntu-server.sh
./scripts/commands/setup.sh --check-only
```

## Exploitation quotidienne

```powershell
.\scripts\windows\start-p5.ps1
.\scripts\windows\status-p5.ps1
.\scripts\windows\stop-p5.ps1
```

`stop-p5.ps1` arrête uniquement la distribution P5. Pour arrêter toute la VM
WSL2 et toutes les distributions :

```powershell
wsl --shutdown
```

## Sauvegarde

Une sauvegarde complète peut être produite en VHDX :

```powershell
.\scripts\windows\backup-p5.ps1 -Destination D:\WSL-Backups
```

Le script arrête proprement `p5-devops`, exporte la distribution, vérifie que le
VHDX existe et relance la distribution sauf si `-NoRestart` est fourni.

## Restauration sûre

La restauration fournie par le dépôt importe le VHDX sous un nouveau nom afin
de ne jamais supprimer automatiquement une distribution existante :

```powershell
.\scripts\windows\restore-p5.ps1 `
  -BackupPath D:\WSL-Backups\p5-devops-YYYYMMDD-HHMMSS.vhdx `
  -NewDistroName p5-devops-restored `
  -InstallLocation D:\WSL\p5-devops-restored
```

Après validation de la copie restaurée, le remplacement d'une ancienne
distribution reste une opération humaine explicite.

## Plusieurs distributions

WSL2 peut exécuter plusieurs distributions simultanément. Elles ne doivent pas
être considérées comme des VM KVM indépendantes : elles partagent la VM WSL2,
son noyau, son enveloppe CPU/RAM et son réseau WSL. Pour un lab nécessitant des
VM avec adresses indépendantes, cartes réseau séparées ou snapshots de type
hyperviseur, utiliser Hyper-V ou un autre hyperviseur dédié.
