# Troubleshooting — diagnostic du projet P5

Ce guide sépare clairement les incidents de **workstation** des incidents du
**projet P5**.

## Règle de base

```text
Windows / WSL2 / profil / VHDX / Docker système
        ↓
Windows_11_Pro_Custom

AWS / Terraform / Ansible / Angular / OpenSearch / HAProxy
        ↓
p5_Openclassrooms
```

Ne jamais supprimer un `terraform.tfstate` comme méthode de dépannage.

## 1. WSL2 ou la distribution Ubuntu ne fonctionne pas

Le propriétaire de la plateforme est :

```text
mathiasseguincadiche/Windows_11_Pro_Custom
```

Commencer dans PowerShell :

```powershell
wsl --status
wsl --list --verbose
```

La distribution attendue est :

```text
Ubuntu
```

Puis, depuis le dépôt Windows :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

P5 ne doit pas tenter de recréer WSL2 ou modifier `.wslconfig` pour contourner
cet échec.

## 2. Le profil WSL2 n'est pas le bon

Les profils `standard`, `lab-heavy` et `nat-fallback` sont gérés uniquement dans
`Windows_11_Pro_Custom`.

Cibles actuelles :

```text
standard     → 8 threads / 20 Go / 8 Go / mirrored
lab-heavy    → 12 threads / 28 Go / 12 Go / mirrored
nat-fallback → 8 threads / 20 Go / 8 Go / NAT
```

Après un changement de profil dans le dépôt amont :

```powershell
wsl --shutdown
```

Puis relancer `Ubuntu` et la validation amont.

## 3. Le mode mirrored pose problème avec un VPN ou le réseau

Le profil `nat-fallback` existe précisément comme solution de secours dans le
dépôt Windows. Effectuer le changement depuis ce dépôt, pas depuis P5.

P5 reste indépendant d'une adresse privée WSL fixe.

## 4. Docker est inaccessible sans sudo

Valider d'abord la workstation :

```powershell
.\install.ps1 -Mode Verify -ValidateWsl -ValidateDevOps
```

Si l'utilisateur vient d'être ajouté au groupe Docker :

```powershell
wsl --shutdown
wsl -d Ubuntu
```

Puis dans Ubuntu :

```bash
docker info
```

## 5. Le contrat P5 n'est pas conforme

Dans Ubuntu :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

Si un composant strictement nécessaire au P5 est absent ou incompatible :

```bash
bash scripts/commands/bootstrap-ubuntu-server.sh
```

Ce script corrige uniquement le delta projet. Il ne doit jamais écrire la
configuration WSL2 globale.

## 6. Le dépôt P5 est sous `/mnt/c` ou `/mnt/d`

Recloner ou déplacer le checkout de travail dans le filesystem Linux :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
```

Utiliser ensuite :

```bash
cd ~/labs/p5_Openclassrooms
```

## 7. Diagnostic général P5

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
```

Diagnostic partageable :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

Analyser d'abord le premier `[ KO ]` et le journal précis de l'étape.

## 8. Mauvais compte AWS ou session expirée

Relancer :

```bash
bash scripts/commands/p5.sh prepare
```

Diagnostic manuel :

```bash
aws --profile p5-lab sts get-caller-identity
aws configure get region --profile p5-lab
```

Ne jamais modifier l'identifiant de compte attendu pour faire correspondre un
mauvais compte actif.

## 9. L'adresse `/32` AWS n'est plus valide

La connexion publique a changé.

```bash
bash scripts/commands/p5.sh prepare
```

Ou :

```bash
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

`P5_PUBLIC_IP_CIDR` est l'IPv4 publique vue depuis AWS, pas une IP WSL2.

## 10. `terraform.tfvars` désynchronisés

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

La source de vérité reste `environment/aws-readiness.env`.

## 11. Collision de ressources P5

Ne pas :

- supprimer le `terraform.tfstate` ;
- supprimer immédiatement les ressources dans la console AWS ;
- changer les tags pour contourner le contrôle.

Inspecter :

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-2 state list
terraform -chdir=terraform/exercice-3 state list
```

Puis relancer :

