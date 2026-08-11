# Troubleshooting — diagnostic du projet P5

Ce guide couvre les problèmes du poste **Windows 11 Pro + WSL2**, du socle Ubuntu
et du parcours AWS. L'objectif est de diagnostiquer sans supprimer un état
Terraform, sans contourner un garde-fou et sans recréer des ressources au hasard.

## Réflexe de base

Pour un problème local WSL2, commencer dans PowerShell par :

```powershell
.\scripts\windows\status-p5.ps1
.\scripts\windows\check-wsl2-p5.ps1
```

Pour un problème du parcours Linux/AWS :

```bash
bash scripts/commands/p5.sh logs
```

Pour un diagnostic complet :

```bash
bash scripts/commands/collect-diagnostics.sh --complet --avec-preuves
```

**Ne jamais supprimer un `terraform.tfstate` comme méthode de dépannage.**

## 1. `wsl.exe` est introuvable

Vérifier que PowerShell est lancé sur Windows 11 puis :

```powershell
wsl --status
```

Si WSL n'est pas installé, relancer le script d'installation dans un PowerShell
administrateur :

```powershell
.\scripts\windows\install-wsl2-p5.ps1
```

Le script refuse une exécution non administrateur.

## 2. La distribution `p5-devops` est absente

```powershell
wsl --list --verbose
```

Puis :

```powershell
.\scripts\windows\install-wsl2-p5.ps1
```

Le script n'écrase pas une distribution existante.

## 3. La distribution est arrêtée

État :

```powershell
.\scripts\windows\status-p5.ps1
```

Démarrage :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Un état `Stopped` n'indique aucune perte de données.

## 4. Après `wsl --shutdown` ou un redémarrage Windows

Relancer :

```powershell
.\scripts\windows\start-p5.ps1
.\scripts\windows\status-p5.ps1
wsl -d p5-devops
```

L'IPv4 WSL2 peut changer. C'est normal en NAT et aucune modification du dépôt
n'est nécessaire.

## 5. WSL2 ne voit pas 6 CPU ou 16 Go

Contrôler :

```powershell
Get-Content $env:USERPROFILE\.wslconfig
```

La cible doit contenir :

```ini
[wsl2]
memory=16GB
processors=6
swap=8GB
networkingMode=nat
```

Réappliquer le modèle :

```powershell
.\scripts\windows\install-wsl2-p5.ps1
```

Puis arrêter totalement WSL :

```powershell
wsl --shutdown
```

et redémarrer `p5-devops`.

## 6. `systemd` n'est pas PID 1

Contrôler :

```powershell
wsl -d p5-devops -- ps -p 1 -o comm=
```

Réappliquer la configuration :

```powershell
.\scripts\windows\configure-wsl2-p5.ps1
```

Puis :

```powershell
wsl --terminate p5-devops
.\scripts\windows\start-p5.ps1
```

## 7. Pas d'IPv4 WSL2

```powershell
wsl -d p5-devops hostname -I
```

Dans Ubuntu :

```bash
ip -4 addr show
ip route show default
```

Si aucune route par défaut n'existe, arrêter complètement WSL puis relancer :

```powershell
wsl --shutdown
.\scripts\windows\start-p5.ps1
```

Ne pas ajouter une IP statique manuellement dans Ubuntu pour contourner le NAT
WSL2.

## 8. DNS WSL2 en échec

Dans Ubuntu :

```bash
getent ahostsv4 github.com
cat /etc/resolv.conf
```

Côté Windows, vérifier le modèle :

```powershell
Get-Content $env:USERPROFILE\.wslconfig
```

Le profil attendu contient :

```text
dnsTunneling=true
```

Puis :

```powershell
wsl --shutdown
.\scripts\windows\start-p5.ps1
```

## 9. Internet fonctionne sous Windows mais pas dans WSL2

Tester dans Ubuntu :

```bash
ip route show default
getent ahostsv4 github.com
curl -I https://github.com
```

Puis exécuter :

```powershell
.\scripts\windows\check-wsl2-p5.ps1
```

Un VPN, proxy ou firewall Windows peut modifier le comportement du réseau. Le
projet conserve `autoProxy=true` et `dnsTunneling=true` dans le profil WSL2.

## 10. Le dépôt est exécuté depuis `/mnt/c`

Le projet doit être utilisé depuis le système de fichiers Linux pour éviter les
problèmes de performances et de permissions :

```bash
mkdir -p ~/labs
cd ~/labs
git clone https://github.com/mathiasseguincadiche/p5_Openclassrooms.git
```

Chemin recommandé :

```text
~/labs/p5_Openclassrooms
```

