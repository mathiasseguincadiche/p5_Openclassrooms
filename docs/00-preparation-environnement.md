# Étape 0A — Préparer le poste Windows 11 + WSL2

Cette étape construit le **poste de contrôle DevOps** du projet. Windows 11 Pro
héberge WSL2 et la distribution `p5-devops` sous Ubuntu 26.04. Cette distribution
exécute Terraform, Ansible, AWS CLI, Node.js, Docker et les scripts du dépôt ;
elle ne remplace pas les infrastructures AWS évaluées.

La préparation du compte est traitée ensuite dans
[l’étape 0B — AWS Ready](00b-preparation-compte-aws.md).

![Préparation de la VM](schemas/etape-0.svg)

## Résultat attendu

Un poste de contrôle avec :

- Windows 11 Pro ;
- WSL2 à jour ;
- distribution `p5-devops` sous Ubuntu 26.04 LTS ;
- 6 processeurs logiques maximum pour la VM WSL2 ;
- 16 Go de RAM maximum pour la VM WSL2 ;
- 8 Go de swap ;
- `systemd` actif ;
- réseau WSL2 NAT ;
- IPv4, passerelle et route détectées dynamiquement ;
- DNS tunneling ;
- Git, Python, Terraform, Ansible, AWS CLI et Docker ;
- Node.js 22.22.0 avec NVM ;
- dépôt cloné dans le système de fichiers Linux ;
- clé SSH dédiée au lab AWS ;
- validation locale réussie.

Le verdict de fin d’étape est :

```text
Étape 0A validée. Poursuivez avec le contrôle AWS Ready.
```

## Dimensionnement retenu

| Ressource | Cible P5 |
| --- | ---: |
| Processeurs WSL2 | 6 |
| Mémoire WSL2 | 16 Go |
| Swap WSL2 | 8 Go |
| Stockage | VHDX WSL2 dynamique |
| Réseau | NAT WSL2 |
| DNS | DNS tunneling |

Le fichier `%UserProfile%\.wslconfig` configure la **VM WSL2 globale**. Si
plusieurs distributions WSL2 sont lancées simultanément, elles partagent cette
enveloppe de 6 CPU et 16 Go de RAM.

La distribution ne porte pas le domaine Amazon OpenSearch du livrable : ce
service est créé dans AWS.

## Versions de référence

La source de vérité Linux est :

```text
environment/versions.env
```

Le dépôt fixe notamment :

| Composant | Référence |
| --- | --- |
| Hôte | Windows 11 Pro |
| Virtualisation locale | WSL2 |
| Ubuntu | 26.04 |
| Node.js | 22.22.0 |
| Ansible Core | 2.20.1 |
| Terraform | 1.15.8 |
| OpenSearch local de test | 2.19.6 |
| NGINX local de test | `nginx:1.28-alpine` |
| HAProxy local de test | `haproxy:3.2-alpine` |

## 1. Installer WSL2 et Ubuntu 26.04

Cloner d'abord le dépôt côté Windows ou récupérer les scripts, puis ouvrir un
PowerShell administrateur :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Le script :

1. exige Windows 11 ;
2. met WSL à jour ;
3. définit WSL2 comme version par défaut ;
4. applique `environment/wsl2/.wslconfig.example` ;
5. installe Ubuntu 26.04 sous le nom `p5-devops` si nécessaire ;
6. n'écrase pas une distribution existante ;
7. arrête WSL pour appliquer le profil global.

Le profil cible est :

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

## 2. Créer l'utilisateur Ubuntu puis configurer la distribution

Premier lancement :

```powershell
wsl -d p5-devops
```

Terminer la création de l'utilisateur Linux proposée par Ubuntu, puis revenir
dans PowerShell :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
```

Ce script configure :

- `systemd=true` ;
- hostname `p5-devops` ;
- génération normale de `/etc/hosts` et `/etc/resolv.conf` ;
- utilisateur Ubuntu par défaut ;
- distribution `p5-devops` comme distribution WSL par défaut.

Il redémarre ensuite la distribution et exige `systemd` en PID 1.

## 3. Contrôler CPU, RAM, réseau, route et DNS

Depuis PowerShell :

```powershell
.\scripts\windows\check-wsl2-p5.ps1
```

Le contrôle valide notamment :

- noyau WSL2 ;
- au moins 6 processeurs disponibles ;
- environ 16 Go de RAM visibles ;
- `systemd` ;
- hostname ;
- IPv4 WSL ;
- passerelle ;
- route par défaut ;
- résolution DNS ;
- sortie TCP/443.

### Adressage WSL2

Le mode retenu est NAT. L'adresse est obtenue dynamiquement :

```powershell
wsl -d p5-devops hostname -I
```

Dans Ubuntu :

```bash
ip -4 addr show
ip route show default
getent ahostsv4 github.com
```

L'IPv4 privée WSL n'est **pas** codée en dur : elle peut changer après un
`wsl --shutdown` ou un redémarrage Windows. Le projet détecte donc l'IP et la
passerelle au runtime.

Le VPC AWS `10.0.0.0/16`, ses sous-réseaux et ses routes Terraform restent
inchangés et indépendants de ce réseau local.

## 4. Cloner le dépôt dans le système de fichiers Linux

Le travail doit rester dans le VHDX Linux plutôt que sous `/mnt/c` :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
```

