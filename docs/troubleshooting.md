# Troubleshooting — diagnostiquer le P5 sans casser l'état

## Règle générale

En cas d'échec :

```text
ne pas modifier au hasard
      ↓
inspecter
      ↓
identifier la couche en échec
      ↓
lire le log de cette couche
      ↓
corriger la cause
      ↓
relancer la commande convergente
```

Commencer **dans `ubuntu-devops`** par :

```bash
bash scripts/commands/p5.sh inspect
bash scripts/commands/p5.sh logs
```

Pour un diagnostic complet :

```bash
bash scripts/commands/p5.sh diagnostics
```

Avant de diagnostiquer AWS, distinguer la frontière :

```text
HOST / KVM / VM absente ou non joignable
→ Ubuntu-desktops-custom

runtime P5 / AWS / Terraform / Ansible / preuves
→ p5_Openclassrooms
```

## 1. Le bootstrap refuse l'environnement d'exécution

### Symptôme

Le bootstrap signale par exemple :

- runtime WSL détecté ;
- VM KVM/QEMU attendue ;
- hostname différent de `ubuntu-devops` ;
- filesystem du checkout non accepté.

### Cause

Le P5 est exécuté hors de son architecture de référence. Le runtime attendu est la VM `ubuntu-devops`, Ubuntu Server 26.04, créée et maintenue par `Ubuntu-desktops-custom`.

### Correction

Ne pas désactiver le garde-fou dans P5.

1. vérifier/réparer la VM via `Ubuntu-desktops-custom` ;
2. se connecter à `ubuntu-devops` ;
3. cloner ou ouvrir le P5 dans le filesystem Linux local du guest ;
4. relancer le contrôle.

Dans la VM :

```bash
hostname -s
cat /etc/os-release
systemd-detect-virt
findmnt -T ~/labs -n -o FSTYPE
cd ~/labs/p5_Openclassrooms
bash scripts/commands/bootstrap-ubuntu-server.sh --check-only
```

## 2. Docker est installé mais inutilisable sans sudo

### Symptôme

Le bootstrap retourne le code `90` ou Docker refuse l'accès au daemon.

### Cause probable

L'utilisateur vient d'être ajouté au groupe Docker mais la session SSH courante n'a pas encore rechargé ses groupes.

### Correction

Fermer la session SSH puis se reconnecter à `ubuntu-devops`.

Ensuite :

```bash
cd ~/labs/p5_Openclassrooms
bash scripts/commands/p5.sh status
```

Ne pas réinstaller Docker pour ce symptôme.

## 3. `aws sts get-caller-identity` échoue

### Vérifier

```bash
aws --version
aws configure list
aws sts get-caller-identity
```

Puis :

```bash
bash scripts/commands/p5.sh prepare
```

### Ne pas faire

Ne pas ajouter une access key en clair dans le dépôt pour « tester rapidement ».

## 4. Mauvais compte AWS

### Symptôme

Terraform refuse le provider avec `allowed_account_ids`.

### Diagnostic

```bash
aws sts get-caller-identity
cat environment/aws-readiness.env | grep P5_EXPECTED_ACCOUNT_ID
```

### Correction

Revenir à la bonne session/profil, puis relancer :

```bash
bash scripts/commands/p5.sh prepare
```

Ne pas remplacer le compte attendu par celui d'une session accidentelle.

## 5. `terraform.tfvars` incohérent

### Diagnostic

```bash
bash scripts/commands/sync-terraform-tfvars.sh --check
```

### Correction normale

```bash
bash scripts/commands/p5.sh prepare
```

Les vrais `tfvars` sont dérivés de la configuration locale, pas édités indépendamment sans raison.

## 6. Terraform `init` échoue

### Vérifier

```bash
terraform version
ls -l terraform/exercice-1/.terraform.lock.hcl
```

Puis tester dans le module concerné :

```bash
terraform -chdir=terraform/exercice-1 init -input=false
```

Causes possibles :

- accès réseau depuis la VM ;
- provider indisponible temporairement ;
- lockfile incohérent ;
- version Terraform non conforme.

Ne supprimer le lockfile qu'après avoir compris pourquoi, car il participe à la reproductibilité.

## 7. Terraform `plan` retourne une erreur

Distinguer :

```text
code 2 = delta normal avec -detailed-exitcode
code autre que 0/2 = erreur
```