```bash
bash scripts/commands/p5.sh all
```

## 12. Quota EC2 insuffisant

Vérifier le quota EC2 Standard de la région. Les exercices 1 et 3 peuvent
coexister et nécessiter plusieurs instances.

Ne pas réduire artificiellement les garde-fous pour obtenir un faux `GO AWS`.

## 13. Terraform ne trouve pas l'AMI Ubuntu

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

La configuration normale sélectionne une AMI Canonical Ubuntu selon les filtres
du module Terraform.

## 14. Ansible ne joint pas l'EC2

Consulter d'abord les logs `wait-ssh-ex1` et `ansible-ping`.

Puis :

```bash
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
cat ansible/inventories/hosts_aws
ls -l ~/.ssh/p5-key
```

La clé privée doit être en mode `600` :

```bash
chmod 600 ~/.ssh/p5-key
```

Test direct :

```bash
ssh -i ~/.ssh/p5-key ubuntu@ADRESSE_EC2
```

## 15. Le playbook Ansible échoue

Consulter le log `ansible-deploy`.

Sur l'EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx --no-pager -n 100
```

## 16. L'idempotence Ansible échoue

Le second passage doit donner :

```text
changed=0
unreachable=0
failed=0
```

Si `changed>0`, identifier la tâche qui modifie encore la cible à chaque
exécution.

## 17. Angular ou l'artefact n'est plus synchronisé

```bash
./scripts/commands/prepare-angular-artifact.sh
./scripts/commands/validate.sh
```

Vérification du déploiement :

```bash
./scripts/commands/verify-angular-deployment.sh
```

## 18. Aucun log NGINX réel n'est disponible

```bash
bash scripts/commands/p5.sh ex1
```

Ou :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 96
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

## 19. OpenSearch n'est pas accessible

```bash
terraform -chdir=terraform/exercice-2 output
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Vérifier domaine, endpoint HTTPS, IP publique `/32` et session AWS.

## 20. Les données OpenSearch échouent

```bash
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/verify-opensearch-data.sh
```

La vérification porte sur le volume de documents, les méthodes HTTP, les tranches
temporelles et les chemins distincts.

## 21. Le dashboard n'est pas complet

Le checkpoint reste manuel. Vérifier le data view `nginx-access-*` avec
`@timestamp`, puis les trois visualisations demandées.

## 22. L'exercice 3 ne trouve pas le VPC

L'exercice 1 doit encore exister :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

## 23. HAProxy ne montre qu'un backend

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 12
```

Vérifier ensuite Docker sur les backends et HAProxy sur le frontal.

## 24. Le test de panne HAProxy échoue

Prévisualiser :

```bash
./scripts/commands/test-haproxy-failover.sh
```

Puis exécuter explicitement :

```bash
./scripts/commands/test-haproxy-failover.sh --apply
```

## 25. `p5.sh all` a été interrompu

Depuis Windows :

```powershell
wsl -d Ubuntu
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Terraform réévalue les états existants.

## 26. `p5.sh finalize` échoue

Consulter le log `livrables-strict`, compléter uniquement les preuves réelles,
puis relancer :

```bash
bash scripts/commands/p5.sh finalize
```

## 27. Nettoyage AWS incomplet

```bash
bash scripts/commands/p5.sh cleanup
```

Le verdict final n'est attendu qu'après destruction 3 → 2 → 1 :

```text
NETTOYAGE AWS COMPLET
```

## 28. La CI échoue

Validation locale :

```bash
bash scripts/commands/p5.sh status --full-validation
bash scripts/tests/test-p5-orchestrator.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

Une CI verte valide le dépôt et les intégrations locales, pas un déploiement réel
sur le compte AWS.

## 29. Backup ou restauration WSL2

Ne pas utiliser P5 pour cela. Depuis `Windows_11_Pro_Custom` :

```powershell
.\install.ps1 -BackupAction Create -BackupTargetDrive E:
.\install.ps1 -BackupAction Verify -BackupTargetDrive E:
.\install.ps1 -BackupAction RestorePlan -BackupTargetDrive E:
```

La V7 amont est la seule procédure de sauvegarde/restauration de la workstation.