Cette disposition évite de faire dépendre les performances des outils Linux des
montages NTFS Windows.

## 5. Installer le socle automatiquement

```bash
./scripts/commands/bootstrap-ubuntu-server.sh
```

Le script :

- refuse une exécution en `root` ;
- contrôle que le système est Ubuntu ;
- installe les paquets de base avec APT ;
- télécharge **Terraform depuis l’archive officielle HashiCorp** ;
- vérifie le SHA-256 de l’archive Terraform ;
- installe Docker Engine et Compose depuis le dépôt Docker ;
- installe AWS CLI v2 ;
- installe Ansible Core avec `pipx` ;
- installe NVM et la version Node.js fixée ;
- installe `markdownlint-cli2` ;
- ajoute l’utilisateur au groupe `docker` ;
- contrôle les versions obtenues.

Il ne :

- configure aucun secret AWS ;
- lance aucun `terraform apply` ;
- crée aucune ressource AWS ;
- crée aucune clé SSH à votre place.

## 6. Recharger la session Linux

Après le bootstrap :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
```

Puis reconnectez-vous :

```powershell
wsl -d p5-devops
```

Vérifiez :

```bash
node --version
docker info
```

Node.js doit afficher :

```text
v22.22.0
```

## 7. Configurer Git

```bash
git config --global user.name "Votre nom"
git config --global user.email "votre-adresse@example.com"
git config --global init.defaultBranch main
```

## 8. Créer la clé SSH du lab

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/p5-key -C "p5-lab"
chmod 600 ~/.ssh/p5-key
chmod 644 ~/.ssh/p5-key.pub
```

La clé privée :

```text
~/.ssh/p5-key
```

ne doit jamais entrer dans le dépôt.

La clé publique sera utilisée par Terraform pour créer la paire EC2.

## 9. Préparer le profil AWS

Le mode recommandé est IAM Identity Center :

```bash
aws configure sso --profile p5-lab
aws sso login --profile p5-lab
export AWS_PROFILE=p5-lab
aws sts get-caller-identity
```

Un rôle IAM fourni par une organisation est également acceptable.

La validation stricte du compte est réalisée à l’étape 0B ; ici, on vérifie
seulement que l’outil AWS CLI peut être utilisé.

## 10. Valider le poste de contrôle

Validation Linux :

```bash
./scripts/commands/setup.sh --check-only
```

Validation Windows + WSL2 + outils :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

Les deux doivent réussir avant AWS Ready.

## 11. Validation locale complète

Commande standard :

```bash
./scripts/commands/validate.sh
```

Elle couvre selon les outils disponibles :

- structure du dépôt ;
- non-régression ;
- Angular ;
- NGINX ;
- HAProxy local ;
- données OpenSearch ;
- Terraform ;
- Ansible ;
- Bash ;
- YAML ;
- Markdown ;
- livrables.

Pour inclure OpenSearch local :

```bash
P5_FULL_INTEGRATION=1 ./scripts/commands/validate.sh
```

Cette validation ne crée aucune infrastructure AWS.

## 12. Arrêt et reprise

État :

```powershell
.\scripts\windows\status-p5.ps1
```

Arrêt de la distribution P5 uniquement :

```powershell
.\scripts\windows\stop-p5.ps1
```

Reprise :

```powershell
.\scripts\windows\start-p5.ps1
```

Arrêt de toute la VM WSL2 et de toutes les distributions :

```powershell
wsl --shutdown
```

Les données du VHDX sont persistantes entre les arrêts et démarrages.

## 13. Point de restauration WSL2

Après validation du socle :

```powershell
.\scripts\windows\backup-p5.ps1 -Destination D:\WSL-Backups
```

Le script :

1. arrête `p5-devops` si nécessaire ;
2. exporte un VHDX complet ;
3. calcule un SHA-256 ;
4. écrit un fichier `.sha256` associé ;
5. relance la distribution si elle était active.

Restauration non destructive :

```powershell
.\scripts\windows\restore-p5.ps1 `
  -BackupPath D:\WSL-Backups\p5-devops-YYYYMMDD-HHMMSS.vhdx `
  -NewDistroName p5-devops-restored `
  -InstallLocation D:\WSL\p5-devops-restored
```

Le script refuse de remplacer automatiquement une distribution existante.

## 14. Diagnostic en cas de problème

Couche Windows/WSL2 :

```powershell
.\scripts\windows\check-wsl2-p5.ps1
wsl --status
wsl --version
wsl --list --verbose
```

Couche Linux/P5 :

```bash
bash scripts/commands/collect-diagnostics.sh
```

Voir : [Troubleshooting](troubleshooting.md).

## Ce que l’étape 0A ne valide pas

Elle ne garantit pas :

- le MFA root ;
- le bon compte AWS ;
- le budget ;
- les quotas ;
- la région ;
- l’IPv4 publique d’administration `/32` ;
- les permissions nécessaires ;
- l’absence de collision avec des ressources AWS déjà présentes.

Ces éléments appartiennent à l’étape 0B.

## Étape suivante obligatoire

```bash
cp environment/aws-readiness.env.example environment/aws-readiness.env
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
./scripts/commands/setup-aws-guardrails.sh --apply
./scripts/commands/pre-deployment-check.sh --stage initial
```

Lire :
[Étape 0B — Préparer et valider AWS](00b-preparation-compte-aws.md).
