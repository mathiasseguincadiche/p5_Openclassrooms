# Contrat WSL2 du P5

Le P5 **n'installe plus WSL2** et ne maintient plus sa propre configuration de
workstation.

La plateforme Windows/WSL2 est fournie par :

- `mathiasseguincadiche/Windows_11_Pro_Custom`
- <https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom>

Ce dossier décrit uniquement le **contrat d'intégration** attendu par P5.

## Source de vérité

La propriété des éléments est la suivante :

```text
Windows_11_Pro_Custom
├── Windows 11 Pro
├── installation/mise à jour WSL2
├── distribution Ubuntu
├── D:\WSL\Ubuntu-DevOps
├── %UserProfile%\.wslconfig
├── /etc/wsl.conf
├── profils standard / lab-heavy / nat-fallback
├── Docker / Terraform / Ansible / AWS CLI / Kubernetes
├── qualification WSL2
└── sauvegarde/restauration V7

p5_Openclassrooms
├── contraintes spécifiques P5
├── configuration AWS du lab
├── Terraform des exercices
├── Ansible / Angular / OpenSearch / HAProxy
├── preuves et diagnostics
└── nettoyage AWS
```

Il ne doit exister **qu'une seule source de vérité** pour `.wslconfig` et le VHDX
WSL : le dépôt Windows.

## Distribution utilisée

La distribution fournie par le dépôt Windows est :

```text
Ubuntu
```

Son stockage cible est :

```text
D:\WSL\Ubuntu-DevOps
```

Les commandes P5 documentées utilisent donc :

```powershell
wsl -d Ubuntu
```

et non l'ancien nom `p5-devops`.

## Profils acceptés

Le dépôt Windows définit actuellement :

| Profil | Threads | RAM | Swap | Réseau | Usage P5 |
| --- | ---: | ---: | ---: | --- | --- |
| `standard` | 8 | 20 Go | 8 Go | `mirrored` | recommandé |
| `lab-heavy` | 12 | 28 Go | 12 Go | `mirrored` | validations lourdes |
| `nat-fallback` | 8 | 20 Go | 8 Go | `nat` | secours réseau |

P5 ne recopie pas ces fichiers et ne tente pas de les modifier.

## Qualification amont obligatoire

Avant de commencer P5, la workstation doit être qualifiée depuis le dépôt
`Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Verdicts attendus :

```text
VERDICT: V3 DEVOPS READY
VERDICT: V6 WSL2 PLATFORM READY
```

Cette qualification vérifie notamment les ressources du profil actif, WSL2,
`systemd`, le filesystem Linux et la stack DevOps générale.

## Contrôle P5

Une fois dans Ubuntu :

```powershell
wsl -d Ubuntu
```

puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le premier contrôle compare la workstation déjà construite au contrat du P5.
Il ne modifie rien avec `--check-only`.

Si un composant strictement nécessaire au P5 est absent ou incompatible :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Le bootstrap reste convergent : un outil déjà conforme n'est pas réinstallé.

## Réseau

Le profil quotidien amont utilise `mirrored`. Le profil `nat-fallback` reste
supporté.

Le P5 ne dépend pas d'une adresse privée WSL codée en dur. La valeur
`P5_PUBLIC_IP_CIDR` représente toujours **l'IPv4 publique d'administration vue
par AWS**, et non une adresse d'interface WSL.

## Sauvegarde

P5 ne fournit plus de scripts d'export/restauration WSL2.

La V7 du dépôt `Windows_11_Pro_Custom` est la source de vérité pour :

- image Windows `C:` + `D:` ;
- volumes critiques ;
- export de la distribution Ubuntu en VHDX ;
- SHA-256 ;
- plan de restauration non destructif.

Exemples depuis le dépôt Windows :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

## Règle de maintenance

Si le dimensionnement WSL2, le mode réseau, le chemin du VHDX ou la politique de
backup changent, la modification doit être faite **dans
`Windows_11_Pro_Custom`**, puis P5 adapte seulement son contrat documentaire si
nécessaire.