Lire le log d'étape et la sortie Terraform avant toute correction.

## 8. Terraform propose une destruction inattendue

### Action

Refuser la confirmation.

Puis :

```bash
bash scripts/commands/p5.sh inspect
terraform -chdir=terraform/exercice-X state list
terraform -chdir=terraform/exercice-X plan
```

Comparer :

- state ;
- code actuel ;
- variables ;
- compte/région.

Ne pas accepter une destruction que vous ne pouvez pas expliquer.

## 9. `terraform output` est vide

### Vérifier

```bash
terraform -chdir=terraform/exercice-X state list
terraform -chdir=terraform/exercice-X output
```

Si le module n'a pas de state exploitable, l'orchestrateur doit considérer la valeur comme inconnue.

Ne pas injecter manuellement une IP provenant d'une autre ressource.

## 10. SSH timeout vers l'exercice 1

### Vérifier la valeur Terraform

```bash
WEB_IP="$(terraform -chdir=terraform/exercice-1 \
  output -raw web_public_ip)"
echo "$WEB_IP"
```

### Vérifier la clé dans la VM

```bash
ls -l ~/.ssh/p5-key ~/.ssh/p5-key.pub
```

### Vérifier l'IPv4 publique d'administration

Si elle a changé :

```bash
bash scripts/commands/p5.sh prepare
```

### Vérifier AWS

- instance `running` ;
- subnet public ;
- Internet Gateway ;
- route `0.0.0.0/0` ;
- Security Group TCP/22 depuis la bonne IP `/32`.

## 11. SSH `Permission denied (publickey)`

Causes typiques :

- mauvaise clé privée ;
- mauvais `key_name` lors de la création ;
- mauvais utilisateur ;
- permissions locales de clé incorrectes.

Utilisateur attendu pour l'AMI Ubuntu :

```text
ubuntu
```

## 12. Ansible ping `UNREACHABLE`

Ne modifier pas `deploy.yml` en premier.

Tester SSH directement depuis `ubuntu-devops`.

Puis :

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping -vvv
```

Le niveau `-vvv` est utile pour voir la commande SSH effective.

## 13. Playbook Ansible échoue

### Syntaxe

```bash
ansible-playbook \
  --syntax-check \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

### Exécution détaillée

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml -vvv
```

Lire la première tâche en échec plutôt que les conséquences suivantes.

## 14. Second passage Ansible `changed>0`

Ce n'est pas conforme à la preuve d'idempotence attendue.

Identifier la tâche qui change à chaque run.

Questions :

- écrit-elle un fichier différent à chaque fois ?
- exécute-t-elle une commande sans `changed_when` adapté ?
- un handler est-il déclenché sans changement réel ?
- l'artefact Angular est-il stable ?

Corriger la cause puis rejouer deux passages.

## 15. NGINX ne démarre pas

Sur l'EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx -n 100 --no-pager
```

Vérifier également :

```bash
ls -l /etc/nginx/sites-enabled/
cat /etc/nginx/sites-available/p5
```

## 16. Angular renvoie 404 sur une route interne

La racine `/` peut fonctionner alors qu'une route SPA échoue.

Vérifier le `try_files` de `ansible/files/nginx-angular.conf` et tester :

```bash
curl -i "${WEB_URL}/parcours-p5"
```

Le fallback doit retourner `index.html`.

## 17. Artefact Angular différent des sources

La CI compare le build aux fichiers sous :

```text
ansible/files/angular-app
```

Relancer :

```bash
bash scripts/commands/prepare-angular-artifact.sh
```

Puis vérifier Git avant de commiter l'artefact mis à jour.

## 18. OpenSearch prend longtemps à devenir actif

La création d'un domaine Cloud n'est pas instantanée.

Ne relancer pas plusieurs `apply` en parallèle.

Vérifier :

```bash
terraform -chdir=terraform/exercice-2 output
```

et l'état du domaine dans AWS.

## 19. OpenSearch Dashboards inaccessible

Vérifier :

- domaine actif ;
- endpoint Terraform ;
- bonne région ;
- IPv4 publique d'administration encore identique ;
- policy SourceIp.

Après changement d'IP :

```bash
bash scripts/commands/p5.sh prepare
bash scripts/commands/p5.sh ex2
```

Terraform doit proposer le delta de policy nécessaire, pas recréer arbitrairement tout le domaine.

## 20. Import Bulk échoue

