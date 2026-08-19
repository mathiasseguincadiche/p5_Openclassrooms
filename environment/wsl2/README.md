# Contrat WSL2 du P5

## Source de vérité

Le plan de contrôle P5 s'exécute dans la distribution WSL2 **`Ubuntu`**, Ubuntu
26.04 LTS (`resolute`), fournie et maintenue par
[`mathiasseguincadiche/Windows_11_Pro_Custom`](https://github.com/mathiasseguincadiche/Windows_11_Pro_Custom).

Le dépôt Windows possède :

- Windows 11 Pro, WSL2 et la distribution `Ubuntu` ;
- le VHDX sous `E:\WSL\Ubuntu-DevOps` et le swap WSL ;
- `.wslconfig`, `/etc/wsl.conf`, systemd, le réseau et le DNS ;
- Docker Engine, Terraform et AWS CLI.

Le P5 possède :

- ses versions Node.js et Ansible Core ;
- ses dépendances Angular et ses collections Ansible ;
- la configuration AWS du lab, les `terraform.tfvars`, states, inventaires, logs et preuves ;
- le réglage `vm.max_map_count` requis par le test OpenSearch local.

## Identité attendue

```text
hôte Windows       Windows 11 Pro
runtime Linux      WSL2
distribution       Ubuntu
source             Ubuntu-26.04
release            Ubuntu 26.04 LTS / resolute
architecture       amd64
init               systemd
stockage VHDX      E:\WSL\Ubuntu-DevOps
réseau             mirrored, avec repli NAT géré par la plateforme
```

## Workspace obligatoire

Le checkout doit vivre dans le filesystem Linux du VHDX, sous l'une de ces
racines :

```text
~/projects
~/labs
~/repositories
```

`/mnt/c` et `/mnt/e` sont interdits comme racines de travail. Le fait que le
VHDX soit physiquement stocké sur `E:` ne transforme pas le filesystem Ubuntu
en DrvFS : le projet reste en EXT4 dans `/home/<utilisateur>`.

## Contrôle initial

Depuis PowerShell, valider d'abord la plateforme :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
wsl.exe -d Ubuntu
```

Puis, dans Ubuntu :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/bootstrap-wsl2.sh --check-only
bash scripts/commands/p5.sh inspect
```

Le P5 ne crée, ne supprime, n'exporte et ne déplace jamais une distribution
WSL. Toute opération sur le VHDX ou le cycle de vie WSL reste dans le dépôt
Windows.
