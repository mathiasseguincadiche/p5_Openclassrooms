# Exercice 1 — Infrastructure IaC avec Terraform et CD avec Ansible

![Flux de l'exercice 1](../schemas/exercice-1.svg)

## Objectif officiel

Créer une infrastructure avec Terraform, vérifier `init`, `plan` et `apply`,
puis utiliser Ansible pour installer NGINX et déployer une application Angular.

## Option retenue : AWS

OpenClassrooms autorise Docker local ou AWS. Pour cette réalisation, le choix
validé est **AWS** : Terraform crée le réseau et une instance EC2 accessible en
SSH, puis Ansible configure cette instance. Le mode Docker local n’est pas
implémenté dans ce dépôt.

## Étapes attendues

1. installer Terraform ;
2. écrire `main.tf` avec le provider choisi ;
3. exécuter `terraform init`, `plan` et `apply` ;
4. installer Ansible ;
5. créer l’inventaire `hosts` et vérifier le module `ping` ;
6. écrire `deploy.yml` avec les tâches NGINX, application et configuration ;
7. ajouter un handler de rechargement NGINX ;
8. exécuter le playbook et vérifier l’application sur le port 80.

## Implémentation du dépôt

```text
terraform/exercice-1/        # VPC, sous-réseaux et une cible EC2
ansible/inventories/         # inventaire exemple
ansible/playbooks/deploy.yml # installation et configuration NGINX
ansible/files/angular-app/   # artefact web copié par Ansible
ansible/files/nginx-angular.conf
```

Les deux sous-réseaux préparent aussi l’exercice 3. L’exercice 1 ne crée qu’une
cible Ansible, ce qui suffit pour le résultat officiel.

## Point bloquant à ne pas masquer

`ansible/files/angular-app/index.html` est une page statique de démonstration.
Elle ne prouve pas qu’une application Angular a été construite. Avant la remise :

1. construisez l’application Angular du starter avec `ng build` ;
2. copiez le contenu du dossier `dist/` dans `ansible/files/angular-app/` ;
3. relancez le playbook ;
4. capturez l’application réelle servie par NGINX.

## Commandes de référence

```bash
cp terraform/exercice-1/terraform.tfvars.example \
  terraform/exercice-1/terraform.tfvars
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 plan
terraform -chdir=terraform/exercice-1 apply

terraform -chdir=terraform/exercice-1 output -raw web_public_ip
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
# Remplacez l’adresse d’exemple dans hosts_aws.
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

## Livrables et preuves

- fichiers `.tf`, verrouillage des providers et exemple de variables ;
- inventaire anonymisé ou exemple ;
- playbook `deploy.yml` et configuration NGINX ;
- sorties `terraform validate`, `plan` et `apply` ;
- ping Ansible réussi ;
- exécution du playbook sans erreur ;
- véritable application Angular accessible en HTTP.

Gabarit :
[`SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md`](../livrables/SEGUIN-CADICHE_Mathias_1_terraform_ansible_nginx_02082026.md).
