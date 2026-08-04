# SEGUIN-CADICHE_Mathias_1_Terraform_Ansible_NGINX

# Preuves Exercice 1 : Déploiement Infrastructure as Code avec Terraform + Ansible

> ⚠️️ **Gabarit de collecte** — ce document ne prétend pas qu'un déploiement AWS a été exécuté.
> Remplacez chaque zone « preuve à insérer » par une capture ou une sortie obtenue dans votre propre compte AWS.

---

## 📋 Contexte

**Projet** : P5 OpenClassrooms - Déployer et suivre l'infrastructure as code
**Exercice** : 1 - Déploiement de deux serveurs web NGINX
**Auteur** : SEGUIN-CADICHE Mathias

---

## 🎯 Objectifs

- ✅ Provisionner un VPC, deux sous-réseaux publics et deux instances EC2 avec Terraform.
- ✅ Limiter l'accès SSH à l'adresse IP d'administration.
- ✅ Configurer NGINX avec Ansible.
- ✅ Déployer l'interface web P5 de manière reproductible.

---

## 🛠️ Outils utilisés

- **Terraform** 1.15.8.
- **Ansible Core** 2.18 ou 2.19.
- **AWS CLI v2**.
- **NGINX**.

---

## 📁 Structure des fichiers

```text
terraform/exercice-1/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example

ansible/
├── playbooks/deploy.yml
├── inventories/hosts_aws.example
└── files/
    ├── angular-app/index.html
    └── nginx-angular.conf
```

Le fichier `terraform.tfstate`, les valeurs réelles de `terraform.tfvars` et l'inventaire `hosts_aws` ne doivent pas être commités.

---

## ✅ 1. Préparation de l'environnement

```bash
terraform version
ansible --version
aws --version
aws sts get-caller-identity
```

**Preuve à insérer** : sortie anonymisée des versions et de l'identité AWS, sans clé ni jeton.

---

## ✅ 2. Déploiement Terraform

```bash
cp terraform/exercice-1/terraform.tfvars.example terraform/exercice-1/terraform.tfvars
terraform -chdir=terraform/exercice-1 init
terraform -chdir=terraform/exercice-1 fmt -check
terraform -chdir=terraform/exercice-1 validate
terraform -chdir=terraform/exercice-1 plan -out=tfplan
terraform -chdir=terraform/exercice-1 apply tfplan
terraform -chdir=terraform/exercice-1 output
```

**Preuves à insérer** :

1. Résultat de `terraform validate`.
2. Résumé du plan avant application.
3. Résumé de l'application et outputs, après anonymisation si nécessaire.
4. Vue AWS des deux instances et de leurs groupes de sécurité.

---

## ✅ 3. Configuration Ansible et NGINX

```bash
cp ansible/inventories/hosts_aws.example ansible/inventories/hosts_aws
ansible all -i ansible/inventories/hosts_aws -m ping
ansible-playbook -i ansible/inventories/hosts_aws ansible/playbooks/deploy.yml
```

Le groupe d'inventaire attendu est `webservers`. La clé privée recommandée est `~/.ssh/p5-key`.

**Preuves à insérer** :

1. Résultat du ping Ansible pour les deux hôtes.
2. Récapitulatif du playbook avec `failed=0` et `unreachable=0`.
3. Résultat distant de `sudo nginx -t`.

---

## ✅ 4. Vérification fonctionnelle

```bash
curl --fail "http://ADRESSE_SERVEUR_1"
curl --fail "http://ADRESSE_SERVEUR_2"
```

**Preuves à insérer** : captures des deux pages P5 et sorties HTTP correspondantes.

---

## 🧹 5. Nettoyage

```bash
terraform -chdir=terraform/exercice-1 destroy
```

**Preuve à insérer** : confirmation que les ressources de l'exercice ont été supprimées afin d'éviter des coûts résiduels.

---

## 📌 Conclusion

Le livrable est complet uniquement après remplacement de toutes les zones « preuve à insérer » par des éléments réellement produits pendant le déploiement.
