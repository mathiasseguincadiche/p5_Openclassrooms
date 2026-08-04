# Livrable 1 — Terraform, Ansible, NGINX et application Angular

> **Gabarit à compléter.** Les preuves doivent être issues d'un déploiement
> réel. La présence de ce fichier ne prouve pas que l'exercice est terminé.

## 1. Choix de réalisation

- Mode retenu : **AWS**.
- Région : `us-east-1`.
- Infrastructure du dépôt : VPC, deux sous-réseaux et une cible EC2.
- Une seule cible est utilisée, conformément au besoin minimal de l’exercice.

## 2. Fichiers remis

```text
terraform/exercice-1/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── .terraform.lock.hcl

ansible/
├── inventories/hosts_aws.example
├── playbooks/deploy.yml
└── files/
    ├── angular-app/
    └── nginx-angular.conf
```

Les fichiers `terraform.tfvars`, `terraform.tfstate`, l'inventaire réel et les
clés SSH sont exclus de la remise publique.

## 3. Preuves Terraform

### Validation

```bash
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan
```

**Preuves à insérer :** validation réussie, résumé du plan et ressources
attendues clairement identifiables.

### Application

```bash
terraform -chdir=terraform/exercice-1 apply
terraform -chdir=terraform/exercice-1 output
```

**Preuves à insérer :** résumé de l'application et cible EC2 en état
`running`, sans exposer de donnée sensible.

## 4. Preuves Ansible

```bash
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook \
  -i ansible/inventories/hosts_aws \
  ansible/playbooks/deploy.yml
```

**Preuves à insérer :** ping réussi, récapitulatif du playbook sans échec et
seconde exécution idempotente.

## 5. Preuve de l'application

La page actuellement versionnée dans `ansible/files/angular-app/` est un
support statique de démonstration. Avant la remise, remplacez-la par le build
réel de l'application Angular fourni par le starter.

**Preuves à insérer :** application Angular réelle accessible sur le port 80,
configuration NGINX valide et réponse HTTP attendue.

## 6. Nettoyage

```bash
terraform -chdir=terraform/exercice-1 destroy
```

**Preuve à insérer :** confirmation de destruction et absence des ressources
résiduelles dans AWS.
