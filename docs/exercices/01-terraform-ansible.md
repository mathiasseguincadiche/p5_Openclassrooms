# Exercice 1 — Terraform, Ansible, NGINX et Angular sur AWS

## Objectif pédagogique

Cet exercice démontre deux responsabilités complémentaires :

- **Terraform** décrit et provisionne l'infrastructure AWS ;
- **Ansible** configure le serveur et déploie l'application Angular derrière NGINX.

La compétence ne consiste pas seulement à « lancer deux outils ». Il faut comprendre la frontière entre infrastructure et configuration, lire le plan Terraform, vérifier la connectivité puis démontrer l'idempotence du playbook.

## Résultat final attendu

![Exercice 1 — Terraform, Angular et Ansible](../schemas/exercice-1.svg)

Le schéma sépare volontairement deux flux indépendants : Terraform prépare l'infrastructure AWS tandis
que le build Angular produit l'artefact applicatif. Ces deux flux convergent dans Ansible, qui utilise
l'EC2 créée par Terraform et y déploie NGINX + Angular.

L'exercice est terminé lorsque l'application est réellement accessible et qu'un deuxième passage Ansible ne produit plus de changement inutile.

## Fichiers à connaître

| Élément | Fichier/dossier |
| --- | --- |
| module Terraform | `terraform/exercice-1/` |
| variables | `terraform/exercice-1/variables.tf` |
| outputs | `terraform/exercice-1/outputs.tf` |
| modèle de `tfvars` | `terraform/exercice-1/terraform.tfvars.example` |
| sources Angular | `application/angular/` |
| artefact Angular | `ansible/files/angular-app/` |
| configuration NGINX | `ansible/files/nginx-angular.conf` |
| inventaire exemple | `ansible/inventories/hosts_aws.example` |
| inventaire réel local | `ansible/inventories/hosts_aws` |
| playbook | `ansible/playbooks/deploy.yml` |
| orchestration | `scripts/commands/p5.sh` |

## 1. Comprendre le Terraform

### Provider AWS

Le provider utilise la région configurée et protège le compte :

```hcl
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.expected_aws_account_id]
}
```

`allowed_account_ids` évite qu'un changement de profil AWS envoie le lab vers un autre compte sans alerte.

### Tags par défaut

Toutes les ressources reçoivent des tags communs, notamment :

```text
Project   = p5-openclassrooms
ManagedBy = Terraform
Purpose   = training-lab
Exercise  = 1
```

Ces tags servent à l'identification, au nettoyage et à la réutilisation par l'exercice 3.

### AMI Ubuntu

Si `ami_id` n'est pas renseigné, Terraform sélectionne automatiquement une AMI Canonical Ubuntu 24.04 LTS récente.

La VM de contrôle `ubuntu-devops` est en Ubuntu Server 26.04 ; la cible EC2 est en Ubuntu 24.04. Ce sont deux systèmes distincts avec deux rôles différents.

## 2. Comprendre le réseau

Terraform crée un VPC :

```text
10.0.0.0/16
```

Puis deux subnets publics dérivés du CIDR du VPC.

Une Internet Gateway et une table de routage avec :

```text
0.0.0.0/0 → Internet Gateway
```

permettent aux instances des subnets publics d'accéder à Internet et d'être joignables selon leurs Security Groups.

## 3. Comprendre le Security Group

Deux règles entrantes importantes :

```text
TCP/22  depuis your_ip_cidr
TCP/80  depuis 0.0.0.0/0
```

### SSH

`your_ip_cidr` doit être une IPv4 `/32`, par exemple :

```text
198.51.100.42/32
```

L'objectif est que seule l'IPv4 publique d'administration utilisée par le lab puisse joindre l'EC2 en SSH.

### HTTP

Le port 80 est public car l'application doit être démontrable dans un navigateur.

## 4. Comprendre l'EC2

L'instance reçoit :

- l'AMI Ubuntu ;
- le type d'instance configuré ;
- une IP publique ;
- le Security Group web ;
- la paire de clés ;
- IMDSv2 obligatoire ;
- un volume racine gp3 chiffré.

Le `user_data` installe uniquement Python 3, indispensable au fonctionnement normal d'Ansible sur la cible.

Ce choix est volontaire : **Terraform prépare la machine ; Ansible configure le service applicatif**.

## 5. Outputs Terraform

Le module publie :

```text
vpc_id
public_subnet_ids
web_security_group_id
web_public_ip
web_private_ip
web_public_dns
web_url
```

