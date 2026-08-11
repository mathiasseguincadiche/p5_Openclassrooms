# 01 — Parcours d'exécution de bout en bout

Ce document est le **runbook principal synthétique** du projet. Le poste de
contrôle local est désormais **Windows 11 Pro + WSL2 + Ubuntu 26.04 LTS**.

Pour une exécution détaillée écran par écran, utiliser aussi le
[Runbook d'exécution guidée A → Z](RUNBOOK_EXECUTION_GUIDEE.md).

Référence d'architecture :
[Architecture technique et flux](architecture-et-flux.md).

## Règles du parcours

- travailler dans la distribution WSL2 `p5-devops` ;
- conserver le dépôt sous `~/labs/` dans le système de fichiers Linux ;
- ne pas coder en dur l'IPv4 privée WSL2 ;
- ne jamais versionner `environment/aws-readiness.env`, `terraform.tfvars`, les
  états Terraform, `logs/`, `proofs/runtime/` ou les sauvegardes VHDX ;
- considérer `environment/aws-readiness.env` comme la source unique des paramètres
  dépendant du compte AWS ;
- relire chaque plan Terraform avant `apply` ;
- ne jamais détruire l'exercice 1 avant la fin de l'exercice 3 ;
- conserver les preuves avant destruction ;
- terminer par l'audit AWS global.

## 1. Préparer Windows 11 et WSL2

Depuis PowerShell administrateur :

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows\install-wsl2-p5.ps1
```

Premier lancement :

```powershell
wsl -d p5-devops
```

Après création de l'utilisateur Linux :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

La cible locale est :

```text
6 CPU
16 Go RAM
8 Go swap
NAT
DNS tunneling
systemd
hostname p5-devops
```

## 2. Installer le socle DevOps

Dans Ubuntu WSL2 :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
cd p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Si le bootstrap demande une nouvelle session :

```bash
exit
```

Puis sous PowerShell :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

## 3. Inspecter avant mutation

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh inspect
```

Cette commande observe le socle, AWS, les tfvars, les états Terraform, l'inventaire,
l'artefact Angular et les preuves existantes sans créer de ressource.

## 4. Parcours recommandé

```bash
bash scripts/commands/p5.sh all
```

Le parcours complet est :

```text
prepare
  │
  ├─ contrôle du socle Ubuntu WSL2
  ├─ bootstrap si nécessaire
  ├─ configuration AWS locale
  ├─ synchronisation des tfvars
  ├─ budget
  └─ GO AWS + GO TERRAFORM
  │
  ▼
ex1
  ├─ build Angular
  ├─ Terraform exercice 1
  ├─ inventaire Ansible
  ├─ attente SSH/cloud-init
  ├─ déploiement
  ├─ second passage → changed=0
  ├─ vérification Angular/NGINX
  └─ collecte du vrai access.log
  │
  ▼
ex2
  ├─ Terraform OpenSearch
  ├─ import reproductible
  ├─ import du vrai access.log
  ├─ vérification mappings/agrégations
  └─ dashboard + captures manuelles
  │
  ▼
ex3
  ├─ Terraform HAProxy + 2 backends
  ├─ round-robin
  ├─ panne contrôlée
  └─ reprise et réintégration
  │
  ▼
diagnostics + preuves + livrables
```

## 5. Préparation AWS

```bash
bash scripts/commands/p5.sh prepare
```

La commande prend en charge :

- profil AWS ;
- authentification temporaire ;
- identité et région ;
- IPv4 publique `/32` ;
- clé SSH ;
- confirmations de sécurité ;
- budget ;
- génération et synchronisation des tfvars ;
- contrôles AWS Ready.

L'IPv4 publique `/32` est différente de l'IPv4 privée WSL2.

Conditions de sortie :

```text
GO AWS
GO TERRAFORM
```

## 6. Exercice 1 — Terraform, Ansible, NGINX et Angular

```bash
bash scripts/commands/p5.sh ex1
```

Le second passage Ansible doit obligatoirement produire :

```text
changed=0
unreachable=0
failed=0
```

Le vrai log NGINX est ensuite collecté pour l'exercice 2.

## 7. Exercice 2 — Amazon OpenSearch

```bash
bash scripts/commands/p5.sh ex2
```

Deux sources sont utilisées :

1. `terraform/exercice-2/samples/nginx-access.log.sample` ;
2. `proofs/runtime/exercice-2/nginx-access-real.log`.

Le dashboard reste manuel et doit présenter :

- les méthodes HTTP ;
- `bytes_sent` par tranches de 12 h ;
- le top 5 des `url_path` par tranches de 12 h.

## 8. Exercice 3 — HAProxy

```bash
bash scripts/commands/p5.sh ex3
```

Prérequis : l'exercice 1 existe encore.

Le test prouve :

```text
round-robin
     ↓
panne réelle d'un backend
     ↓
continuité de service
     ↓
redémarrage
     ↓
réintégration
```

## 9. Reprise après interruption

### Terminal fermé

```powershell
wsl -d p5-devops
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

### Distribution arrêtée

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Puis relancer `p5.sh all`.

### Windows redémarré ou `wsl --shutdown`

```powershell
.\scripts\windows\start-p5.ps1
.\scripts\windows\status-p5.ps1
wsl -d p5-devops
```

L'IPv4 WSL peut changer. Aucune modification du dépôt n'est nécessaire.

Règle absolue : **ne jamais supprimer un `terraform.tfstate` pour forcer la
reprise**.

## 10. Sauvegarde WSL2

```powershell
.\scripts\windows\backup-p5.ps1
```

La sauvegarde complète est un VHDX accompagné de son SHA-256.

Pour restaurer :

```powershell
.\scripts\windows\restore-p5.ps1 -BackupPath <fichier.vhdx>
```

La restauration est non destructive et utilise un nouveau nom de distribution.

## 11. Logs et diagnostic

```bash
bash scripts/commands/p5.sh logs
```

Les logs opérateur sont sous `logs/<UTC>/`. Les preuves pédagogiques restent sous
`proofs/runtime/`.

Diagnostic WSL2 :

```powershell
.\scripts\windows\status-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

## 12. Finalisation

```bash
bash scripts/commands/p5.sh finalize
```

Verdict attendu :

```text
LIVRABLES PRÊTS POUR RELECTURE FINALE
```

## 13. Nettoyage AWS

```bash
bash scripts/commands/p5.sh cleanup
```

Ordre obligatoire :

```text
Exercice 3 → Exercice 2 → Exercice 1
```

Verdict final :

```text
NETTOYAGE AWS COMPLET
```

Le nettoyage AWS ne supprime pas la distribution WSL2.

## 14. Niveau de validation

| Niveau | Preuve |
| --- | --- |
| Windows / WSL2 | scripts PowerShell + contrat CI WSL2 |
| Code | CI, syntaxe, tests, audits |
| Intégrations locales | Angular/NGINX, OpenSearch, HAProxy |
| AWS réel | `p5.sh all` depuis `p5-devops` avec session AWS valide |

Une CI verte ne remplace pas le premier déploiement réel AWS.

## Checklist de fin

- [ ] Windows 11 + WSL2 validés ;
- [ ] 6 CPU / 16 Go / systemd / réseau validés ;
- [ ] `p5.sh all` exécuté sur AWS réel ;
- [ ] idempotence Ansible prouvée ;
- [ ] logs NGINX réels collectés ;
- [ ] OpenSearch et dashboard validés ;
- [ ] HAProxy round-robin, panne et reprise validés ;
- [ ] `p5.sh finalize` réussi ;
- [ ] sauvegarde WSL2 créée si nécessaire ;
- [ ] `p5.sh cleanup` réussi ;
- [ ] `NETTOYAGE AWS COMPLET` obtenu.
