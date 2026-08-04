# Exercice 1 — Terraform, Ansible et application Angular

![Flux de l'exercice 1](../schemas/exercice-1.svg)

## Objectif officiel

Créer l’infrastructure avec Terraform, vérifier `init`, `plan` et `apply`, puis
utiliser Ansible pour installer NGINX et déployer une application Angular.

## Implémentation retenue

Terraform crée le VPC, les sous-réseaux, le groupe de sécurité et une instance
EC2 Ubuntu. Ansible configure cette instance. Le dépôt contient une véritable
SPA Angular, son `package-lock.json` et le build exact déployé par Ansible.

```text
application/angular/             # sources Angular reproductibles
scripts/commands/prepare-angular-artifact.sh
ansible/files/angular-app/       # build de production
ansible/files/nginx-angular.conf # virtual host et fallback SPA
ansible/playbooks/deploy.yml     # installation et déploiement
terraform/exercice-1/            # réseau et cible EC2
```

## 1. Contrôler l’environnement

```bash
./scripts/commands/pre-deployment-check.sh --stage initial
./scripts/commands/prepare-angular-artifact.sh
```

Le second script exécute `npm ci`, construit Angular et remplace l’artefact
Ansible. La CI reconstruit aussi l’application et vérifie que les deux dossiers
sont identiques.

## 2. Déployer avec Terraform

```bash
cp terraform/exercice-1/terraform.tfvars.example \
  terraform/exercice-1/terraform.tfvars
$EDITOR terraform/exercice-1/terraform.tfvars

terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 show tfplan
terraform -chdir=terraform/exercice-1 apply tfplan
```

Relire le compte autorisé, la région, l’adresse `/32`, le type d’instance, le
volume et les règles réseau avant l’application.

## 3. Préparer l’inventaire Ansible

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
terraform -chdir=terraform/exercice-1 output -raw web_public_ip
$EDITOR ansible/inventories/hosts_aws

ansible all \
  -i ansible/inventories/hosts_aws \
  -m ping
```

L’inventaire réel et la clé SSH restent exclus de Git.

## 4. Déployer NGINX et Angular

```bash
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml --check --diff

ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml

# Répéter pour démontrer l’idempotence.
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

Le playbook installe NGINX, crée l’utilisateur applicatif, copie le build dans
`/var/www/p5`, active le site, vérifie `nginx -t` et démarre le service.

## 5. Vérifier le déploiement réel

```bash
./scripts/commands/verify-angular-deployment.sh
```

Le contrôle valide automatiquement :

- la réponse HTTP 200 ;
- la présence de la racine Angular ;
- l’accessibilité du bundle principal ;
- le fallback SPA sur `/parcours-p5` ;
- l’en-tête NGINX `X-Content-Type-Options: nosniff`.

Les sorties sont enregistrées sous `proofs/runtime/exercice-1/`.

## 6. Produire des logs réels pour l’exercice 2

```bash
./scripts/commands/generate-nginx-traffic.sh --requests 64
./scripts/commands/collect-nginx-access-log.sh
```

Le premier script génère plusieurs méthodes et chemins HTTP. Le second récupère
le journal NGINX par SSH et vérifie son format avant un éventuel import dans
OpenSearch.

## Preuves attendues

- versions de Terraform, Ansible, Node.js et Angular ;
- validation et plan Terraform relu ;
- instance EC2 en état `running` ;
- ping Ansible ;
- première exécution du playbook puis exécution idempotente ;
- verdict `APPLICATION ANGULAR DÉPLOYÉE ET SERVIE PAR NGINX` ;
- capture de l’application réelle ;
- configuration NGINX valide ;
- aucune clé, variable locale ou identité sensible visible.

Gabarit :
[`SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md).

## Nettoyage

L’exercice 3 dépend du VPC et de la clé de l’exercice 1. Ne détruisez donc
l’exercice 1 qu’après la démonstration HAProxy.