Commencer par le mode de validation :

```bash
bash scripts/commands/import-opensearch-data.sh
```

Puis vérifier le log d'entrée :

```bash
wc -l terraform/exercice-2/samples/nginx-access.log.sample
```

Pour le log réel :

```bash
ls -lh proofs/runtime/exercice-2/nginx-access-real.log
```

Ne lancer `--apply` qu'après validation correcte.

## 21. Aucune donnée dans Discover

Contrôler :

- index/data view ;
- plage temporelle ;
- timestamps ;
- filtres globaux.

Une plage « dernière heure » peut masquer un sample historique valide.

## 22. `bytes_sent` ne peut pas être agrégé en somme

Le champ doit être numérique.

Vérifier mapping et pipeline :

```bash
bash scripts/commands/verify-opensearch-data.sh \
  --endpoint "$ENDPOINT"
```

Ne remplacez pas la métrique demandée par une autre simplement pour obtenir un graphique.

## 23. Exercice 3 : Terraform ne trouve pas le VPC

Vérifier l'exercice 1 :

```bash
terraform -chdir=terraform/exercice-1 state list
terraform -chdir=terraform/exercice-1 output vpc_id
```

Si l'exercice 1 a été détruit, il faut restaurer le socle par le parcours normal avant ex3.

## 24. HAProxy ne répond pas

Sur l'EC2 HAProxy :

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl status haproxy --no-pager
sudo journalctl -u haproxy -n 100 --no-pager
```

Vérifier aussi le Security Group port 80.

## 25. Un backend ne répond pas

Sur le backend :

```bash
sudo systemctl status docker --no-pager
sudo docker ps -a
sudo docker logs nginx-hello
curl -fsS http://127.0.0.1/
```

Le problème est backend si le service ne répond pas localement.

## 26. Round-robin ne montre qu'un backend

Vérifier d'abord les deux backends individuellement et l'état HAProxy.

Puis :

```bash
bash scripts/commands/test-haproxy-roundrobin.sh \
  --url "$HAPROXY_URL" --requests 12
```

Si un backend est DOWN, le comportement « un seul backend » peut être correct du point de vue HAProxy mais l'infrastructure n'est pas dans l'état sain attendu pour commencer la démonstration.

## 27. Le failover laisse le backend arrêté

Vérifier immédiatement le backend et redémarrer le conteneur si nécessaire :

```bash
sudo docker start nginx-hello
```

Puis vérifier :

```bash
sudo docker ps
curl -fsS http://127.0.0.1/
```

Attendre ensuite la réintégration HAProxy.

## 28. `finalize` échoue

Le log indique normalement les marqueurs restant dans les livrables.

Exécuter directement :

```bash
bash scripts/commands/prepare-livrables.sh
```

Compléter uniquement les preuves réellement disponibles. Ne supprimer pas un marqueur pour faire passer le contrôle si la preuve manque toujours.

## 29. `cleanup` ne termine pas par `NETTOYAGE AWS COMPLET`

Ne conclure pas que les coûts sont arrêtés.

Lancer :

```bash
bash scripts/commands/check-aws-cleanup.sh
```

Identifier la ressource restante et son exercice propriétaire.

Vérifier le state correspondant avant suppression manuelle.

Le nettoyage P5 ne concerne pas l'arrêt ou la destruction de `ubuntu-devops`.

## 30. State absent mais ressource AWS présente

C'est une situation de récupération, pas un run normal.

Avant toute action :

- identifier les tags ;
- chercher un state sauvegardé ;
- vérifier le compte/région ;
- décider s'il faut importer ou supprimer proprement.

Ne lancer pas un nouvel `apply` aveuglément.

## 31. Ordre de diagnostic recommandé

Toujours descendre par couche :

```text
0. plateforme HOST/KVM/VM si ubuntu-devops n'est pas joignable
1. runtime P5 dans ubuntu-devops
2. identité AWS
3. Terraform/state
4. réseau AWS
5. SSH vers les EC2
6. Ansible/service
7. application
8. données OpenSearch
9. dashboard
10. HAProxy/backends
11. preuves/livrables
12. nettoyage AWS
```

Pour la couche 0, utiliser `Ubuntu-desktops-custom`. Pour les couches 1 à 12, rester dans le dépôt P5.

Cette méthode évite de corriger une couche applicative lorsqu'en réalité la plateforme, le réseau ou l'identité est en panne.