## 11. Le bootstrap demande une reconnexion

Le bootstrap peut ajouter l'utilisateur au groupe Docker ou installer NVM.

Quitter Ubuntu :

```bash
exit
```

Puis :

```powershell
.\scripts\windows\stop-p5.ps1
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Ensuite :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

## 12. Docker est inaccessible

Dans Ubuntu :

```bash
docker info
systemctl status docker --no-pager
id
```

Si l'utilisateur vient d'être ajouté au groupe Docker, redémarrer la distribution
comme indiqué dans la section précédente.

Ne pas utiliser `sudo docker` comme solution permanente.

## 13. Le socle DevOps reste incomplet

```bash
bash scripts/commands/p5.sh status
```

Puis :

```bash
node --version
docker info
terraform version
ansible-playbook --version
aws --version
```

Côté Windows :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

## 14. Une sauvegarde WSL2 échoue

Vérifier l'état de la distribution :

```powershell
.\scripts\windows\status-p5.ps1
```

Puis relancer :

```powershell
.\scripts\windows\backup-p5.ps1
```

Le script arrête `p5-devops` avant l'export VHDX et calcule un SHA-256.

Vérifier que le disque de destination dispose de suffisamment d'espace libre.

## 15. Une restauration WSL2 est refusée

La restauration refuse volontairement d'écraser une distribution existante.
Lister les distributions :

```powershell
wsl --list --verbose
```

Utiliser un nouveau nom de restauration si nécessaire :

```powershell
.\scripts\windows\restore-p5.ps1 `
  -BackupPath <fichier.vhdx> `
  -DistroName p5-devops-restored
```

Après restauration :

```powershell
.\scripts\windows\status-p5.ps1 -DistroName p5-devops-restored
```

## 16. Mauvais compte AWS ou session expirée

Symptômes :

- identité AWS illisible ;
- compte différent de `P5_EXPECTED_ACCOUNT_ID` ;
- `GO AWS` refusé.

Relancer :

```bash
bash scripts/commands/p5.sh prepare
```

Diagnostic :

```bash
aws --profile p5-lab sts get-caller-identity
aws configure get region --profile p5-lab
```

Ne jamais modifier l'identifiant de compte attendu uniquement pour faire passer
un mauvais compte actif.

## 17. L'adresse publique `/32` n'est plus valide

L'IPv4 publique Windows/Internet a changé. Elle est indépendante de l'IPv4 WSL2.

Relancer :

```bash
bash scripts/commands/p5.sh prepare
```

En manuel :

```bash
$EDITOR environment/aws-readiness.env
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

Ne pas remplacer `P5_PUBLIC_IP_CIDR` par l'adresse privée WSL2.

## 18. `terraform.tfvars` désynchronisés

```bash
bash scripts/commands/sync-terraform-tfvars.sh --apply
bash scripts/commands/sync-terraform-tfvars.sh --check
```

La source de vérité reste `environment/aws-readiness.env`.

## 19. Collision de ressources P5

Ne pas :

- supprimer `terraform.tfstate` ;
- supprimer immédiatement les ressources dans la console AWS ;
- changer les tags pour contourner le contrôle.

Vérifier :

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-2 state list
terraform -chdir=terraform/exercice-3 state list
```

Puis relancer :

```bash
bash scripts/commands/p5.sh all
```

## 20. Quota EC2 insuffisant

Vérifier le quota EC2 Standard dans la région du projet. Ne pas réduire
arbitrairement `P5_REQUIRED_STANDARD_VCPUS` pour obtenir un faux `GO AWS`.

## 21. Le budget AWS est absent

```bash
bash scripts/commands/p5.sh prepare
```

Ou :

```bash
./scripts/commands/setup-aws-guardrails.sh
./scripts/commands/setup-aws-guardrails.sh --apply
```

## 22. Terraform ne trouve pas l'AMI Ubuntu

```bash
./scripts/commands/check-aws-readiness.sh --stage initial
```

L'AMI EC2 Ubuntu utilisée dans AWS est indépendante d'Ubuntu 26.04 exécuté dans
WSL2.

## 23. Ansible ne joint pas l'EC2

Consulter d'abord les logs `wait-ssh-ex1` ou `ansible-ping`.

```bash
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
cat ansible/inventories/hosts_aws
ls -l ~/.ssh/p5-key
```

Permissions :

```bash
chmod 600 ~/.ssh/p5-key
```

Test direct :

```bash
ssh -i ~/.ssh/p5-key ubuntu@ADRESSE_EC2
```

Vérifier aussi le `/32` du Security Group.

## 24. Le playbook Ansible échoue

Consulter `ansible-deploy`.

Sur l'EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx --no-pager -n 100
```