Pour les consulter :

```bash
terraform -chdir=terraform/exercice-1 output
```

Pour lire une valeur brute :

```bash
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
```

Le moteur `p5.sh` utilise `web_public_ip` et `web_url` comme valeurs autoritaires. Si elles sont absentes ou invalides, il s'arrête plutôt que d'inventer une adresse.

## 6. Préparer l'exercice

Avant création :

```bash
bash scripts/commands/p5.sh status
```

Puis :

```bash
bash scripts/commands/p5.sh ex1
```

Pour un débutant, il est utile de comprendre les étapes internes décrites ci-dessous même si l'orchestrateur les enchaîne.

## 7. Build Angular

La source est sous :

```text
application/angular/
```

La CI utilise notamment :

```bash
npm ci --prefix application/angular --no-audit --no-fund
npm run lint --prefix application/angular
npm test --prefix application/angular
npm run build --prefix application/angular
```

### Pourquoi `npm ci` ?

`npm ci` installe exactement les dépendances du `package-lock.json`. Il est adapté à une installation reproductible en CI.

### Pourquoi comparer le build et l'artefact Ansible ?

Parce que le dépôt ne doit pas dire :

```text
sources Angular A
mais déploiement de l'artefact B
```

Le build produit est comparé à :

```text
ansible/files/angular-app/
```

## 8. Terraform init

Commande conceptuelle :

```bash
terraform -chdir=terraform/exercice-1 init -input=false
```

### Effet

- initialise le module ;
- installe le provider AWS selon le lockfile ;
- prépare Terraform à lire le state et à produire un plan.

Aucune EC2 n'est créée par `init`.

## 9. Terraform plan

Le moteur exécute :

```bash
terraform -chdir=terraform/exercice-1 \
  plan -input=false -detailed-exitcode -out=tfplan
```

Puis :

```bash
terraform -chdir=terraform/exercice-1 \
  show -no-color tfplan
```

### Pourquoi sauvegarder le plan ?

Parce que l'`apply` peut utiliser exactement le plan qui a été affiché et confirmé.

### Lire le plan

Contrôler :

- nombre de ressources ;
- région ;
- tags ;
- CIDR VPC ;
- deux subnets ;
- port SSH `/32` ;
- port HTTP 80 ;
- type EC2 ;
- chiffrement ;
- aucune destruction inattendue.

### Code détaillé

`-detailed-exitcode` distingue :

```text
0 = aucun changement
2 = changements proposés
autre = erreur
```

Si le code est `0`, `p5.sh` ne lance pas d'apply inutile.

## 10. Terraform apply et post-plan

Si le plan contient un delta, le moteur demande confirmation puis applique `tfplan`.

Ensuite il relance :

```bash
terraform -chdir=terraform/exercice-1 \
  plan -input=false -detailed-exitcode
```

Le résultat attendu après convergence est `0` : plus de delta.

## 11. Génération de l'inventaire Ansible

Après Terraform :

```bash
bash scripts/commands/generate-ansible-inventory.sh
```

Le script génère l'inventaire réel à partir des outputs Terraform et de la clé configurée.

Pourquoi ne pas versionner cet inventaire ?

Parce qu'il contient des valeurs runtime liées au lab actuel.

## 12. Vérifier SSH avant Ansible

`p5.sh` attend que l'EC2 réponde avec la clé privée et que `cloud-init` soit terminé.

Diagnostic manuel utile depuis `ubuntu-devops` :

```bash
WEB_IP="$(terraform -chdir=terraform/exercice-1 output -raw web_public_ip)"
ssh -i ~/.ssh/p5-key \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=accept-new \
  "ubuntu@${WEB_IP}"
```

Sur la cible :

```bash
hostname
cat /etc/os-release
python3 --version
exit
```

Ne pas continuer vers Ansible si SSH échoue.

## 13. Ansible ping

```bash
ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

Le module `ping` vérifie qu'Ansible peut :

- joindre la cible ;
- s'authentifier ;
- exécuter Python.

Résultat attendu :

```text
SUCCESS
pong
```

## 14. Lire `deploy.yml`

Le playbook cible le groupe :

```text
webservers
```

et utilise l'élévation de privilèges :

```yaml
become: true
```

### Tâches principales

| Tâche | Rôle |
| --- | --- |
| installer NGINX et `curl` | fournir le serveur HTTP et un outil de test |
| créer `appgroup` | groupe système applicatif |
| créer `appuser` | utilisateur système sans shell de login |
| créer `/var/www/p5` | racine du site |
| copier l'artefact Angular | déployer le build |
| copier `nginx-angular.conf` | définir le VirtualHost |
| activer le site | créer le lien `sites-enabled/p5` |
| retirer le site par défaut | éviter les conflits de configuration |
| `nginx -t` | valider la syntaxe avant exploitation |
| service NGINX | garantir démarrage et activation |

Les copies notifient le handler de rechargement NGINX uniquement lorsqu'un changement a été effectué.

## 15. Vérifier la syntaxe Ansible

Avant exécution manuelle :

```bash
ansible-playbook \
  --syntax-check \
  --inventory ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

La CI exécute un syntax-check avec l'inventaire exemple pour vérifier le dépôt sans exposer l'inventaire réel.

## 16. Premier passage Ansible

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le premier passage peut avoir plusieurs `changed` : paquets, fichiers, liens ou services doivent être convergés.

Critères minimaux :

```text
unreachable=0
failed=0
```

## 17. Second passage et idempotence

Relancer exactement le même playbook :

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Avec l'état déjà conforme, le dépôt exige :

```text
changed=0
unreachable=0
failed=0
```

Le moteur parse le recap et refuse une preuve d'idempotence ambiguë.

## 18. NGINX et Angular

La configuration NGINX sert :

```text
/var/www/p5
```

Le projet teste également le fallback de Single Page Application.

Commande automatisée :

```bash
bash scripts/commands/verify-angular-deployment.sh \
  --url "$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
```

Vérification manuelle simple :

```bash
WEB_URL="$(terraform -chdir=terraform/exercice-1 output -raw web_url)"
curl -fsSI "$WEB_URL/"
curl -fsS "$WEB_URL/" | head
```

Puis ouvrir l'URL dans un navigateur.

## 19. Produire le log réel

Le moteur envoie 96 requêtes de preuve :

```bash
bash scripts/commands/generate-nginx-traffic.sh \
  --url "$WEB_URL" \
  --requests 96
```

Puis collecte `access.log` :

```bash
bash scripts/commands/collect-nginx-access-log.sh \
  --host "$WEB_IP" \
  --output proofs/runtime/exercice-2/nginx-access-real.log
```

Ce fichier est local à la VM et sert ensuite à l'exercice 2.

## 20. Preuves recommandées

Conserver au minimum :

- plan Terraform relu ;
- sortie d'apply ;
- outputs utiles sans secrets ;
- instance AWS visible comme active ;
- Ansible ping ;
- recap du premier passage ;
- recap strict du deuxième passage ;
- application dans le navigateur ;
- preuve HTTP/fallback ;
- log NGINX réel collecté.

## 21. Ce qu'il ne faut pas faire après l'exercice 1

La consigne pédagogique générale peut suggérer de supprimer les ressources AWS après un exercice. Dans **cette implémentation**, le VPC et les subnets de l'exercice 1 sont réutilisés par l'exercice 3.

Donc :

```text
NE PAS détruire exercice 1 avant exercice 3
```

Le nettoyage global se fera :

```text
3 → 2 → 1
```

## 22. Diagnostic rapide

### `terraform output` ne retourne rien

Vérifier :

```bash
pwd
ls terraform/exercice-1
terraform -chdir=terraform/exercice-1 state list
```

Ne pas créer une valeur d'output manuellement.

### SSH timeout

Vérifier :

- instance running ;
- IP publique actuelle ;
- route Internet ;
- Security Group SSH ;
- IPv4 `/32` d'administration ;
- clé privée dans la VM.

### `Permission denied (publickey)`

Vérifier :

- bonne clé ;
- `key_name` attendu ;
- utilisateur `ubuntu` ;
- permissions de la clé.

### Ansible `UNREACHABLE`

Revenir au test SSH direct. Ne pas modifier le playbook tant que la couche transport ne fonctionne pas.

### NGINX invalide

Sur l'EC2 :

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo journalctl -u nginx -n 100 --no-pager
```

### Application 404 sur une route SPA

Contrôler la configuration NGINX et son `try_files` vers `index.html`.

## Definition of Done

L'exercice 1 est prêt à alimenter la suite lorsque :

```text
Terraform convergé
+ Ansible ping OK
+ playbook réussi
+ second passage changed=0
+ Angular servi par NGINX
+ access.log réel collecté
```

Étape suivante : [Exercice 2 — Amazon OpenSearch](02-opensearch.md).