## 25. L'idempotence Ansible échoue

Le second passage doit produire :

```text
changed=0
unreachable=0
failed=0
```

Si `changed>0`, identifier la tâche qui modifie encore la cible à chaque passage.

## 26. L'artefact Angular est désynchronisé

```bash
./scripts/commands/prepare-angular-artifact.sh
./scripts/commands/validate.sh
```

## 27. Angular répond mais le fallback SPA échoue

```bash
./scripts/commands/verify-angular-deployment.sh
```

Tests :

```bash
curl -i http://ADRESSE_EC2/
curl -i http://ADRESSE_EC2/parcours-p5
```

La configuration NGINX doit conserver le fallback SPA vers `/index.html`.

## 28. Aucun vrai log NGINX n'est disponible

```bash
bash scripts/commands/p5.sh ex1
```

Ou :

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 96
./scripts/commands/collect-nginx-access-log.sh \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

## 29. OpenSearch n'est pas accessible

```bash
terraform -chdir=terraform/exercice-2 output
./scripts/commands/check-aws-readiness.sh --stage exercice-2
```

Causes fréquentes :

- domaine encore en création ;
- IPv4 publique `/32` périmée ;
- endpoint incorrect ;
- HTTPS/TLS ;
- session AWS expirée.

L'IPv4 privée WSL2 n'est pas celle qui doit être autorisée dans OpenSearch.

## 30. Les données OpenSearch échouent à la vérification

```bash
./scripts/commands/import-opensearch-data.sh --apply
./scripts/commands/verify-opensearch-data.sh
```

Le jeu versionné assure la reproductibilité ; le log réel prouve le bout en bout.

## 31. Le dashboard OpenSearch ne montre pas les trois graphiques

Contrôler d'abord que les données sont prêtes puis vérifier le data view
`nginx-access-*` avec `@timestamp`.

Les trois vues attendues sont :

1. Terms sur `http_method` ;
2. Date histogram `12h` + Sum sur `bytes_sent` ;
3. Date histogram `12h` + Terms taille 5 sur `url_path`.

## 32. L'exercice 3 ne trouve pas le VPC

L'exercice 1 doit encore exister :

```bash
./scripts/commands/check-aws-readiness.sh --stage exercice-3
```

Ne jamais détruire l'exercice 1 avant l'exercice 3.

## 33. HAProxy ne montre qu'un backend

```bash
./scripts/commands/test-haproxy-roundrobin.sh --requests 12
```

Sur les backends :

```bash
sudo docker ps
sudo docker logs nginx-hello
curl http://localhost/
```

Sur HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
```

## 34. Le test de panne HAProxy échoue

```bash
./scripts/commands/test-haproxy-failover.sh
./scripts/commands/test-haproxy-failover.sh --apply
```

Vérifier clé SSH, utilisateur `ubuntu`, `/32` et outputs Terraform.

## 35. `p5.sh all` a été interrompu

Ne pas nettoyer les états ni recommencer manuellement au hasard.

Si WSL2 est arrêté :

```powershell
.\scripts\windows\start-p5.ps1
wsl -d p5-devops
```

Puis :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh all
```

Terraform réévalue les états existants.

## 36. `p5.sh finalize` échoue

Consulter le log `livrables-strict`. Corriger uniquement les preuves réelles
manquantes puis relancer :

```bash
bash scripts/commands/p5.sh finalize
```

## 37. Nettoyage AWS incomplet

```bash
bash scripts/commands/p5.sh cleanup
```

Le verdict final n'est attendu qu'après destruction des exercices 3, 2 puis 1 :

```text
NETTOYAGE AWS COMPLET
```

Le nettoyage AWS ne supprime pas WSL2 ni les sauvegardes VHDX.

## 38. La CI échoue

Validation Linux :

```bash
bash scripts/commands/p5.sh status --full-validation
bash scripts/tests/test-p5-orchestrator.sh
python3 scripts/tools/audit_non_regression.py
python3 scripts/tools/audit_secrets.py
```

Validation WSL2 :

```powershell
.\scripts\windows\check-wsl2-p5.ps1 -RequireTools
```

La CI protège également le contrat Windows 11 / WSL2 et parse les scripts
PowerShell.

## 39. La CI est verte mais AWS réel échoue

C'est possible. La CI teste le dépôt et les intégrations locales sans utiliser les
credentials AWS réels.

Le premier `p5.sh all` depuis `p5-devops` reste le test d'intégration AWS final.
Conserver le log exact de la première étape en échec au lieu de lancer plusieurs
corrections au hasard.
